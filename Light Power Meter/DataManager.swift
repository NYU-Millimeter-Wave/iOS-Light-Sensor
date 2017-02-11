//
//  DataManager.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/23/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import Alamofire

class DataManager: NSObject {

    // MARK: - Singleton Declaration
    
    static let sharedManager = DataManager()
    
    // MARK: - Class Properties
    
    // Experiments
    var currentExperiment: Experiment?
    var experiments: [Experiment] = []
    
    // Device Info
    var deviceID: Int!
    var deviceIP: String!
    
    // Communication & Sync
    var pulledJSON: [String: AnyObject]?
    var connectionIP: String?
    var socket: SocketListener?
    var sentTime: CFAbsoluteTime?
    var timeDelta: Double?
    var syncronizedTime: Int?
    var pongReceived: Bool = false {
        didSet {
            if self.pongReceived {
                self.timeDelta = CFAbsoluteTimeGetCurrent() - self.sentTime!
                print("[ INF ] Time delta: \(self.timeDelta!)")
            }
        }
    }
    
    // MARK: - Initalizers
    
    private override init() {
        super.init()
    }
    
    // MARK: - Transmission Methods
    
    func initalizeSocketConnection(url: String) {
        if let _ = self.socket {
            print("[ ERR ] Cannot create socket as one already exists")
        } else {
            self.socket = SocketListener(url: url)
        }
    }
    
    func syncronizeTime() {
        if let soc = self.socket {
            if soc.isConnected {
                print("[ INF ] Syncronizing time with server...")
                self.sentTime = CFAbsoluteTimeGetCurrent()
                soc.sendPing()
            } else {
                print("[ ERR ] Cannot sync time, socket not connected")
            }
        } else {
            print("[ ERR ] Cannot sync time, socket not connected")
        }
    }
    
    func uploadExperiment(experiment: Experiment, completion: (success: Bool) -> Void) {
        // Add experiment to array (so most recent on top)
        experiments.append(experiment)
        
        // Add in all the other experiments
        parseInExperimentsFromServer() { success in
            if success {
                // Properly fetched the experiment set from server
                
                // This is safe to call dirctly in this context
                let url = "http://\(self.connectionIP!):8000/"
                
                // Convert the experiment array to JSON
                var transmissionDict = [String: AnyObject]()
                var jsonExpArray = [[String: AnyObject]]()
                for exp in self.experiments {
                    jsonExpArray.append(exp.serializeSelfToJSONDict())
                }
                transmissionDict["experiments"] = jsonExpArray
                
                // Fire off request
                Alamofire.request(.POST, url, parameters: transmissionDict, encoding: .JSON).response {
                    _, _, _, error in
                    if let err = error {
                        print("[ ERR ] Experiment upload failed: \(err)")
                        completion(success: false)
                    } else {
                        print("[ COM ] Upload Complete")
                        completion(success: true)
                    }
                }
            } else {
                print("[ ERR ] Could not upload experiment")
                completion(success: false)
            }
        }
    }
    
    func parseInExperimentsFromServer(completion: (success: Bool) -> Void) {
        var failed = false
        var url = ""
        if let ip = self.connectionIP {
            url = "http://\(ip):8000"
        } else {
            print("[ ERR ] Transmission Failed, URL nil")
            completion(success: false)
        }
        Alamofire.request(.GET, url, parameters: nil, encoding: .JSON).responseJSON { response in
            if let dict = response.result.value as? [String: AnyObject] {
                self.pulledJSON = dict
                if let experiments = dict["experiments"] as? [[String: AnyObject]] {
                    for experiment in experiments {
                        let newExperiment = Experiment(title: "NULL")
                        newExperiment.title = experiment["title"] as? String
                        newExperiment.startTime = experiment["startTime"] as? Double
                        newExperiment.stopTime = experiment["endTime"] as? Double
                        
                        for reading in (experiment["readings"] as! [[String: AnyObject]]) {
                            let bump   = reading["bump"]      as! Int
                            let time   = reading["timestamp"] as! Double
                            let red    = reading["LightRPL"]  as! Double
                            let yellow = reading["LightYPL"]  as! Double
                            let purple = reading["LightPPL"]  as! Double
                            newExperiment.readingsArray?.append((red: red, yellow: yellow, purple: purple, time: time, bump: bump))
                        }
                        
                        self.experiments.append(newExperiment)
                    }
                } else {
                    print("[ INF ] Empty JSON")
                    failed = false
                }
            }
            print("[ COM ] Parsing JSON complete")
            completion(success: !(failed))
        }
    }
}

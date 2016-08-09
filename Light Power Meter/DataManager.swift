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
    lazy var experiments: [Experiment] = []
    
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
                let url = "http://\(self.connectionIP):8000/"
                
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
        let url = "http://\(connectionIP):8000/"
        Alamofire.request(.GET, url, parameters: nil, encoding: .JSON).responseJSON { response in
            if let dict = response.result.value as? [String: AnyObject] {
                self.pulledJSON = dict
                
                for (key, value) in self.pulledJSON! {
                    let newExp = Experiment(title: "NONE")
                    if key == "title" {
                        newExp.title = value as? String
                    }
                    else if key == "startTime" {
                        newExp.startTime = value as? Double
                    }
                    else if key == "stopTime" {
                        newExp.stopTime = value as? Double
                    }
                    else if key == "readings" {
                        if let readingDict = value as? [String: AnyObject] {
                            for (rkey, rvalue) in readingDict {
                                var red    = 0.0
                                var yellow = 0.0
                                var purple = 0.0
                                var time   = 0.0
                                if rkey == "Light1Detected"      { red    = rvalue as! Double }
                                else if rkey == "Light1Detected" { yellow = rvalue as! Double }
                                else if rkey == "Light1Detected" { purple = rvalue as! Double }
                                else if rkey == "timestamp"      { time   = rvalue as! Double }
                                else if rkey == "direction"      { /* TODO: Implement */ }
                                else { break }
                                newExp.readingsArray?.append((red: red, yellow: yellow, purple: purple, time: time))
                            }
                        }
                    } else {
                        print("[ ERR ] Unexpected token in JSON parsing")
                        completion(success: false)
                    }
                    self.experiments.append(newExp)
                }
                print("[ COM ] Parsing JSON complete")
                completion(success: true)
            } else {
                print("[ ERR ] Could not parse JSON into dict")
                completion(success: false)
            }
        }
    }
}

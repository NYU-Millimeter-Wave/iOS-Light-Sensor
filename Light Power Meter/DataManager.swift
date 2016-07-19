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
    var currentExperiment: Experiment?
    
    // Device Info
    var deviceID: Int!
    var deviceIP: String!
    
    // Communication & Sync
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
    
    func syncronizeCurrentExperiment() {}
    
    func syncronizeAllExperiments() {}
}

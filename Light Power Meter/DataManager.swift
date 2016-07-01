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
    
    var experiments: [Experiment]!
    
    var deviceID: Int!
    var deviceIP: String!
    
    var syncronizedTime: Int!
    
    var socket: SocketListener?
    
    // MARK: - Initalizers
    
    private override init() {
        super.init()
        
        self.experiments = []
//        self.deviceID = UIDevice.currentDevice().indentifierFor
    }
    
    // MARK: - Experiment Methods
    
    func startNewExperiment() {}
    
    // MARK: - Transmission Methods
    
    func syncronizeTime() {}
    
    func syncronizeCurrentExperiment() {}
    
    func syncronizeAllExperiments() {}
    
    
}

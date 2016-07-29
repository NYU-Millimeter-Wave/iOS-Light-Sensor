//
//  Experiment.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/23/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit

class Experiment: NSObject {
    
    // MARK: - Class Properties
    
    /// The title of the experiment
    var title: String?
    
    /// Optional Text View to log output
    var logOutput: UITextView?
    
    /// Array to store power levels
    var readingsArray: [(red: Double, yellow: Double, purple: Double, time: CFAbsoluteTime)]?
    
    /// Exact time of start of experiment
    var startTime: CFAbsoluteTime?
    
    /// Exact time of end of experiment
    var stopTime:  CFAbsoluteTime?
    
    /// Evals to true if the experiement didn't encounter issues
    var endedCleanly: Bool?
    
    // MARK: - Private Class Properties
    
    // Singletons
    
    private let dm = DataManager.sharedManager
    private let ip = ImageProcessor.sharedProcessor
    
    // Power Level Reading Properties
    
    // Count of readings taken for timer
    private var readingCount: Int = 0
    
    // Timer to trigger reading
    private var readingTimer: NSTimer?
    
    // Color buffers for reading
    private var maxR: Double!
    private var maxY: Double!
    private var maxP: Double!
    
    // MARK: - Initalizers
    
    init(title: String) {
        super.init()
        self.title = title
    }
    
    // MARK: - Experiment Control Flow
    
    func beginExperiment() {
        log("[ === ] Starting New Experiment: \(title)")
        log("[ --- ] Checking time sync...")
        
        if self.checkTimeSync() {
            log("[ -+- ] Time sync complete")
            
            self.startTime = CFAbsoluteTimeGetCurrent()
            log("[ --- ] Starting experiment with start time \(self.startTime!)")
            
            self.signalRoombaToStart() { _ in
                self.log("[ -+- ] Roomba acknowledged experiment begin")
                
                self.log("[ TST ] Testing read operations...")
                self.performReadingOperations()
            }
            
        } else {
            log("[ === ] Could not verify time sync, stopping...")
            endedCleanly = false
        }
    }
    
    func performReadingOperations() {
        self.signalRoombaToRead() { _ in
            self.log("[ -+- ] Roomba in reading mode")
            self.takeReading() { success in
                
                if success == true {
                    self.log("[ -+- ] Reading done, Success")
                }
            }
        }
    }
    
    func endExperiment() {
        self.signalRoombaExperimentEnd() { success in
            if success {
                self.log("[ -+- ] Roomba aknowledged end of experiment")
                self.log("[ --- ] Uploading experiment to server")
                self.stopTime = CFAbsoluteTimeGetCurrent() - self.startTime!
                self.endedCleanly = true
            } else {
                self.log("[ -x- ] Roomba did not aknowledge end of experiment")
                self.log("[ --- ] Attempting upload to server anyways...")
                self.stopTime = CFAbsoluteTimeGetCurrent() - self.startTime!
                self.endedCleanly = false
            }
            
            // At this point, the experiment object has all reading data
            // Upload experiment to server
            self.dm.uploadExperiment(self.serializeSelfToJSONDict())
            
            print("[ -+- ] Upload successful")
            print("[ === ] Experiment ended cleanly")
            
        }
    }
    
    // MARK: - Experiment Operations
    
    /**
     
     Checks the latency of the connection. If the latency is above a certain
     thesold, the method returns false
     
     - Returns: `Bool`
     
     */
    func checkTimeSync() -> Bool {
        if let td = dm.timeDelta {
            return (td < 1.00)
        } else {
            return false
        }
    }
    
    private func signalRoombaToStart(completion: () -> Void) {
        log("[ --- ] Signalling Roomba to begin...")
        self.dm.socket?.signalStart() { _ in
            completion()
        }
        
//        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
//        dispatch_async(dispatch_get_global_queue(priority, 0)) {
//            self.dm.socket?.signalStart()
//            dispatch_semaphore_wait(self.dm.socket!.serverSignal!, DISPATCH_TIME_FOREVER)
//            completion(start: true)
//        }
    }
    
    private func signalRoombaToRead(completion: () -> Void) {
        log("[ --- ] Singalling Roomba to read...")
        self.dm.socket?.signalReadingMode() { _ in
            completion()
        }
        
//        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
//        dispatch_async(dispatch_get_global_queue(priority, 0)) {
//            self.dm.socket?.signalReadingMode()
//            dispatch_semaphore_wait(self.dm.socket!.serverSignal!, DISPATCH_TIME_FOREVER)
//            completion(read: true)
//        }
        
    }
    
    private func signalRoombaExperimentEnd(completion: (success: Bool) -> Void) {
        log("[ --- ] Signalling end of experiment...")
        
        self.dm.socket?.signalEndOfExperiment() { _ in
            completion(success: true)
        }
    }
    
    private func takeReading(completion: (success: Bool) -> Void) {
        log("[ --- ] Reading...")
        
        // Signal Roomba to spin iPhone
        self.dm.socket?.signalReadNow() { _ in
            
            self.maxR = 0.0; self.maxY = 0.0; self.maxP = 0.0
            NSTimer.scheduledTimerWithTimeInterval(
                1.0,
                target   : self,
                selector : #selector(Experiment.getPowerLevels),
                userInfo : nil,
                repeats  : true
            )

            print("[ -+- ] Reading Done")
            completion(success: true)
        }
    }
    
    @objc private func getPowerLevels() {
        if readingCount < 6 {
            let redPL    = ip.getPowerLevelForHue(ip.red, threshold: ip.colorThreshold)
            let yellowPL = ip.getPowerLevelForHue(ip.yellow, threshold: ip.colorThreshold)
            let purplePL = ip.getPowerLevelForHue(ip.purple, threshold: ip.colorThreshold)
            
            if  redPL    > maxR { maxR = redPL }
            if  yellowPL > maxY { maxY = yellowPL }
            if  purplePL > maxP { maxP = purplePL }
            
            readingCount += 1
        } else {
            let currentTime = CFAbsoluteTimeGetCurrent()
            readingsArray?.append((red: maxR!, yellow: maxY!, purple: maxP!, time: currentTime))
            readingTimer?.invalidate()
        }
    }
    
    // MARK: - Utility Methods
    
    // TODO: Implement
    func serializeSelfToJSONDict() -> [String: AnyObject] {
        var selfAsDictionary: [String: AnyObject] = [:]
        
        selfAsDictionary["title"] = self.title
        selfAsDictionary["startTime"] = self.startTime
        selfAsDictionary["stopTime"] = self.stopTime
        
        var arrayOfReadingDictionaries: [[String: Double]] = []
        for r in self.readingsArray! {
            var readingsAsDictionary: [String: Double] = [:]
            readingsAsDictionary["timestamp"] = r.time
            readingsAsDictionary["LightRPL"]  = r.red
            readingsAsDictionary["LightYPL"]  = r.yellow
            readingsAsDictionary["LightPPL"]  = r.purple
            arrayOfReadingDictionaries.append(readingsAsDictionary)
        }
        selfAsDictionary["readings"] = arrayOfReadingDictionaries
        
        if NSJSONSerialization.isValidJSONObject(selfAsDictionary) {
            let data = NSKeyedArchiver.archivedDataWithRootObject(selfAsDictionary)
            let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            print(json)
            print("[ EXP ] Experiment successfully converted to JSON")
            return selfAsDictionary
        } else {
            print(" [ ERR ] Could not serialize Experiment object to JSON")
            return ["":""]
        }
    }
    
    private func log(line: String) {
        if let lo = self.logOutput {
            lo.text = lo.text + "\(line)\n"
        }
        print(line)
    }
}

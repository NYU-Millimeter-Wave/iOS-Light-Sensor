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
    
    /// Total number of seconds to run an experiment
    var maxExperimentDuration: Double = 30
    
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
    private var experimentTimer        : NSTimer?
    private var readingTimer           : NSTimer?
    private var readingOperationsTimer : NSTimer?
    
    // Color buffers for reading
    private var maxR: Double!
    private var maxY: Double!
    private var maxP: Double!
    private var readingTime: CFAbsoluteTime!
    
    // MARK: - Initalizers
    
    init(title: String) {
        super.init()
        self.title = title
    }
    
    // MARK: - Experiment Control Flow
    
    /**
     
     Starts the experiment main loop that will run until the max
     experiment time is reached.
     
     - Returns: `nil`
     
     */
    func beginExperiment() {
        log("[ === ] Starting New Experiment: \(title)")
        log("[ --- ] Checking time sync...")
        
        if self.checkTimeSync() {
            log("[ -+- ] Time sync complete")
            
            self.signalRoombaToStart() { _ in
                self.log("[ -+- ] Roomba acknowledged experiment begin")
                
                self.startTime = CFAbsoluteTimeGetCurrent()
                self.log("[ --- ] Starting experiment with start time \(self.startTime!)")
                
                // Start Experiment timer
                self.experimentTimer =  NSTimer.scheduledTimerWithTimeInterval(
                    self.maxExperimentDuration,
                    target   : self,
                    selector : #selector(self.endExperiment),
                    userInfo : nil,
                    repeats  : false
                )
                
                // Start Reading Operations Timer
                self.readingOperationsTimer = NSTimer.scheduledTimerWithTimeInterval(
                    5.0,
                    target: self,
                    selector: #selector(self.performReadingOperations),
                    userInfo: nil,
                    repeats: true
                )
            }
            
        } else {
            log("[ === ] Could not verify time sync, stopping...")
            endedCleanly = false
        }
    }
    
    /**
     
     Performs all the reading operations and logs results to the
     readings array
     
     - Returns: `nil`
     
     */
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
    
    /**
     
     Signals the end of the experiment to the Roomba. The results of 
     the experiment will then be uploaded to server and the Roomba will
     perform its teardown operations.
     
     - Returns: `nil`
     
     */
    func endExperiment() {
        // Invalidate Timers
        self.readingOperationsTimer?.invalidate()
        self.experimentTimer?.invalidate()
        
        // Send end signal
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
    
    /**
     
     Wrapper function to invoke the Roomba to start (move forward)
     
     - Returns: `nil`
     
     */
    private func signalRoombaToStart(completion: () -> Void) {
        log("[ --- ] Signalling Roomba to begin...")
        self.dm.socket?.signalStart() { _ in
            completion()
        }
    }
    
    /**
     
     Wrapper function to invoke the Roomba to read (stop motors)
     
     - Returns: `nil`
     
     */
    private func signalRoombaToRead(completion: () -> Void) {
        log("[ --- ] Singalling Roomba to read...")
        self.dm.socket?.signalReadingMode() { _ in
            completion()
        }
    }
    
    /**
     
     Wrapper function to invoke the Roomba to end experiment and
     start teardown operations
     
     - Returns: `nil`
     
     */
    private func signalRoombaExperimentEnd(completion: (success: Bool) -> Void) {
        log("[ --- ] Signalling end of experiment...")
        
        self.dm.socket?.signalEndOfExperiment() { _ in
            completion(success: true)
        }
    }
    
    /**
     
     Invokes the iPhone mount motor to turn and initializes
     timer to take power level readings at interval
     
     - Returns: `nil`
     
     */
    private func takeReading(completion: (success: Bool) -> Void) {
        log("[ --- ] Reading...")
        
        // Signal Roomba to spin iPhone
        self.dm.socket?.signalReadNow() { _ in
            
            self.maxR = 0.0; self.maxY = 0.0; self.maxP = 0.0
            self.readingTime = CFAbsoluteTimeGetCurrent()
            NSTimer.scheduledTimerWithTimeInterval(
                1.0,
                target   : self,
                selector : #selector(self.getPowerLevels),
                userInfo : nil,
                repeats  : true
            )

            print("[ -+- ] Reading Done")
            completion(success: true)
        }
    }
    
    /**
     
     Finds the max power levels for consecutive readings in one
     reading operation and updates the max levels. Once the readings are
     over, the max power levels are added to the reading array along with
     a timestamp.
     
     - Returns: `nil`
     
     */
    @objc private func getPowerLevels() {
        if readingCount < 6 {
            
            // Get observed power levels
            let redPL    = ip.getPowerLevelForHue(ip.red, threshold: ip.colorThreshold)
            let yellowPL = ip.getPowerLevelForHue(ip.yellow, threshold: ip.colorThreshold)
            let purplePL = ip.getPowerLevelForHue(ip.purple, threshold: ip.colorThreshold)
            
            // Compare them to max power levels found in this reading operation
            if  redPL    > maxR { maxR = redPL }
            if  yellowPL > maxY { maxY = yellowPL }
            if  purplePL > maxP { maxP = purplePL }
            
            readingCount += 1
        } else {
            // Append
            readingsArray?.append((red: maxR!, yellow: maxY!, purple: maxP!, time: self.readingTime))
            
            // Reset max levels
            maxR = 0
            maxY = 0
            maxP = 0
            
            // Stop timer
            readingTimer?.invalidate()
        }
    }
    
    // MARK: - Utility Methods
    
    /**
     
     Converts self into a Dictionary object that is fit
     for JSON serialization. This will be fed into a POST
     request to save the experiment to the Roomba
     
     - Returns: `nil`
     
     */
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
    
    /**
     
     Function to print message to console and to a 
     textView simultaneously
     
     - Parameter line: A String containing the message
     
     - Returns: `nil`
     
     */
    private func log(line: String) {
        if let lo = self.logOutput {
            lo.text = lo.text + "\(line)\n"
        }
        print(line)
    }
}

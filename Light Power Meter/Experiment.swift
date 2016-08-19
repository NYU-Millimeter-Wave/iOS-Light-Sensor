//
//  Experiment.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/23/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import GPUImage

class Experiment: NSObject {
    
    // MARK: - Class Properties
    
    /// The title of the experiment
    var title: String?
    
    /// Optional Text View to log output
    var logOutput: UITextView?
    
    /// Total number of seconds to run an experiment
    var maxExperimentDuration: Double = 60.0
    
    /// The number of seconds between each reading
    var readingInterval: Double = 10.0  // (Each reading is ~ 5.0)
    
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
        self.readingsArray = []
    }
    
    // MARK: - Experiment Control Flow
    
    /**
     
     Starts the experiment main loop that will run until the max
     experiment time is reached.
     
     - Returns: `nil`
     
     */
    func beginExperiment() {
        log("[ === ] Starting New Experiment: \(title!)")
        log("[ --- ] Checking Time Sync")
        
        // Check time sync
        if self.checkTimeSync() {
            
            // Latency is good
            log("[ -+- ] Time sync complete")
            
            // Signalling start of experiment
            self.dm.socket?.signalStart({
                //            self.dm.socket?.socket.send(text: "START")
                self.log("[ -+- ] Roomba acknowledged experiment begin")
                
                // Get start time
                self.startTime = CFAbsoluteTimeGetCurrent()
                self.log("[ --- ] Starting experiment with start time \(self.startTime!)")
                
                // Begin the experiment timer
                self.experimentTimer =  NSTimer.scheduledTimerWithTimeInterval(
                    self.maxExperimentDuration,
                    target   : self,
                    selector : #selector(self.endExperiment),
                    userInfo : nil,
                    repeats  : false
                )
                
                // Begin Reading Operations Timer
                // (+5, a reading is ~5 seconds)
                self.readingOperationsTimer = NSTimer.scheduledTimerWithTimeInterval(
                    self.readingInterval,
                    target: self,
                    selector: #selector(self.performReadingOperations),
                    userInfo: nil,
                    repeats: true
                )
            })
        } else {
            log("[ -x- ] Bad time sync ending...")
            endedCleanly = false
        }
    }
    
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
     
     Performs all the reading operations and logs results to the
     readings array
     
     - Returns: `nil`
     
     */
    func performReadingOperations() {
        self.dm.socket?.signalReadingMode({})
        
        self.log("[ -+- ] Roomba in reading mode")
        self.log("[ --- ] Reading now...")
        
        // Reset max levels
        self.maxR = 0.0; self.maxY = 0.0; self.maxP = 0.0
        
        // Get reading timestamp
        self.readingTime = CFAbsoluteTimeGetCurrent()
        
        // Synconous, blocking
        var i: Int = 5
        while(i > 0) {
            // Get observed power levels
            let redPL    = self.ip.getPowerLevelForHue(self.ip.red, threshold: self.ip.colorThreshold)
            let yellowPL = self.ip.getPowerLevelForHue(self.ip.yellow, threshold: self.ip.colorThreshold)
            let purplePL = self.ip.getPowerLevelForHue(self.ip.purple, threshold: self.ip.colorThreshold)
            
            // Log PLs
            self.log("Power levels R: \(redPL) Y: \(yellowPL) P: \(purplePL)")
            
            // Compare them to max power levels found in this reading operation
            if  redPL    > self.maxR { self.maxR = redPL }
            if  yellowPL > self.maxY { self.maxY = yellowPL }
            if  purplePL > self.maxP { self.maxP = purplePL }
            
            // Wait 1 second, blocking
            sleep(1)
            
            i -= 1
        }
        
        // Append to readingsArray
        self.readingsArray?.append((red: self.maxR!, yellow: self.maxY!, purple: self.maxP!, time: self.readingTime))
        
        self.log("[ -+- ] Reading Done")
        
        // Block thread while roomba finishes
        sleep(7)
    }

    /**
     
     Signals the end of the experiment to the Roomba. The results of 
     the experiment will then be uploaded to server and the Roomba will
     perform its teardown operations.
     
     - Returns: `Bool` Success of closure
     
     */
    func endExperiment() {
        
        // Invalidate Timer
        self.readingOperationsTimer?.invalidate()
        
        // Send end signal
        self.dm.socket?.signalEndOfExperiment({
            self.log("[ -+- ] Roomba aknowledged end of experiment")
            self.stopTime = CFAbsoluteTimeGetCurrent()
            self.log("[ === ] Experiment ened with stop time: \(self.stopTime!)")
            self.log("[ --- ] Uploading experiment to server...")
            self.endedCleanly = true
            
            self.dm.uploadExperiment(self, completion: { success in
                if success {
                    self.log("[ -+- ] Experiment uploaded successfully")
                    self.log("[ --- ] Exiting...")
                } else {
                    self.log("[ -x- ] Upload failed")
                    self.log("[ --- ] Exiting...")
                }
            })
        })
    }
    
    /**
     
     Forcefully end an experiment from continuing due
     to error.
     
     - Returns: `nil`
     
     */
    func forceEnd() {
        
        self.log("[ ERR ] Experiment ending forcefully")
        
        // Signal socket directly to stop motors, ignore result
        self.dm.socket?.signalEndOfExperiment({ _ in })
        
        // Set to unclean
        self.endedCleanly = false
    }

    // MARK: - Utility Methods
    
    static func generateTestObject() -> Experiment {
        let newExp = Experiment(title: "Test Run 1")
        newExp.startTime = CFAbsoluteTimeGetCurrent()
        newExp.stopTime  = CFAbsoluteTimeGetCurrent() + (30000)
        for _ in 0...10 {
            let newTuple = (red: getRando(), yellow: getRando(), purple: getRando(), time: Double(CFAbsoluteTimeGetCurrent()))
            newExp.readingsArray?.append(newTuple)
        }
        newExp.endedCleanly = true
        return newExp
    }
    private static func getRando() -> Double {
        return Double(Float(arc4random()) / Float(UINT32_MAX))
    }
    
    /**
     
     Converts self into a Dictionary object that is fit
     for JSON serialization. This will be fed into a POST
     request to save the experiment to the Roomba
     
     - Returns: `nil`
     
     */
    func serializeSelfToJSONDict() -> [String: AnyObject] {
        var selfAsDictionary = [String: AnyObject]()
        
        selfAsDictionary["title"] = self.title
        selfAsDictionary["startTime"] = self.startTime
        selfAsDictionary["stopTime"] = self.stopTime
        
        var arrayOfReadingDictionaries = [[String: Double]]()
        for r in self.readingsArray! {
            var readingsAsDictionary = [String: Double]()
            readingsAsDictionary["timestamp"] = r.time
            readingsAsDictionary["LightRPL"]  = r.red
            readingsAsDictionary["LightYPL"]  = r.yellow
            readingsAsDictionary["LightPPL"]  = r.purple
            arrayOfReadingDictionaries.append(readingsAsDictionary)
        }
        selfAsDictionary["readings"] = arrayOfReadingDictionaries
        
        if NSJSONSerialization.isValidJSONObject(selfAsDictionary) {
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

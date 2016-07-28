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
    
    // Here will go our experiment variables ----------------------------
    
    /// Exact time of start of experiment
    var startTime: CFAbsoluteTime?
    
    /// Exact time of end of experiment
    var stopTime:  CFAbsoluteTime?
    
    // MARK: - Private Class Properties
    
    // Singletons
    
    private let dm = DataManager.sharedManager
    private let ip = ImageProcessor.sharedProcessor
    
    // Photo Processing Properties
    
    // Count of readings taken for timer
    private var readingCount: Int = 0
    
    // Timer to trigger reading
    private var readingTimer: NSTimer?
    
    // Array to store power levels
    private var readingsArray: [(red: Double, yellow: Double, purple: Double)]?
    
    // MARK: - Initalizers
    
    init(title: String) {
        super.init()
        self.title = title
    }
    
    // MARK: - Experiment Control Flow
    
    func beginExperiment() {
        log("[ === ] NEW EXPERIMENT START")
        log("[ --- ] Checking time sync...")
        
        if self.checkTimeSync() {
            log("[ -+- ] Time sync complete")
            
            self.startTime = CFAbsoluteTimeGetCurrent()
            log("[ --- ] Starting experiment with start time \(self.startTime!)")
            
            self.signalRoombaToStart() { _ in
                self.log("[ -+- ] Roomba acknowledged experiment begin")
                self.performReadingOperations()
            }
            
        } else {
            log("[ -x- ] Could not verify time sync, stopping...")
            log("[ === ] NEW EXPERIMENT END")
        }
    }
    
    func performReadingOperations() {
        self.signalRoombaToRead() { _ in
            self.log("[ -+- ] Roomba in reading mode")
            self.takeReading() { success in
                
                if success == true {
                    self.log("[ -+- ] Reading done")
                    self.log("[ --- ] Uploading Resutls to server...")
                    // TODO: UPLOAD READING TO SERVER PURGE READING ARRAY
                    
                    self.log(" [ -+- ] Success")
                }
            }
        }
    }
    
    func endExperiment() {}
    
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
        log("[ ---] Signalling end of experiment")
        
        self.dm.socket?.signalEndOfExperiment() { _ in
            self.stopTime = CFAbsoluteTimeGetCurrent() - self.startTime!
            self.log("[ === ] Experiment ended successfully")
        }
    }
    
    private func takeReading(completion: (success: Bool) -> Void) {
        log("[ --- ] Reading...")
        // Get current time for timestamp
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        // Signal Roomba to spin iPhone
        self.dm.socket?.signalReadNow() { _ in
            
            NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(Experiment.getPowerLevels), userInfo: nil, repeats: true)
            
            let endTime = CFAbsoluteTimeGetCurrent() - currentTime
            print("Reading completed in: \(endTime)")
            completion(success: true)
        }
    }
    
    @objc private func getPowerLevels() {
        if readingCount < 6 {
            let redPL    = ip.getPowerLevelForHue(ip.red, threshold: ip.colorThreshold)
            let yellowPL = ip.getPowerLevelForHue(ip.yellow, threshold: ip.colorThreshold)
            let purplePL = ip.getPowerLevelForHue(ip.purple, threshold: ip.colorThreshold)
            
            readingsArray?.append((red: redPL, yellow: yellowPL, purple: purplePL))
            readingCount += 1
        } else {
            readingTimer?.invalidate()
        }
    }
    
    // MARK: - Utility Methods
    
    // TODO: Implement
    func serializeSelfToJSON() -> String {return ""}
    
    private func log(line: String) {
        if let lo = self.logOutput {
            lo.text = lo.text + "\(line)\n"
        }
        print(line)
    }
}

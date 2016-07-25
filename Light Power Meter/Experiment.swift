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
    
    /// Dictionary to store timestamp and detection results (R, Y, P)
    lazy var lightDetectionReadings: Dictionary<String, (Bool, Bool, Bool)> = [:]
    
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
    
    // Count of taken photos for timer
    private var photoCount: Int = 0
    
    // Timer to trigger photo capture
    private var photoTimer: NSTimer?
    
    // Array to store images to process (color, mask)
    private lazy var photoBuffer: [(UIImage, UIImage)] = []
    
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
                self.experimentMainLoop()
            }
            
        } else {
            log("[ -x- ] Could not verify time sync, stopping...")
            log("[ === ] NEW EXPERIMENT END")
        }
    }
    
    func experimentMainLoop() {
        self.signalRoombaToRead() { _ in
            self.log("[ -+- ] Roomba in reading mode")
            self.takeReading() { _ in
                self.log("[ -+- ] Reading done")
                    
                // TODO: UPLOAD READING TO SERVER
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
    
    func signalRoombaToStart(completion: () -> Void) {
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
    
    func signalRoombaToRead(completion: () -> Void) {
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
    
    func takeReading(completion: () -> Void) {
        log("[ --- ] Reading...")
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            // Get current time for timestamp
            let currentTime = CFAbsoluteTimeGetCurrent()
            
            // Signal Roomba to spin iPhone
            self.dm.socket?.signalReadNow() { _ in
                
                // TODO: POLL POWER METER

                let endTime = CFAbsoluteTimeGetCurrent() - currentTime
                print("Reading completed in: \(endTime)")
                completion()
            }
            
            // Wait for signal to verify
            dispatch_semaphore_wait(self.dm.socket!.serverSignal!, DISPATCH_TIME_FOREVER)
            
//            // TODO: POLL POWER METER
//            
//            
//            
//            let endTime = CFAbsoluteTimeGetCurrent() - currentTime
//            print("Reading completed in: \(endTime)")
//            
////            for (color, mask) in self.photoBuffer {
////                
////            }
////            
////            let resultTuple = (false, false, false)
////            self.lightDetectionReadings["\(currentTime)"] = resultTuple
//            completion(done: true)
        }
    }
    
    private func takePhotoForTimer() {
        if self.photoCount >= 6 {
            self.photoTimer?.invalidate()
            self.photoTimer = nil
        } else {
//            self.photoBuffer[photoCount] = ip.takeStillImage()
        }
    }
    
    // MARK: - Utility Methods
    
    func serializeSelfToJSON() -> String {return ""}
    
    private func log(line: String) {
        if let lo = self.logOutput {
            lo.text = lo.text + "\(line)\n"
        }
        print(line)
    }
}

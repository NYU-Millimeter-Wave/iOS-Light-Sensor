//
//  SocketListener.swift
//  Light Power Meter
//
//  Created by Cole Smith on 7/1/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import SwiftWebSocket

class SocketListener: NSObject, WebSocketDelegate {
    
    // MARK: - Class Properties
    
    private let dm = DataManager.sharedManager
    
    /// Indicates socket connection to server
    var isConnected: Bool = false
    
    /// General-use semaphore for server waiting
    var serverSignal: dispatch_semaphore_t?
    
    var socket: WebSocket!
    
    // MARK: - Initializers
    
    init(url: String) {
        super.init()
        print("[ DAT ] Opening socket on: \(url)")
        
        // Socket Configuration
        self.socket = WebSocket(url:NSURL(string: url)!)
        self.socket.delegate = self
    }
    
    // MARK: - Web Socket Delegate Methods
    
    func webSocketOpen() {
        print("[ DAT ] Socket Connected")
        self.isConnected = true
        self.dm.syncronizeTime()
        
    }

    func webSocketMessageText(text: String) {
        print("[ DAT ] Received: \(text)")
        
        // Sense the echo and release the semaphore
        switch text {
        case "VSTART", "VREADING", "VREADNOW", "VENDEXP":
            dispatch_semaphore_signal(self.serverSignal!)
        default:
            print("bip")
            break
        }
    }
    
    func webSocketMessageData(data: NSData) {
        print("[ DAT ] Received: \(data)")
    }
    
    func webSocketPong() {
        print("[ DAT ] Received Pong")
        self.dm.pongReceived = true
    }
    
    func webSocketError(error: NSError) {
        let errorString = error.localizedDescription
        print("[ ERR ] Socket error: \(errorString)")
    }
    
    func webSocketClose(code: Int, reason: String, wasClean: Bool) {
        if wasClean {
            print("[ DAT ] Socket Closed Cleanly")
        } else {
            print("[ ERR ] Socket Closed Uncleanly: \(code)")
        }
        
        self.isConnected = false
        self.dm.pongReceived = false
    }
    
    // MARK: - Sending Methods
    
    /**
     
     Sends a text string to the connected socket server
     
     - Parameter msg: The String to send
     
     - Returns: `nil`
     
     */
    func sendString(msg: String) {
        let msgTimed = "\(NSDate()): \(msg)"
        print("[ DAT ] Socket Sending: \"\(msgTimed)\"")
        self.socket.send(text: msgTimed)
    }
    
    /**
     
     Sends an NSData object to the connected socket server
     
     - Parameter data: The data object to send
     
     - Returns: `nil`
     
     */
    func sendData(data: NSData) {
        socket.send(data: data)
    }
    
    /**
     
     Sends a ping to the connected socket server
     
     - Returns: `nil`
     
     */
    func sendPing() {
        print("[ DAT ] Pinging Server...")
        self.socket.ping()
    }
    
    // MARK: - Control Flow Signal Methods
    
    /*
    The following signal methods are ASYNCRONOUS, but are
    controlled through semaphores. They can be used in syncronous
    contexts for this reason.
    */
    
    /**
     
     Sends Signal to server to begin experiment
     
     - Returns: `nil`
     
     */
    func signalStart(completion: () -> Void) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            self.socket.send(text: "START")
            self.serverSignal = dispatch_semaphore_create(0)
            dispatch_semaphore_wait(self.serverSignal!, DISPATCH_TIME_FOREVER)
            dispatch_async(dispatch_get_main_queue()) {
                completion()
            }
        }
    }
    
    /**
     
     Sends signal to server to prepare to take
     a reading from the iPhone
     
     - Returns: `nil`
     
     */
    func signalReadingMode(completion: () -> Void) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            self.socket.send(text: "READING")
            self.serverSignal = dispatch_semaphore_create(0)
            dispatch_semaphore_wait(self.serverSignal!, DISPATCH_TIME_FOREVER)
            dispatch_async(dispatch_get_main_queue()) {
                completion()
            }
        }
    }
    
    /**
     
     Signals the server to perform the reading
     
     - Returns: `nil`
     
     */
    func signalReadNow(completion: () -> Void) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            self.socket.send(text: "READNOW")
            self.serverSignal = dispatch_semaphore_create(0)
            dispatch_semaphore_wait(self.serverSignal!, DISPATCH_TIME_FOREVER)
            dispatch_async(dispatch_get_main_queue()) {
                completion()
            }
        }
    }
    
    /**
     
     Signals the server to end the experiment and perform
     cleanup operations
     
     - Returns: `nil`
     
     */
    func signalEndOfExperiment(completion: () -> Void) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            self.socket.send(text: "ENDEXP")
            self.serverSignal = dispatch_semaphore_create(0)
            dispatch_semaphore_wait(self.serverSignal!, DISPATCH_TIME_FOREVER)
            dispatch_async(dispatch_get_main_queue()) {
                completion()
            }
        }
    }
    // MARK: - Closure Methods
    
    /**
     
     Closes the socket connection
     
     - Returns: `nil`
     
     */
    func close() {
        self.socket.close()
    }
    
    /**
     
     Remotely shuts down the socket server and
     cleanly closes client connection
     
     - Returns: `nil`
     
     */
    func remotelyCloseServer() {
        self.socket.send(text: "SHUTDOWN")
        self.close()
    }
}

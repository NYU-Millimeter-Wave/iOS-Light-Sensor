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
    
    /// Number of messages sent to the socket server
    var messageCount: Int = 0
    
    /// Indicates socket connection to server
    var isConnected: Bool = false
    
    private var socket: WebSocket!
    
    // MARK: - Initializers
    
    init(url: String) {
        super.init()
        print("[ INF ] Opening socket on: \(url)")
        
        // Socket Configuration
        self.socket = WebSocket(url:NSURL(string: url)!)
        self.socket.delegate = self
    }
    
    // MARK: - Web Socket Delegate Methods
    
    func webSocketOpen() {
        print("[ INF ] Socket Connected")
        self.isConnected = true
        self.dm.syncronizeTime()
    }

    func webSocketMessageText(text: String) {
        print("[ DAT ] Received: \(text)")
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
            print("[ INF ] Socket Closed Cleanly")
        } else {
            print("[ ERR ] Socket Closed Uncleanly: \(reason)")
        }
        
        self.isConnected = false
        self.dm.pongReceived = false
    }
    
    // MARK: - Transmission Methods
    
    /**
     
     Sends a text string to the connected socket server
     
     - Parameter msg: The String to send
     
     - Returns: `nil`
     
     */
    func sendString(msg: String) {
        messageCount += 1
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
        messageCount += 1
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
    
    /**
     
     Closes the socket connection
     
     - Returns: `nil`
     
     */
    func close() {
        self.socket.close()
    }
}

//
//  SocketListener.swift
//  Light Power Meter
//
//  Created by Cole Smith on 7/1/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import SwiftWebSocket

class SocketListener: NSObject {
    
    // MARK: - Class Properties
    
    /// Number of messages sent to the socket server
    var messageCount: Int
    
    private var socket: WebSocket
    
    // MARK: - Initializers
    
    init(url: String) {
        
        print("[ INF ] Opening socket on: \(url)")
        
        // Socket Configuration
        self.socket = WebSocket(url:NSURL(string: url)!)
        self.messageCount = 0
        self.socket.event.open = {
            print("[ INF ] Socket Connected")
        }
        self.socket.event.close = { code, reason, clean in
            print("[ INF ] Socket Closed")
        }
        self.socket.event.message = { message in
            if let msg = message as? String {
                print("[ DAT ] Received: \(msg)")
            }
        }
        self.socket.event.error = { error in
            print("[ ERR ] Socket Error: \(error)")
        }
        
        super.init()
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
        socket.send(text: msgTimed)
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
     
     Closes the socket connection
     
     - Returns: `nil`
     
     */
    func close() {
        self.socket.close()
    }
}

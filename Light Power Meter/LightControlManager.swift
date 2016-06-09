//
//  LightControlManager.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/9/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import Foundation
import Alamofire

class LightControlManager: NSObject {
    
    // MARK: - Singleton Declaration
    static let sharedManager = LightControlManager()
    
    // MARK: - Networking Constants
    
    /// Static IP of the Philips Hue Bridge
    let bridgeIP = "172.24.113.38"
    
    /// MAC Address of the Philips Hue Bridge
    let bridgeMAC = "00:17:88:26:98:F9"
    
    /// Unique authorized user of the Philips Hue Bridge
    let bridgeUser = "6478a30667c36d213e7a5df45f72255b"
    
    // MARK: - Initalizers
    
    private override init() {
        super.init()
        print("Light Control Manager Init")
        setLight(2, saturation: 255, brightness: 100, hue: 5555)
    }
    
    // MARK: - Philips Hue Utility Methods
    
    /**
     
     Sends a POST request to the IP address with bridgeUser to turn
     on the light specified (light 1 - 3)
     
     - Parameter lightNumber: The light to turn on or off
     - Parameter lightOn: `true` turns the light on, and `false` turns it off
     
     - Returns: `nil`
     
     */
    func setLightOn(lightNumber: Int!, lightOn: Bool!) {
        print("Setting light \(lightNumber) to \(lightOn)")
        
        let url: String = "http://\(bridgeIP)/api/\(bridgeUser)/lights/\(lightNumber)/state"
        Alamofire.request(.PUT, url, parameters: ["on": lightOn], encoding: .JSON)
    }
    
    /**
     
     Sends a POST request to the specified light to change its color or brightness.
     Also turns the light on if it's off.
     
     - Parameter lightNumber: The light to change properties of
     - Parameter saturation: Color saturation value (0 - 255)
     - Parameter brightness: Brightness of bulb value (0 - 255)
     - Parameter hue: Hue value of light (0 - 10000)
     
     - Returns: `nil`
     
     */
    func setLight(lightNumber: Int!, saturation: Int!, brightness: Int!, hue: Int!) {
        print("Setting light \(lightNumber) to -- sat: \(saturation) bri: \(brightness) hue: \(hue)")
        
        let url: String = "http://\(bridgeIP)/api/\(bridgeUser)/lights/\(lightNumber)/state"
        Alamofire.request(.PUT, url, parameters: ["on": true, "sat": saturation, "bri": brightness, "hue": hue], encoding: .JSON)
    }
}
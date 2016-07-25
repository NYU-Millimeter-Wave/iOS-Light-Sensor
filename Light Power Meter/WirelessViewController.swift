//
//  WirelessViewController.swift
//  Light Power Meter
//
//  Created by Cole Smith on 7/6/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
/////                                                       /////
/////                  CLASS DEPRECATED                     /////
/////                                                       /////
/////       -------use ControlViewController--------        /////
/////                                                       /////
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

import UIKit
class WirelessViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var connectionIndicator: UILabel!
    @IBOutlet weak var ipField: UITextField!
    
    // MARK: - Class Properties
    
    let dm = DataManager.sharedManager
    
    var connected:  Bool = false
    
    var disconnectedIcon: String = "⚪️"
    var connectedIcon:    String = "🔵"

    // MARK: - Initalizers

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("Class Deprecated")
    }
    
    // MARK: - View Handlers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Navigation Bar
        let navBar = self.navigationController?.navigationBar
        navBar?.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navBar?.shadowImage = UIImage()
        navBar?.backgroundColor = UIColor.clearColor()
        navBar?.translucent = true
        
        self.checkConnected()
        NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(WirelessViewController.checkConnected), userInfo: nil, repeats: true)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    func checkConnected() {
        // Check Socket Connection
        if let socket = self.dm.socket {
            if socket.isConnected {
                self.connected = true
            } else {
                self.connected = false
            }
        } else {
            print("[ ERR ] Accessed uninitialized socket")
            self.connected = false
        }
        
        if self.connected {
            self.connectionIndicator.text = connectedIcon
            self.connectButton.enabled = false
        } else {
            self.connectionIndicator.text = disconnectedIcon
            self.connectButton.enabled = true
        }
    }
    
    // MARK: - Actions
    
    @IBAction func connectPressed(sender: AnyObject) {
        if let txt = self.ipField.text {
            self.dm.socket = SocketListener(url: txt)
        }
    }
    
    @IBAction func menuPressed(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }
}

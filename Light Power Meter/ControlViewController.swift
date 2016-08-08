//
//  ControlViewController.swift
//  Light Power Meter
//
//  Created by Cole Smith on 7/8/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit

class ControlViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var connectionIndicator: UILabel!
    @IBOutlet weak var ipField: UITextField!
    @IBOutlet var colorLabels: [UIButton]!
    
    // MARK: - Class Properties
    
    private let dm = DataManager.sharedManager
    private let ip = ImageProcessor.sharedProcessor
    
    var experiment: Experiment!
    
    var connected:  Bool = false
    var disconnectedIcon: String = "◎"
    var connectedIcon:    String = "◉"
    
    // MARK: - Initalizers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        
        // Label Styling
        for l in colorLabels {
            l.layer.masksToBounds = true
            l.layer.cornerRadius = 15.0
        }
        
        colorLabels[0].backgroundColor = UIColor(hue: CGFloat(ip.red    / 360.0), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        colorLabels[1].backgroundColor = UIColor(hue: CGFloat(ip.yellow / 360.0), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        colorLabels[2].backgroundColor = UIColor(hue: CGFloat(ip.purple / 360.0), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        
        // Check connection every 3 seconds
         self.checkConnected()
         NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(ControlViewController.checkConnected), userInfo: nil, repeats: true)
        
        // test
        self.ipField.text = "ws://172.16.28.45:9000"
        self.nameField.text = "test"
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    func checkConnected() {
        if let socket = self.dm.socket {
            if socket.isConnected {
                self.connected = true
            } else {
                self.connected = false
            }
        } else {
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
    
    func throwErrorMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func connectPressed(sender: AnyObject) {
        if let txt = self.ipField.text {
            self.dm.connectionIP = txt
            let formattedForSocket = "ws://\(txt):9000"
            self.dm.socket = SocketListener(url: formattedForSocket)
        }
    }
    
    func finalizeExperiment() {
        self.experiment = Experiment(title: self.nameField.text!)
        performSegueWithIdentifier("final", sender: nil)
    }
    
    @IBAction func menuPressed(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }

    @IBAction func finalizePressed(sender: AnyObject) {
        if nameField.text == "" || ipField.text == "" {
            throwErrorMessage("Cannot Finalize", message: "All fields are required")
        } else if self.connected == false {
            if let txt = self.ipField.text {
                self.dm.socket = SocketListener(url: txt)
            }
            checkConnected()
            if self.connected == false {
                throwErrorMessage("Cannot Finalize", message: "Could not conect to server")
            } else {
                finalizeExperiment()
            }
        } else {
            finalizeExperiment()
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "final" {
            let vc = segue.destinationViewController as! ControlConfirmViewController
            vc.experiment = self.experiment
            vc.tcpText = self.ipField.text
        }
    }
}

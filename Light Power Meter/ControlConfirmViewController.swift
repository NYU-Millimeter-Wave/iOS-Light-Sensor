//
//  ControlConfirmViewController.swift
//  Light Power Meter
//
//  Created by Cole Smith on 7/27/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit

class ControlConfirmViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var nameField: UILabel!
    @IBOutlet weak var tcpAddress: UILabel!
    @IBOutlet weak var connected: UILabel!
    @IBOutlet var colorLabels: [UIButton]!
    
    // MARK: - Class Properties
    
    private let ip = ImageProcessor.sharedProcessor
    private let dm = DataManager.sharedManager
    
    var experiment: Experiment!
    var tcpText: String!
    
    var isConnected:  Bool = false
    var disconnectedIcon: String = "◎"
    var connectedIcon:    String = "◉"
    
    // MARK: - Initalizers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View Handlers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.lightGrayColor()
        
        nameField.text  = experiment.title
        tcpAddress.text = tcpText
        
        for l in colorLabels {
            l.layer.masksToBounds = true
            l.layer.cornerRadius = 15.0
        }
        
        colorLabels[0].backgroundColor = UIColor(hue: CGFloat(ip.red    / 360.0), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        colorLabels[1].backgroundColor = UIColor(hue: CGFloat(ip.yellow / 360.0), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        colorLabels[2].backgroundColor = UIColor(hue: CGFloat(ip.purple / 360.0), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        
        checkConnected()
    }
    
    // MARK: - Utility Methods
    
    func checkConnected() {
        if let socket = self.dm.socket {
            if socket.isConnected {
                self.isConnected = true
            } else {
                self.isConnected = false
            }
        } else {
            self.isConnected = false
        }
        
        if self.isConnected {
            self.connected.text = connectedIcon
        } else {
            self.connected.text = disconnectedIcon
        }
    }
    
    func throwErrorMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func startPressed(sender: AnyObject) {
        if isConnected {
            performSegueWithIdentifier("start", sender: nil)
        } else {
            throwErrorMessage("Not Connected", message: "You need to be connected over TCP to start")
        }
    }

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "start" {
            let vc = segue.destinationViewController as! MonitorViewController
            vc.experiment = self.experiment
        }
    }
}

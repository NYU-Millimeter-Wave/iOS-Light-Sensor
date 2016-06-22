//
//  PowerMeterViewController.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/15/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import GPUImage

class PowerMeterViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var preview: UIView!
    @IBOutlet var buttons: [UIButton]!
    
    // MARK: - Class Properties
    
    let ip = ImageProcessor.sharedProcessor
    lazy var filterInput: Bool = true
    var timer: NSTimer!
    
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
        
        for button in buttons {
            button.layer.cornerRadius = 40
            button.layer.masksToBounds = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        buttons[0].backgroundColor = self.ip.red
        buttons[1].backgroundColor = self.ip.yellow
        buttons[2].backgroundColor = self.ip.purple
        
        ip.filterInputStream(self.view as! GPUImageView)
    }
    
    override func viewWillDisappear(animated: Bool) {
        ip.stopCapture()
    }
    
    // MARK: - Actions
    
    @IBAction func buttonPressed(sender: AnyObject) {
        buttons[sender.tag].setTitle("TRACK", forState: .Normal)
        for button in buttons {
            if button.tag != sender.tag {
                button.setTitle("•", forState: .Normal)
            }
        }
        switch sender.tag {
        case 0:
            if let red = ip.red {
                ip.targetColorVector = ip.convertUIColorToColorVector(red)
            }
        case 1:
            if let yellow = ip.yellow {
                ip.targetColorVector = ip.convertUIColorToColorVector(yellow)
            }
        case 2:
            if let purple = ip.purple {
                ip.targetColorVector = ip.convertUIColorToColorVector(purple)
            }
        default:
            print("[ ERR ]")
        }
    }
    
    @IBAction func filterPressed(sender: AnyObject) {
        filterInput = !filterInput
        ip.stopCapture()
        if filterInput {
            ip.filterInputStream(self.view as! GPUImageView)
        } else {
            ip.displayRawInputStream(self.view as! GPUImageView)
        }
    }
    
    @IBAction func menuPressed(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }
}

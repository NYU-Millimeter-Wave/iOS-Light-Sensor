//
//  CalibrationViewController.swift
//  CameraTesting
//
//  Created by Cole Smith on 1/11/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import AVFoundation
import SlideMenuControllerSwift
import GPUImage

class CalibrationViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var preview: GPUImageView!
    @IBOutlet weak var progress: UILabel!
    @IBOutlet var buttons: [UIButton]!
    
    // MARK: - Class Properties
    
    private let ip = ImageProcessor.sharedProcessor
    
    let averagingPasses: UInt = 20
    
    // MARK: - Initializers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View Handlers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progress.layer.masksToBounds = true
        progress.layer.cornerRadius = 40
        progress.hidden = true
        
        // Button Styling
        for button in buttons {
            button.layer.cornerRadius = 40
            button.layer.masksToBounds = true
        }
        
        // Navigation Bar
        let navBar = self.navigationController?.navigationBar
        navBar?.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navBar?.shadowImage = UIImage()
        navBar?.backgroundColor = UIColor.clearColor()
        navBar?.translucent = true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.ip.filterInputStream(preview)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.ip.stopCapture()
    }
    
    // MARK: - Actions
    
    @IBAction func menuPressed(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }
    
    @IBAction func buttonPressed(sender: AnyObject) {
        progress.hidden = true
        let hue = ip.multipassHueAverageCalibration(averagingPasses)
        let color = UIColor(hue: CGFloat(hue / 360.0), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        buttons[sender.tag].backgroundColor = color
        
        switch sender.tag {
        case 0:
            self.ip.red = hue
        case 1:
            self.ip.yellow = hue
        case 2:
            self.ip.purple = hue
        default:
            print("[ ERR ] Unexpected error in CalibrationViewController")
        }
        progress.hidden = true
    }
}

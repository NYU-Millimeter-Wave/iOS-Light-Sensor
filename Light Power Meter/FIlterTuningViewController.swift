//
//  FilterTuningViewController.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/14/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import GPUImage

class FilterTuningViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var preview: GPUImageView!
    @IBOutlet var fields: [UITextField]!
    
    // MARK: - Class Properties
    
    private let ip = ImageProcessor.sharedProcessor
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        fields[0].placeholder = "\(ip.colorThreshold)"
        fields[1].placeholder = "\(ip.powerLevelMaximum)"
        fields[2].placeholder = "\(ip.lumeThreshold!)"
        
        ip.filterInputStream(self.preview)
    }
    
    override func viewWillDisappear(animated: Bool) {
        ip.stopCapture()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        self.view.endEditing(true)
    }
    
    // MARK: - Actions
    
    @IBAction func menuPressed(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }
    
    @IBAction func fieldDidChange(sender: AnyObject) {
        switch sender.tag {
        case 0:
            ip.colorThreshold = Double(fields[0].text!)!
        case 1:
            ip.powerLevelMaximum = Double(fields[1].text!)!
        case 2:
            ip.lumeThreshold = CGFloat(Double(fields[2].text!)!)
        default:
            break
        }
    }
}

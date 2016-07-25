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
    
    @IBOutlet var meters: [KDCircularProgress]!
    
    // MARK: - Class Properties
    
    private let ip = ImageProcessor.sharedProcessor
    
    var filterInput: Bool = true
    var meterRefresh: NSTimer!
    
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
        print("Starting Capture")
        ip.filterInputStream(self.view as! GPUImageView)
        
        // Power Meter UI
        meterRefresh = NSTimer.scheduledTimerWithTimeInterval(
            0.5,
            target: self,
            selector: #selector(PowerMeterViewController.updatePowerMeters),
            userInfo: nil,
            repeats: true
        )
    }
    
    override func viewWillDisappear(animated: Bool) {
        print("Stopping Capture")
        meterRefresh.invalidate()
        ip.stopCapture()
    }
    
    func updatePowerMeters() {
//        let totalpx = Double(ip.PIXEL_SIZE.width * ip.PIXEL_SIZE.height)
        let totalpx = 20.0
        meters[0].angle = Double(ip.getPowerLevelForHue(ip.red,    threshold: ip.colorThreshold)) / totalpx
        meters[1].angle = Double(ip.getPowerLevelForHue(ip.yellow, threshold: ip.colorThreshold)) / totalpx
        meters[2].angle = Double(ip.getPowerLevelForHue(ip.purple, threshold: ip.colorThreshold)) / totalpx
    }
    
    // MARK: - Actions
    
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

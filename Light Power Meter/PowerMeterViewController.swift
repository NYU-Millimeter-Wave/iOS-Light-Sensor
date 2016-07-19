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
        
        // Power Meter UI
        meterRefresh = NSTimer.scheduledTimerWithTimeInterval(
                       0.1,
                       target: self,
                       selector: #selector(PowerMeterViewController.pollPowerMeters),
                       userInfo: nil,
                       repeats: true
        )
    }
    
    override func viewWillAppear(animated: Bool) {
        ip.filterInputStream(self.view as! GPUImageView)
    }
    
    override func viewWillDisappear(animated: Bool) {
        ip.stopCapture()
    }
    
    func pollPowerMeters() {
        updatePowerMeters(ip.powerRed, yellow: ip.powerYellow, purple: ip.powerPurple)
    }
    
    func updatePowerMeters(red: Double, yellow: Double, purple: Double) {
        meters[0].angle = red * 360
        meters[1].angle = yellow * 360
        meters[2].angle = purple * 360
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

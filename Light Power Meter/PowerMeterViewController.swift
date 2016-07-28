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
    
    @IBOutlet weak var preview: GPUImageView!
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
        
        let logo = UIImage(named: "logo")
        let imgView = UIImageView(image: logo)
        self.navigationController?.navigationItem.titleView = imgView
    }
    
    override func viewWillAppear(animated: Bool) {
        ip.filterInputStream(preview)
        
        // Power Meter UI
        meterRefresh = NSTimer.scheduledTimerWithTimeInterval(
            0.3,
            target: self,
            selector: #selector(PowerMeterViewController.updatePowerMeters),
            userInfo: nil,
            repeats: true
        )
        refreshMeterColors()
    }
    
    override func viewWillDisappear(animated: Bool) {
        meterRefresh.invalidate()
        ip.stopCapture()
    }
    
    func updatePowerMeters() {
        meters[0].angle = 360 * ip.getPowerLevelForHue(ip.red,    threshold: ip.colorThreshold)
        meters[1].angle = 360 * ip.getPowerLevelForHue(ip.yellow, threshold: ip.colorThreshold)
        meters[2].angle = 360 * ip.getPowerLevelForHue(ip.purple, threshold: ip.colorThreshold)
    }
    
    func refreshMeterColors() {
        meters[0].progressInsideFillColor = UIColor(hue: CGFloat(ip.red) / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        meters[1].progressInsideFillColor = UIColor(hue: CGFloat(ip.yellow) / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        meters[2].progressInsideFillColor = UIColor(hue: CGFloat(ip.purple) / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        
        meters[0].progressColors[0] = UIColor(hue: CGFloat(ip.red) / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        meters[1].progressColors[0] = UIColor(hue: CGFloat(ip.yellow) / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        meters[2].progressColors[0] = UIColor(hue: CGFloat(ip.purple) / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }
    
    // MARK: - Actions
    
    @IBAction func filterPressed(sender: AnyObject) {
        filterInput = !filterInput
        if filterInput {
            ip.reloadCapture()
            for m in meters {
                m.hidden = false
            }
        } else {
            ip.reloadUnfilteredCapture()
            for m in meters {
                m.hidden = true
            }
        }
    }
    
    @IBAction func menuPressed(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }
}

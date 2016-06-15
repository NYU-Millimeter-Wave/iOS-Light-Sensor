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
    
    @IBOutlet var labels: [UILabel]!
    @IBOutlet weak var preview: GPUImageView!
    
    // MARK: - Class Properties
    
    let ip = ImageProcessor.sharedProcessor
    lazy var filterInput: Bool = true
    
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
        
        for label in labels {
            label.layer.cornerRadius = 40
            label.layer.masksToBounds = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        ip.filterInputStream(self.preview)
    }
    
    override func viewDidDisappear(animated: Bool) {
        ip.stopCapture()
    }
    
    // MARK: - Actions
    
    @IBAction func filterPressed(sender: AnyObject) {
        filterInput = !filterInput
        ip.stopCapture()
        if filterInput {
            ip.filterInputStream(self.preview)
        } else {
            ip.displayRawInputStream(self.preview)
        }
    }
    
    @IBAction func menuPressed(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }
}

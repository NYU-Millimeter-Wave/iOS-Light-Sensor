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

class CalibrationViewController: UIViewController {

    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var colorView: UIView!
    
    let cc = CameraCapture()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cc.startSession(preview)
        
        // Navigation Bar
        let navBar = self.navigationController?.navigationBar
        navBar?.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navBar?.shadowImage = UIImage()
        navBar?.backgroundColor = UIColor.clearColor()
        navBar?.translucent = true
        
        // Preview Layer
        preview.layer.cornerRadius = (self.preview.frame.size.width / 2)
        preview.layer.masksToBounds = false
        preview.clipsToBounds = true
        preview.backgroundColor = UIColor.darkGrayColor()
        
        // Reticle
        self.view.addSubview(cc.generateReticle(self.view, preview: preview))
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func menuPressed(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }
    
    @IBAction func capturePressed(sender: AnyObject) {
        var targetColor: UIColor?
        cc.getCalibrationColor() {
            (color: UIColor) in
            targetColor = color
            self.view.backgroundColor = color
        }
    }
}

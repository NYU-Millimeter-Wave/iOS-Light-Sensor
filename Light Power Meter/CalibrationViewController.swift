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
    
    @IBOutlet weak var preview: UIView!
    @IBOutlet var buttons: [UIButton]!
    
    // MARK: - Class Properties
    
    let cc = CameraCapture()
    let ip = ImageProcessor.sharedProcessor
    
    // MARK: - Initializers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View Handlers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
//        // Preview Layer
//        preview.layer.cornerRadius = (self.preview.frame.size.width / 2)
//        preview.layer.masksToBounds = false
//        preview.clipsToBounds = true
//        preview.backgroundColor = UIColor.darkGrayColor()
        
        // Reticle
        self.view.addSubview(cc.generateReticle(self.view, preview: preview))
        
//        cc.startSession(preview)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        self.ip.displayRawInputStream(self.view as! GPUImageView)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.ip.stopCapture()
    }
    
    // MARK: - Actions
    
    @IBAction func menuPressed(sender: AnyObject) {
        self.slideMenuController()?.openLeft()
    }
    
    @IBAction func buttonPressed(sender: AnyObject) {
        switch sender.tag {
        case 0:
            buttons[0].backgroundColor = self.getColorAtPoint(self.ip.videoCameraReference!)
        default:
            print("[ ERR ]")
        }
    }
    
    // TODO: FIX THE BYTE INCOME ITS ALWAYS BLACK
    
    func getColorAtPoint(videoCamera: GPUImageVideoCamera) -> UIColor {
        
        let centerX = (self.view.bounds.width / 2)
        let centerY = (self.view.bounds.height / 2)
        let imageSize = CGSize(width: self.view.bounds.width, height: self.view.bounds.height)
        
        let byteData = GPUImageRawDataOutput(imageSize: imageSize, resultsInBGRAFormat: false)
        videoCamera.addTarget(byteData)
        
        let rawColor = byteData.colorAtLocation(CGPoint(x:centerX, y: centerY))
        
        let red = CGFloat(rawColor.red)
        let green = CGFloat(rawColor.green)
        let blue = CGFloat(rawColor.blue)
        
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1.0)
    }
    
    func test() {
        let rawColor = GPUImageRawDataOutput()
    }

//    @IBAction func capturePressed(sender: AnyObject) {
//        var targetColor: UIColor?
//        cc.getCalibrationColor() {
//            (color: UIColor) in
//            targetColor = color
//            self.view.backgroundColor = color
//        }
//    }
}

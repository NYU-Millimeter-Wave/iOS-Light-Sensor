//
//  TestDetectionViewController.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/14/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import GPUImage

class TestDetectionViewController: UIViewController {

    @IBOutlet weak var preview: UIView?
    @IBOutlet var sliders: [UISlider]!
    
    var videoCamera:            GPUImageVideoCamera?
    var filterLume:             GPUImageLuminanceThresholdFilter?
    var filterDetect:           GPUImageSobelEdgeDetectionFilter?
    var filterClosing:          GPUImageRGBClosingFilter?
    var filterColorThreshhold:  GPUImageFilter?
    var filterColorPosition:    GPUImageFilter?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Invoke Video Camera
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
        videoCamera!.outputImageOrientation = .Portrait;
        
        // Setup closing filter
        filterClosing = GPUImageRGBClosingFilter()
        
        // Setup selective color filter
        let thresholdSensitivity: GLfloat = 0.1
        let thresholdColor: GPUVector3 = GPUVector3(one: 1, two: 1, three: 1)
        
        filterColorThreshhold = GPUImageFilter(fragmentShaderFromFile: "Threshold")
        filterColorThreshhold?.setFloat(thresholdSensitivity, forUniformName: "threshold")
        filterColorThreshhold?.setFloatVec3(thresholdColor, forUniformName: "inputColor")
        
        filterColorPosition = GPUImageFilter(fragmentShaderFromFile: "PositionColor")
        filterColorPosition?.setFloat(thresholdSensitivity, forUniformName: "threshold")
        filterColorPosition?.setFloatVec3(thresholdColor, forUniformName: "inputColor")
        
        // Setup lume filtering
        filterLume = GPUImageLuminanceThresholdFilter()
        filterLume?.threshold = 0.99
        
        // Setup edge detection
        filterDetect = GPUImageSobelEdgeDetectionFilter()
        
        // Link filters
        videoCamera?.addTarget(filterClosing)
        filterClosing?.addTarget(filterLume)
        filterLume?.addTarget(filterDetect)
        filterDetect?.addTarget(self.preview as! GPUImageView)
        
        // Begin video capture
        videoCamera?.startCameraCapture()
    }
    
    @IBAction func sliderChanged(sender: AnyObject) {
        switch sender.tag {
//        case 0:
//            testfilter.erosion = CGFloat(self.sliders[0].value)
//        case 1:
//            testfilter.green = CGFloat(self.sliders[1].value)
//        case 2:
//            testfilter = CGFloat(self.sliders[2].value)
        default:
            print("[ ERR ]")
        }
    }
}

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
    
    var imageProcessor: ImageProcessor?
    
    var videoCamera:  GPUImageVideoCamera?
    var filterLume:   GPUImageLuminanceThresholdFilter?
    var filterDetect: GPUImageSobelEdgeDetectionFilter?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        imageProcessor = ImageProcessor()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if let proc = imageProcessor {
//            proc.filterInputStream(preview.frame, preview: preview)
//        }
        
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
        videoCamera!.outputImageOrientation = .Portrait;
        
        filterLume = GPUImageLuminanceThresholdFilter()
        filterLume?.threshold = 0.99
        
        filterDetect = GPUImageSobelEdgeDetectionFilter()
//        filterDetect?.texelHeight = 0.005
//        filterDetect?.texelWidth = 0.005
        
        videoCamera?.addTarget(filterLume)
        filterLume?.addTarget(filterDetect)
        filterDetect?.addTarget(self.preview as! GPUImageView)
//        videoCamera?.addTarget(filterDetect)
//        filterDetect?.addTarget(self.preview as! GPUImageView)
        
        videoCamera?.startCameraCapture()
    }
    
    @IBAction func sliderChanged(sender: AnyObject) {
        switch sender.tag {
        case 0:
            filterLume?.threshold = CGFloat(self.sliders[0].value)
            print(self.sliders[0].value)
//        case 1:
//            filterDetect?.green = CGFloat(self.sliders[1].value)
//        case 2:
//            filterDetect?.edgeStrength = CGFloat(self.sliders[2].value)
        default:
            print("[ ERR ]")
        }
    }
}

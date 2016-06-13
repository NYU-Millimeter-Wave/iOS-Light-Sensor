//
//  ImageProcessor.swift
//  CameraTesting
//
//  Created by Cole Smith on 1/19/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import Foundation
import GPUImage

class ImageProcessor: NSObject {
    
    override init() {
        super.init()
        
    }
    
    func syncronizeTargetColor(targetColor: UIColor) {}
    
    func filterInputStream() {
        let videoCamera     : GPUImageVideoCamera = GPUImageVideoCamera(
            sessionPreset   : AVCaptureSessionPreset640x480,
            cameraPosition  : AVCaptureDevicePosition.Back)
        videoCamera.outputImageOrientation = UIInterfaceOrientation.Portrait
        
//        let customFilter: GPUImageFilter = GPUImageFilter(
        
        
    }
    
}

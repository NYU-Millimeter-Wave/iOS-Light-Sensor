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
    
    var detectionFilter: GPUImageSobelEdgeDetectionFilter!
    
    override init() {
        super.init()
        
    }
    
    func syncronizeTargetColor(targetColor: UIColor) {}
    
    func filterInputStream(frame: CGRect, preview: UIView) {
        let videoCamera     : GPUImageVideoCamera = GPUImageVideoCamera(
            sessionPreset   : AVCaptureSessionPreset640x480,
            cameraPosition  : AVCaptureDevicePosition.Back)
        videoCamera.outputImageOrientation = UIInterfaceOrientation.Portrait
        
        detectionFilter = GPUImageSobelEdgeDetectionFilter()
        
        videoCamera.addTarget(detectionFilter)
        detectionFilter.addTarget(preview as! GPUImageView)
        videoCamera.startCameraCapture()
    }
    
    func tuneFilter(texelW: CGFloat?, texelH: CGFloat?, edge: CGFloat?) {
        if let texelW = texelW { detectionFilter.texelWidth = texelW }
        if let texelH = texelH { detectionFilter.texelHeight = texelH }
        if let edge = edge { detectionFilter.edgeStrength = edge }
    }
}

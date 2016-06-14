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
    
    // MARK: - Singleton Declaration
    static let sharedProcessor = ImageProcessor()
    
    // MARK: - Class Properties
    
    var thresholdSensitivity: GLfloat?
    var targetColorVector : GPUVector3?
    var lumeThreshold: Float?
    var edgeTolerance: Float?
    
    // MARK: - Processing Filters
    
    var videoCamera:            GPUImageVideoCamera?
    var filterLume:             GPUImageLuminanceThresholdFilter?
    var filterDetect:           GPUImageSobelEdgeDetectionFilter?
    var filterClosing:          GPUImageRGBClosingFilter?
    var filterColorThreshold:  GPUImageFilter?
    var filterColorPosition:    GPUImageFilter?
    
    // MARK: - Initalizers
    
    private override init() {
        super.init()
        
        // Default Values
        thresholdSensitivity = 0.5
        targetColorVector = GPUVector3(one: 1, two: 1, three: 1)
        lumeThreshold = 0.99
        
        // Setup closing filter
        filterClosing = GPUImageRGBClosingFilter()
        
        // Setup lume filtering
        filterLume = GPUImageLuminanceThresholdFilter()
        if let lume = lumeThreshold {
            filterLume?.threshold = CGFloat(lume)
        }
        
        // Setup selective color filter
        filterColorThreshold = GPUImageFilter(fragmentShaderFromFile: "Threshold")
        if let sen = thresholdSensitivity {
            filterColorThreshold?.setFloat(sen, forUniformName: "threshold")
        }
        if let color = targetColorVector {
            filterColorThreshold?.setFloatVec3(color, forUniformName: "inputColor")
        }
        
        filterColorPosition = GPUImageFilter(fragmentShaderFromFile: "PositionColor")
        if let sen = thresholdSensitivity {
            filterColorPosition?.setFloat(sen, forUniformName: "threshold")
        }
        if let color = targetColorVector {
            filterColorPosition?.setFloatVec3(color, forUniformName: "inputColor")
        }
        
        // Setup edge detection
        filterDetect = GPUImageSobelEdgeDetectionFilter()
    }
    
    // MARK: - Filter Processing Methods
    
    /**
     
     Applies edge detection filters to an input steam and displays it on the
     given view
     
     - Parameter preview: The view to display the filtered image stream
     
     - Returns: `nil`
     
     */
    func filterInputStream(preview: GPUImageView) {
        
        // Invoke Video Camera
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
        videoCamera!.outputImageOrientation = .Portrait
        
        // Link filters
        videoCamera?.addTarget(filterClosing)
        filterClosing?.addTarget(filterLume)
        filterLume?.addTarget(filterDetect)
        filterDetect?.addTarget(preview)
        
        // Begin video capture
        videoCamera?.startCameraCapture()
    }
}

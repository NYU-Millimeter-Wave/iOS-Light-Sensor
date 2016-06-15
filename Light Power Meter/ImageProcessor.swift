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
    
    // Color Constants
    
    var red:    UIColor?
    var yellow: UIColor?
    var purple: UIColor?
    
    // Tuning Parameters
    
    var thresholdSensitivity: GLfloat? {
        didSet { loadThresholdSensitivity() }
    }
    var targetColorVector : GPUVector3? {
        didSet { loadTargetColorVector() }
    }
    var lumeThreshold: Float? {
        didSet {
            if let lume = lumeThreshold {
                filterLume?.threshold = CGFloat(lume)
            }
        }
    }
    var edgeTolerance: Float? {
        didSet {
            if let edge = edgeTolerance {
                filterDetect?.edgeStrength = CGFloat(edge)
            }
        }
    }
    var closingPixelRadius: UInt? {
        didSet {
            if let rad = closingPixelRadius {
                filterClosing = GPUImageRGBClosingFilter(radius: rad)
            }
        }
    }
    
    var videoCameraReference: GPUImageVideoCamera?
    
    // MARK: - Processing Filters
    
    private var videoCamera:            GPUImageVideoCamera?
    private var filterLume:             GPUImageLuminanceThresholdFilter?
    private var filterDetect:           GPUImageSobelEdgeDetectionFilter?
    private var filterClosing:          GPUImageRGBClosingFilter?
    private var filterColorThreshold:   GPUImageFilter?
    private var filterColorPosition:    GPUImageFilter?
    
    // MARK: - Initalizers
    
    private override init() {
        super.init()
        
        print("[ INF ] Image Processor Init")
        
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
        filterColorPosition = GPUImageFilter(fragmentShaderFromFile: "PositionColor")
        loadThresholdSensitivity()
        loadTargetColorVector()
        
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
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPresetHigh, cameraPosition: .Back)
        videoCamera?.outputImageOrientation = .Portrait
        
        // Link filters
        videoCamera?.addTarget(filterClosing)
        filterClosing?.addTarget(filterLume)
        filterLume?.addTarget(filterDetect)
        filterDetect?.addTarget(preview)
        
        self.videoCameraReference = videoCamera
        
        // Begin video capture
        videoCamera?.startCameraCapture()
    }
    
    /**
     
     Displays the unfiltered video view
     
    - Parameter preview: The view to display the unfiltered image stream
     
     - Returns: `nil`
     
     */
    func displayRawInputStream(preview: GPUImageView) {
        // Invoke Video Camera
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPresetHigh, cameraPosition: .Back)
        videoCamera?.outputImageOrientation = .Portrait
        
        videoCamera?.addTarget(preview)
        self.videoCameraReference = videoCamera
        
        // Begin video capture
        videoCamera?.startCameraCapture()
    }
    
    func getImageByteData() {
    }
    
    /**
     
     Stops capturing of video
     
     - Returns: `nil`
     
     */
    func stopCapture() {
        self.videoCameraReference?.stopCameraCapture()
    }
    
    private func loadThresholdSensitivity() {
        if let sen = thresholdSensitivity {
            filterColorThreshold?.setFloat(sen, forUniformName: "threshold")
        }
        if let sen = thresholdSensitivity {
            filterColorPosition?.setFloat(sen, forUniformName: "threshold")
        }
    }
    
    private func loadTargetColorVector() {
        if let color = targetColorVector {
            filterColorThreshold?.setFloatVec3(color, forUniformName: "inputColor")
        }
        if let color = targetColorVector {
            filterColorPosition?.setFloatVec3(color, forUniformName: "inputColor")
        }
    }
}

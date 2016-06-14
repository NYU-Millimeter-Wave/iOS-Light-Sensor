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
    
    var targetColor: UIColor?
    private var targetColorVector : GPUVector3?
    
    // MARK: - Processing Filters
    
    var videoCamera:            GPUImageVideoCamera?
    var filterLume:             GPUImageLuminanceThresholdFilter?
    var filterDetect:           GPUImageSobelEdgeDetectionFilter?
    var filterClosing:          GPUImageRGBClosingFilter?
    var filterColorThreshhold:  GPUImageFilter?
    var filterColorPosition:    GPUImageFilter?
    
    // MARK: - Initalizers
    
    private override init() {
        super.init()
        
    }
    
    // MARK: - Filter Processing Methods
    
    func syncronizeTargetColor(targetColor: UIColor) {
    }
    
    func filterInputStream(preview: UIView) {
    }
    
    func tuneFilter(closingPixelRadius: UInt?, colorSensitivity: Float?, lumeThreshold: Float?, edgeTolerance: Float?) {
        
    }
}

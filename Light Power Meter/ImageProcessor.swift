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
    
    /// Target color of red
    var red:    UIColor?
    
    /// Target color of yellow
    var yellow: UIColor?
    
    /// Target color of purple
    var purple: UIColor?
    
    // Pixel Size Constant
    
    /**
     
     The pixel size of AVCaptureSessionPresetHigh for the iPhone 6s(+)
     using the back-facing camera
     
     */
    let pixelSize = CGSizeMake(1920.0, 1080.0)
    
    // Tuning Parameters
    
    /// Sensitivity value for color detection
    var thresholdSensitivity: GLfloat? {
        didSet { loadThresholdSensitivity() }
    }
    
    /// Tarrget color vector for color deteciton
    var targetColorVector : GPUVector3? {
        didSet { loadTargetColorVector() }
    }
    
    /// Lume threshold for light intensity detection
    var lumeThreshold: Float? {
        didSet {
            if let lume = lumeThreshold {
                filterLume?.threshold = CGFloat(lume)
            }
        }
    }
    
    /// Edge tolerance for Sobel Edge Detection
    var edgeTolerance: Float? {
        didSet {
            if let edge = edgeTolerance {
                filterDetect?.edgeStrength = CGFloat(edge)
            }
        }
    }
    
    /// Radius value of Closing filter
    var closingPixelRadius: UInt? {
        didSet {
            if let rad = closingPixelRadius {
                filterClosing = GPUImageRGBClosingFilter(radius: rad)
            }
        }
    }
    
    // Video
    
    /// Captures the video stream from the back-facing camera
    var videoCamera: GPUImageVideoCamera?
    
    /// Represents the raw byte data from the camera
    var videoCameraRawDataOutput: GPUImageRawDataOutput?
    
    // MARK: - Processing Filters
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
        
        red =     UIColor(red: 1.0, green: 130 / 255.0, blue: 116 / 255.0, alpha: 1.0)
        yellow =  UIColor(red: 238 / 255.0, green: 1.0, blue: 166.0 / 255.0, alpha: 1.0)
        purple =  UIColor(red: 239 / 255.0, green: 161 / 255.0, blue: 1.0, alpha: 1.0)
        
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
        
        // Setup raw output
        videoCameraRawDataOutput = GPUImageRawDataOutput(imageSize: pixelSize, resultsInBGRAFormat: true)
        videoCamera?.addTarget(videoCameraRawDataOutput)
        
        // Link filters
        videoCamera?.addTarget(filterClosing)
        filterClosing?.addTarget(filterLume)
        filterLume?.addTarget(filterDetect)
        filterDetect?.addTarget(preview)
        
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
        
        // Setup raw output
        videoCameraRawDataOutput = GPUImageRawDataOutput(imageSize: pixelSize, resultsInBGRAFormat: true)
        
        videoCamera?.addTarget(videoCameraRawDataOutput)
        videoCamera?.addTarget(preview)
        
        // Begin video capture
        videoCamera?.startCameraCapture()
    }
    
    /**
     
     Gets the color value as `UIColor` of the pixel specified
     for the current video capture stream. Will return black if
     no color is found or the capture session is inactive
     
     - Parameter point: The point at which to get the target color
     
     - Returns: `UIColor`
     
     */
    func getColorFromPoint(point: CGPoint) -> UIColor {
        if let color = videoCameraRawDataOutput?.colorAtLocation(point) {
            let red: CGFloat = CGFloat(color.red)
            let green: CGFloat = CGFloat(color.green)
            let blue: CGFloat = CGFloat(color.blue)
            let alpha: CGFloat = CGFloat(color.alpha)
            return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha / 255.0)
        } else {
            print("Video steam not initialized, no color output")
            return UIColor.blackColor()
        }
    }
    
    /**
     
     Creates a reticle for the video preview for color selection
     
     - Parameter parentView :   The view that the preview lies within
     - Parameter preview    :   The view that displays the live video preview
     
     - Returns: `Recticle`  :   a Reticle object ready to add
     
     */
    func generateReticle(previewFrame: CGRect) ->  Reticle {
        let scale = previewFrame.width * 0.025
        let centerX = (previewFrame.width / 2)
        let centerY = (previewFrame.height / 2)
        return Reticle(origin: CGPoint(x:centerX, y: centerY), size: scale)
    }
    
    /**
     
     Stops capturing of video
     
     - Returns: `nil`
     
     */
    func stopCapture() {
        self.videoCamera?.stopCameraCapture()
    }
    
    // MARK: - Private Methods
    
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

/**
 
 Generates a small circle in the middle of the given frame
 so that the user can pin-point the target color (our light source)
 
 */
class Reticle: UIView {
    var reticleRect: CGRect!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    init(origin: CGPoint, size: CGFloat) {
        super.init(frame: CGRectMake(0.0, 0.0, size, size))
        self.center = origin
        self.backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect) {
        let reticle = UIBezierPath(ovalInRect: rect)
        UIColor.whiteColor().colorWithAlphaComponent(0.5).setFill()
        reticle.fill()
    }
}

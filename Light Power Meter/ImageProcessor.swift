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
    
    //
    // Constants
    //
    
    /// Size of capture frame in pixels
    let PIXEL_SIZE = CGSizeMake(480.0, 360.0)
    
    /// Maximum allowed distance from color
    let MAXIMUM_ALLOWED_COLOR_DISTANCE = 0.5
    
    //
    // Tunable Target Colors
    //
    // These colors are sampled during calibration and
    // represent the benchmark for power level calculation
    
    /// Target hue of red
    var red:    Double!
    
    /// Target hue of yellow
    var yellow: Double!
    
    /// Target hue of purple
    var purple: Double!
    
    //
    // Tuning Parameters
    //
    // These parameters change how the light filters
    // behave and should be adjusted per circumstance
    
    /// The allowed distance between color hues
    var colorThreshold: Double = 2.0
    
    /// The divisor for power level calculations
    var powerLevelMaximum: Double = 1000.0
    
    /// Lume threshold for light intensity detection
    var lumeThreshold: CGFloat? {
        didSet {
            if let lume = lumeThreshold {
                filterLume.threshold = lume
            }
        }
    }
    
    /// Edge tolerance for Sobel Edge Detection
    var edgeTolerance: CGFloat? {
        didSet {
            if let edge = edgeTolerance {
                filterEdgeDetect.edgeStrength = edge
            }
        }
    }
    
    //
    // Video Capture Properties
    //
    
    /// Captures the video stream from the back-facing camera
    var videoCamera: GPUImageVideoCamera?
    
    /// Represents the raw byte data from the camera
    var videoCameraRawDataOutput: GPUImageRawDataOutput?
    
    /// Represents the raw byte data from the camera (unfiltered)
    var unfilteredVideoCameraRawDataOutput: GPUImageRawDataOutput?
    
    // A reference to the current preview layer
    private var previewLayer: GPUImageView?
    
    // MARK: - Processing Filters
    
    private lazy var filterMask: GPUImageMaskFilter = GPUImageMaskFilter()
    private lazy var filterLume: GPUImageLuminanceThresholdFilter = GPUImageLuminanceThresholdFilter()
    private lazy var filterEdgeDetect: GPUImageThresholdEdgeDetectionFilter = GPUImageThresholdEdgeDetectionFilter()
    
    // MARK: - Initalizers
    
    private override init() {
        super.init()
        
        print("[ INF ] Image Processor Init")
        
        // Default Color Values
        
        // UIColor(red: 1.0, green: 130 / 255.0, blue: 116 / 255.0, alpha: 1.0)
        red = 14.0
        
        // UIColor(red: 238 / 255.0, green: 1.0, blue: 166.0 / 255.0, alpha: 1.0)
        yellow = 38.0
        
        // UIColor(red: 239 / 255.0, green: 161 / 255.0, blue: 1.0, alpha: 1.0)
        purple = 300.0
    }
    
    // MARK: - Cpature Control
    
    /**
     
     Applies lume filtering and edge detection to generate an array of points
     of hard edges in frame. Method then samples the found points to check for target colors
     and the distance between target and observed colors for power meter computation.
     
     - Parameter preview: The view to display the filtered image stream
     
     - Returns: `nil`
     
     */
    func filterInputStream(preview: GPUImageView) {
        
        // Default Filter Tweaks
        lumeThreshold = 0.7
        filterLume.threshold = CGFloat(lumeThreshold!)
        
        // Texel tuning for edge size
        filterEdgeDetect.texelHeight = 0.005
        filterEdgeDetect.texelWidth  = 0.005
        
        // Set local preview layer
        self.previewLayer = preview
        
        // Invoke Video Camera
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPresetMedium, cameraPosition: .Back)
        videoCamera?.outputImageOrientation = .Portrait
        
        // Setup raw output
        videoCameraRawDataOutput = GPUImageRawDataOutput(imageSize: PIXEL_SIZE, resultsInBGRAFormat: true)
        unfilteredVideoCameraRawDataOutput = GPUImageRawDataOutput(imageSize: PIXEL_SIZE, resultsInBGRAFormat: true)
        videoCamera?.addTarget(unfilteredVideoCameraRawDataOutput)
        
        // Lume & Edge Filtering
        videoCamera?.addTarget(filterLume)
        filterLume.addTarget(filterEdgeDetect)
        
        // Lume Masking
        videoCamera?.addTarget(filterMask)
        filterEdgeDetect.addTarget(filterMask)
        
        // Outlet Linking
        filterMask.addTarget(preview)
        filterMask.addTarget(videoCameraRawDataOutput)
        
        // Begin video capture
        print("[ CAM ] Starting Capture")
        videoCamera?.startCameraCapture()
    }
    
    
    /**
     
     Displays the unfiltered video view
     
    - Parameter preview: The view to display the unfiltered image stream
     
    - Returns: `nil`
     
     */
    func displayRawInputStream(preview: GPUImageView) {
        // Invoke Video Camera
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPresetMedium, cameraPosition: .Back)
        videoCamera?.outputImageOrientation = .Portrait
        
        // Setup raw output
        unfilteredVideoCameraRawDataOutput = GPUImageRawDataOutput(imageSize: PIXEL_SIZE, resultsInBGRAFormat: true)
        
        videoCamera?.addTarget(unfilteredVideoCameraRawDataOutput)
        videoCamera?.addTarget(preview)
        
        // Begin video capture
        print("[ CAM ] Starting Unfiltered Capture")
        videoCamera?.startCameraCapture()
    }

    /**
     
     Stops capturing of video
     
     - Returns: `nil`
     
     */
    func stopCapture() {
        print("[ CAM ] Stopping Capture")
        self.videoCamera?.stopCameraCapture()
    }
    
    /**
     
     Reloads the cpaturing operation
     
     - Returns: `nil`
     
     */
    func reloadCapture() {
        self.stopCapture()
        if let pl = previewLayer {
            self.filterInputStream(pl)
        }
    }
    
    /**
     
     Reloads the cpaturing operation
     
     - Returns: `nil`
     
     */
    func reloadUnfilteredCapture() {
        self.stopCapture()
        if let pl = previewLayer {
            self.displayRawInputStream(pl)
        }
    }
    
    // MARK: - Image Processing Methods
    
    /**
     
     Get the average hue of entire masked image
     
     - Returns: `Tuple` with average hue and hit count
     
     */
    func getAverageHue() -> (Double, Int) {
        if videoCameraRawDataOutput != nil {
            let imgWidth   = Int(self.PIXEL_SIZE.width)
            let imgHieight = Int(self.PIXEL_SIZE.height)
            var avHue = 0.0
            var hit   = 0.0
            videoCameraRawDataOutput?.lockFramebufferForReading()
            for x in 0...imgWidth {
                for y in 0...imgHieight {
                    var hue: CGFloat = 0.0
                    let color = self.getColorFromPoint(CGPointMake(CGFloat(x), CGFloat(y)))
                    color.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
                    if hue != 0 {
                        avHue += Double(hue)
                        hit += 1
                    }
                }
            }
            videoCameraRawDataOutput?.unlockFramebufferAfterReading()
            return ( ((avHue / hit) * 360), Int(hit))
        } else {
            print("[ ERR ] No capture session, cannot get hue")
            return (-1.0, -1)
        }
    }
    
    /**
     
     Gets average color a specified amount of times and
     returns the median of the result set
     
     - Parameter passes: Number of color averaging readings
     
     - Returns: `Double` The median color average in result set
     
     */
    func multipassHueAverageCalibration(passes: UInt) -> Double {
        print("[ IMG ] Calibrating Hue... ", terminator: "")
        var results: [Double] = []
        for _ in 0...passes {
            let avHue = self.getAverageHue().0
            results.append(avHue)
        }
        print("Done")
        results.sortInPlace()
        return results[results.count / 2]
    }
    
    /**
     
     Get the distance between each pixel and target hue.
     If difference is less than threshold (0-360) increment hit count
     
     - Parameter hue: The hue value for distance calculation
     - Parameter threshold: The maximum allowed distance
     
     - Returns: `Double` The ratio of matching pixels on [0,1]
     
     */
    func getPowerLevelForHue(hue: Double, threshold: Double) -> Double {
        if videoCameraRawDataOutput != nil {
            let imgWidth   = Int(self.PIXEL_SIZE.width)
            let imgHieight = Int(self.PIXEL_SIZE.height)
            var hit = 0.0
            videoCameraRawDataOutput?.lockFramebufferForReading()
            for x in 0...imgWidth {
                for y in 0...imgHieight {
                    
                    var hueSample: CGFloat = 0.0
                    let color = self.getColorFromPoint(CGPointMake(CGFloat(x), CGFloat(y)))
                    color.getHue(&hueSample, saturation: nil, brightness: nil, alpha: nil)
                    
                    if hueSample != 0 {
                        if abs(hue - Double(hueSample*360)) <= threshold {
                            hit += 1
                        }
                    }
                }
            }
            videoCameraRawDataOutput?.unlockFramebufferAfterReading()
            if hit > powerLevelMaximum {
                return 1.0
            } else {
                return hit / powerLevelMaximum
            }
        } else {
            print("[ ERR ] No capture session, cannot get power level")
            return -1.0
        }
    }

    
    // MARK: - Color Control
    
    /**
     
     Gets the color value as `UIColor` of the pixel specified
     for the current video capture stream. Will return black if
     no color is found or the capture session is inactive
     
     - Parameter point    : The point at which to get the target color
     
     - Returns: `UIColor` The color at point
     
     */
    func getColorFromPoint(point: CGPoint) -> UIColor {
        if let color = videoCameraRawDataOutput?.colorAtLocation(point) {
            let red:   CGFloat = CGFloat(color.red)
            let green: CGFloat = CGFloat(color.green)
            let blue:  CGFloat = CGFloat(color.blue)
            let alpha: CGFloat = CGFloat(color.alpha)
            return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha / 255.0)
        } else {
            print("[ ERR ] No capture session, no color output")
            return UIColor.clearColor()
        }
    }
    
    // MARK: - Mathematics
    
    /**
     
     Creates a reticle for the video preview for color selection
     
     - Parameter parentView :   The view that the preview lies within
     - Parameter preview    :   The view that displays the live video preview
     
     - Returns: `Recticle` A Reticle object ready to add
     
     */
    func generateReticle(previewFrame: CGRect) ->  Reticle {
        let scale   = previewFrame.width * 0.025
        let centerX = (previewFrame.width / 2)
        let centerY = (previewFrame.height / 2)
        return Reticle(origin: CGPoint(x:centerX, y: centerY), size: scale)
    }
}

// MARK: -

/**
 
 Generates a small circle in the middle of the given frame
 so that the user can pin-point the target color (our light source)
 
 */
class Reticle: UIView {
    var reticleRect: CGRect!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("[ FATAL ] init(coder:) has not been implemented")
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

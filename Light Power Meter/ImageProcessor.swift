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
//    let PIXEL_SIZE = CGSizeMake(480.0, 640.0)
    let PIXEL_SIZE = CGSizeMake(480.0, 360.0)
    
    /// Maximum allowed distance from color
    let MAXIMUM_ALLOWED_COLOR_DISTANCE = 0.5
    
    //
    // Power Levels
    //
    // The Power levels range from 0 - 1.0 where
    // 0 represents an average color below the minimum
    // threshold and 1.0 would represent a perfect match
    
    /// The current detection amount of red
    var powerRed:    Double = 0.0
    
    /// The current detection amount of yellow
    var powerYellow: Double = 0.0
    
    /// The current detection amount of purple
    var powerPurple: Double = 0.0
    
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
    
    /// Sensitivity value for color detection filter
    var thresholdSensitivity: GLfloat? {
        didSet { loadThresholdSensitivity() }
    }
    
    /// Tarrget color vector for color deteciton filter
    var targetColorVector : GPUVector3? {
        didSet { loadTargetColorVector() }
    }
    
    /// Lume threshold for light intensity detection
    var lumeThreshold: Float? {
        didSet {
            if let lume = lumeThreshold {
                filterLume.threshold = CGFloat(lume)
            }
        }
    }
    
    /// Edge tolerance for Sobel Edge Detection
    var edgeTolerance: Float? {
        didSet {
            if let edge = edgeTolerance {
                filterEdgeDetect.edgeStrength = CGFloat(edge)
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
    
    /// Scaling factor for Constrast filter
    var contrastFactor: Float? {
        didSet {
            if let cont = contrastFactor {
                filterContrast.contrast = CGFloat(cont)
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
    
    /// Reference to the last filter in the filter group
    var terminalFilterOfFilterGroup: GPUImageFilter?
    
    // A reference to the current preview layer
    private var previewLayer: GPUImageView?
    
    // Pointer to the array returned by corner detection algorithm
    private var interestPointsArray: UnsafeMutablePointer<GLfloat>?
    private var interestPointsArraySize: UInt?
    
    // MARK: - Processing Filters
    
    private lazy var filterLume: GPUImageLuminanceThresholdFilter = GPUImageLuminanceThresholdFilter()
    private lazy var filterMask: GPUImageMaskFilter = GPUImageMaskFilter()
    private lazy var filterEdgeDetect: GPUImageThresholdEdgeDetectionFilter = GPUImageThresholdEdgeDetectionFilter()
    private lazy var cornerDetect: GPUImageHarrisCornerDetectionFilter = GPUImageHarrisCornerDetectionFilter()
    private lazy var crosshairs: GPUImageCrosshairGenerator = GPUImageCrosshairGenerator()
    
    
    // Unused Filters
    private lazy var filterContrast:   GPUImageContrastFilter           = GPUImageContrastFilter()
    private lazy var filterClosing:    GPUImageRGBClosingFilter         = GPUImageRGBClosingFilter()
    private lazy var solidWhite:       GPUImageSolidColorGenerator      = GPUImageSolidColorGenerator()
    private lazy var filterColorPosition: GPUImageFilter = GPUImageFilter(fragmentShaderFromFile: "PositionColor")
    private lazy var chromaDetection: GPUImageChromaKeyBlendFilter     = GPUImageChromaKeyBlendFilter()
    private lazy var filterColorThreshold: GPUImageFilter = GPUImageFilter(fragmentShaderFromFile: "Threshold")
    
    // MARK: - Initalizers
    
    private override init() {
        super.init()
        
        print("[ INF ] Image Processor Init")
        
        // Default Color Values
        
        // UIColor(red: 1.0, green: 130 / 255.0, blue: 116 / 255.0, alpha: 1.0)
        red = 6.0
        
        // UIColor(red: 238 / 255.0, green: 1.0, blue: 166.0 / 255.0, alpha: 1.0)
        yellow = 71.0
        
        // UIColor(red: 239 / 255.0, green: 161 / 255.0, blue: 1.0, alpha: 1.0)
        purple = 290.0
        
        
//        targetColorVector = GPUVector3(one: 1, two: 1, three: 1)
//        solidWhite.setColorRed(1.0, green: 1.0, blue: 1.0, alpha: 1.0)
//        solidWhite.forceProcessingAtSize(self.pixelSize)
//        let comp = CGColorGetComponents(self.red.CGColor)
//        chromaDetection.setColorToReplaceRed(GLfloat(comp[0]), green: GLfloat(comp[1]), blue: GLfloat(comp[2]))
//        thresholdSensitivity = 0.1
        
//        filterContrast.contrast = CGFloat(contrastFactor!)
//        loadThresholdSensitivity()
//        loadTargetColorVector()
    }
    
    // MARK: - Filter Processing Methods
    
    /**
     
     Applies lume filtering and edge detection to generate an array of points
     of hard edges in frame. Method then samples the found points to check for target colors
     and the distance between target and observed colors for power meter computation.
     
     - Parameter preview: The view to display the filtered image stream
     
     - Returns: `nil`
     
     */
    func filterInputStream(preview: GPUImageView) {
        
        // Default Filter Tweaks
        lumeThreshold        = 0.7
        filterLume.threshold = CGFloat(lumeThreshold!)
        
        // Texel tuning for edge size
        filterEdgeDetect.texelHeight = 0.005
        filterEdgeDetect.texelWidth  = 0.005
        
//        // Crosshair options
//        crosshairs.forceProcessingAtSize(PIXEL_SIZE)
//        crosshairs.crosshairWidth = 10.0
//        
//        // Corner Detection Handler
//        cornerDetect.cornersDetectedBlock = { arrayPointer, count, timestamp in
//            if count > 0 {
//                self.interestPointsArray = arrayPointer
//                self.interestPointsArraySize = count
//                
//                var points: [GLfloat] = []
//                for i in 0...(count - 1) {
//                    
//                    // Convert point from given array to cgpoint
//                    let x = CGFloat(arrayPointer[Int(i)]) * self.PIXEL_SIZE.height
//                    let y = CGFloat(arrayPointer[Int(i+1)]) * self.PIXEL_SIZE.width
//                    let point = CGPointMake(x, y)
//                    
//                    for p in self.getNeighboringPixels(2, point: point) {
//                        let color = self.getColorFromPoint(p)
//                        var hue: CGFloat = -1
//                        color.getHue(&(hue), saturation: nil, brightness: nil, alpha: nil)
//                        if hue != 0 {
//                            
//                            points.append(GLfloat(p.x / self.PIXEL_SIZE.height))
//                            points.append(GLfloat(p.y / self.PIXEL_SIZE.width))
//                        }
//                    }
//                }
//                
//                self.crosshairs.renderCrosshairsFromArray(&points, count: UInt(points.count*2), frameTime: timestamp)
////                if let results = self.processPointsForTargetColors(arrayPointer, count: count, frameTime: timestamp) {
////                    self.powerRed    = results.red
////                    self.powerYellow = results.yellow
////                    self.powerPurple = results.purple
////                }
////                self.getAverageColorFromPoints(arrayPointer, count: count, frameTime: timestamp)
//            } else {
//                self.powerRed    = 0
//                self.powerYellow = 0
//                self.powerPurple = 0
//            }
//        }
        
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
        
        // Corner Detection
//        filterMask.addTarget(cornerDetect)
        filterMask.addTarget(preview)
        filterMask.addTarget(videoCameraRawDataOutput)
        
        // Overlay Crosshairs
//        let blend = GPUImageAlphaBlendFilter()
//        filterMask.addTarget(blend)
//        crosshairs.addTarget(blend)
//        blend.addTarget(preview)
//        blend.addTarget(videoCameraRawDataOutput)
        
        // Color Masking
        
        // Make Solid White UIImage
//        let rect = CGRectMake(0, 0, self.pixelSize.width, self.pixelSize.height)
//        UIGraphicsBeginImageContext(rect.size)
//        let context = UIGraphicsGetCurrentContext()
//        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
//        CGContextFillRect(context, rect)
//        let solidWhiteImage = GPUImagePicture(image: UIGraphicsGetImageFromCurrentImageContext())
//        UIGraphicsEndImageContext()

//        chromaDetection.thresholdSensitivity = 0.8
//        chromaDetection.smoothing = 0.1
        
        // Link in color masking
//        filterMask.addTarget(chromaDetection)
//        solidWhite.addTarget(chromaDetection)
//        chromaDetection.addTarget(preview)
        
        // Begin video capture
        videoCamera?.startCameraCapture()
    }
    
    // Get the average hue of an entire image
    // (hue value, hit Count)
    func getAverageHue() -> (Double, Int) {
        let imgWidth = Int(self.PIXEL_SIZE.width)
        let imgHieight = Int(self.PIXEL_SIZE.height)
        var avHue = 0.0
        var hit = 0.0
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
    }
    
    // Get the average hue a number of times and return the median
    func multipassHueAverageCalibration(passes: UInt) -> Double {
        var results: [Double] = []
        for _ in 0...passes {
            results.append(self.getAverageHue().0)
        }
        results.sortInPlace()
        return results[results.count / 2]
    }
    
    // Get the distance between each pixel and
    // provided hue and if difference is less than threshold (0-360)
    // add to hitCount
    func getPowerLevelForHue(hue: Double, threshold: Double) -> Int {
        let imgWidth = Int(self.PIXEL_SIZE.width)
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
                        print(abs(hue - Double(hueSample*360)))
                        hit += 1
                    }
                }
            }
        }
        videoCameraRawDataOutput?.unlockFramebufferAfterReading()
        return Int(hit)
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
        videoCameraRawDataOutput = GPUImageRawDataOutput(imageSize: PIXEL_SIZE, resultsInBGRAFormat: true)
        
        videoCamera?.addTarget(videoCameraRawDataOutput)
        videoCamera?.addTarget(preview)
        
        // Begin video capture
        videoCamera?.startCameraCapture()
    }

    /**
     
     Stops capturing of video
     
     - Returns: `nil`
     
     */
    func stopCapture() {
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
    
    // MARK: - Color Control
    
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
     
     Converts a UIColor object into a color vector
     
     - Parameter inputColor: The color to convert
     
     - Returns: `GPUVector3`
     
     */
    func convertUIColorToColorVector(inputColor: UIColor) -> GPUVector3 {
        let colorComponents = CGColorGetComponents(inputColor.CGColor)
        let rComponent = Float(colorComponents[0])
        let gComponent = Float(colorComponents[1])
        let bComponent = Float(colorComponents[2])
        
        return GPUVector3(one: rComponent, two: gComponent, three: bComponent)
    }
    
    // MARK: - Mathematics
    
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
    

    
    // MARK: - Private Methods
    
    private func loadThresholdSensitivity() {
        if let sen = thresholdSensitivity {
            filterColorThreshold.setFloat(sen, forUniformName: "threshold")
            filterColorPosition.setFloat(sen, forUniformName: "threshold")
        }
    }
    
    private func loadTargetColorVector() {
        if let color = targetColorVector {
            filterColorThreshold.setFloatVec3(color, forUniformName: "inputColor")
            filterColorPosition.setFloatVec3(color, forUniformName: "inputColor")
        }
    }
    
    // MARK: - Commented Code
    
    //
    //    // Returns Tuple of distances from each color
    //    private func getDistanceForPixel(pixel: CGPoint) -> (red: Double, yellow: Double, purple: Double)? {
    //        // Get color channels at point on unfiltered image
    //        if let color = videoCameraRawDataOutput?.colorAtLocation(pixel) {
    //            let distanceFromR = getDistanceFromColors(color, second: self.red)
    //            let distanceFromY = getDistanceFromColors(color, second: self.yellow)
    //            let distanceFromP = getDistanceFromColors(color, second: self.purple)
    //
    //            return (distanceFromR, distanceFromY, distanceFromP)
    //        } else {
    //            print("[ ERR ] Tried to get color but the raw input stream was empty")
    //            return nil
    //        }
    //    }
    
    //    // Direction:
    //    //     1
    //    //   2   3
    //    //     4
    //    // Return: Hit count of found pixels
    //    private func walk(point: CGPoint, dir: Int) -> (red: UInt, yellow: UInt, purple: UInt) {
    //        var results: (red: UInt, yellow: UInt, purple: UInt) = (0,0,0)
    //        var localizedPoint = point
    //        var i = 0
    //        while(i < 10) {
    //
    //            // Check Edge cases for each direction
    //            switch dir {
    //            case 1:
    //                if (localizedPoint.y - 1) < 0 { return results }
    //            case 2:
    //                if (localizedPoint.x - 1) < 0 { return results }
    //            case 3:
    //                if (localizedPoint.x + 1) > self.PIXEL_SIZE.width { return results }
    //            case 4:
    //                if (localizedPoint.y + 1) > self.PIXEL_SIZE.height { return results }
    //            default:
    //                print("Error in walk")
    //                return results
    //            }
    //
    //            let color = getColorFromPoint(localizedPoint)
    //            if color == UIColor.clearColor() {
    //                print("reached black point")
    //                return results
    //            }
    //            let dist = getDistanceForPixel(localizedPoint)
    //            if dist?.red < MAXIMUM_ALLOWED_COLOR_DISTANCE {
    //                results.red += 1
    //            }
    //            if dist?.yellow < MAXIMUM_ALLOWED_COLOR_DISTANCE {
    //                results.yellow += 1
    //            }
    //            if dist?.purple < MAXIMUM_ALLOWED_COLOR_DISTANCE {
    //                results.purple += 1
    //            }
    //
    //            switch dir {
    //            case 1:
    //                localizedPoint.y -= 1
    //            case 2:
    //                localizedPoint.x -= 1
    //            case 3:
    //                localizedPoint.x += 1
    //            case 4:
    //                localizedPoint.y += 1
    //            default:
    //                print("error in walk")
    //                return results
    //            }
    //            i += 1
    //        }
    //        return results
    //    }
    
    //    // Only to be used by the above function
    //    private func getDistanceFromColors(first: GPUByteColorVector, second: UIColor) -> Double {
    //
    //        // Normalize Byte Vector
    //        let normRed   = Double(first.red) / 255.0
    //        let normGreen = Double(first.green) / 255.0
    //        let normBlue  = Double(first.blue) / 255.0
    //
    //        // Convert UIColor to vector
    //        let vectorColor = convertUIColorToColorVector(second)
    //
    //        let squaredDiffR = pow((normRed   - Double(vectorColor.one)  ), 2)
    //        let squaredDiffG = pow((normGreen - Double(vectorColor.two)  ), 2)
    //        let squaredDiffB = pow((normBlue  - Double(vectorColor.three)), 2)
    //
    ////        print("Distance: \(abs(sqrt(squaredDiffR + squaredDiffG + squaredDiffB)))")
    //        return abs(sqrt(squaredDiffR + squaredDiffG + squaredDiffB))
    //    }
    //
    //    // Target Color selection: red(1) yellow(2) purple(3)
    //    func learnColor(forTargetColor: Int) -> UIColor {
    //
    //        if self.previewLayer == nil {
    //            print("[ ERR ] Cannot calibrate color without preview layer")
    //            return UIColor.blackColor()
    //        }
    //
    //        // Do a multipass color averaging of interest points
    //        var foundColors: [UIColor] = []
    //        if let array = interestPointsArray {
    //            if let size = interestPointsArraySize {
    //                for i in 0...(size - 1) {
    //                    let point = CGPointMake(CGFloat(array[Int(i)]), CGFloat(array[Int(i + 1)]))
    //                    let colorAtPoint = getColorFromPoint(point)
    //                    foundColors.append(colorAtPoint)
    //                }
    //                
    //                
    //            }
    //        }
    //        
    //        return UIColor()
    //    }

    
    //    // For every point in the array, average the hue
    //    func getAverageColorFromPoints(arrayPointer: UnsafeMutablePointer<GLfloat>, count: UInt, frameTime: CMTime) {
    //        for x in 0...(count - 1) {
    //            let y = x + 1
    //            let point = CGPointMake(CGFloat(x), CGFloat(y))
    //
    //            for p in self.getNeighboringPixels(30, point: point) {
    //                let color = self.getColorFromPoint(p)
    //                var hue: CGFloat = -1
    //                color.getHue(&(hue), saturation: nil, brightness: nil, alpha: nil)
    //                if hue != 0 {
    ////                    print("Hue: \(hue)")
    //                }
    //            }
    //        }
    //    }
    //
    //    func getNeighboringPixels(radius: UInt, point: CGPoint) -> [CGPoint] {
    //        let x = point.x
    //        let y = point.y
    //        var resultArray: [CGPoint] = []
    //
    //        if radius == 0 {
    //            print("[ ERR ] Cannot get neighboring pixels, radius cannot be 0")
    //            return []
    //        }
    //
    //        for d in 1...radius {
    //            let dist = CGFloat(d)
    //            resultArray.append(CGPointMake(x - dist, y - dist))
    //            resultArray.append(CGPointMake(x       , y - dist))
    //            resultArray.append(CGPointMake(x + dist, y - dist))
    //            resultArray.append(CGPointMake(x - dist, y       ))
    //            resultArray.append(CGPointMake(x + dist, y       ))
    //            resultArray.append(CGPointMake(x - dist, y + dist))
    //            resultArray.append(CGPointMake(x       , y + dist))
    //            resultArray.append(CGPointMake(x + dist, y + dist))
    //        }
    //
    //        return resultArray
    //    }
    
    //    /**
    //
    //     Calculates the distance in 3D RGB color space from each pixel to the three RYP target
    //     colors. Where ditance D is defined as:
    //
    //        D = [(r2 - r1)^2 + (g2 - g1)^2 + (b2 - b1)^2]^(1/2)
    //
    //     Distances below a defined threshold will be added to the target color's respective total
    //     distance and a counter will be incremented. The average distnce Dav is defined as:
    //
    //        Dav = SUM(D where D <= max_dist) / count_of_D
    //
    //     The average is then normalized (range [0,1.0] on the interval [0, max_dist], where 0 is perfect match with target color,
    //     for a power level PL defined as:
    //
    //        PL = Dav / max_dist
    //
    //     - Parameter arrayPointer: Pointer to array of normalized XY points found by edge detection
    //     - Parameter count:        Number of points in array
    //     - Parameter time:         Timestamp for polled frame
    //
    //     - Returns: Named `Tuple` containing the power level for each target color
    //
    //     */
    //    func processPointsForTargetColors(arrayPointer: UnsafeMutablePointer<GLfloat>, count: UInt, frameTime: CMTime) -> (red: Double, yellow: Double, purple: Double)? {
    //
    //        var distanceSumR: Double = 0.0
    //        var distanceSumY: Double = 0.0
    //        var distanceSumP: Double = 0.0
    //
    //        var hitCountR: UInt = 0
    //        var hitCountY: UInt = 0
    //        var hitCountP: UInt = 0
    //
    //        for i in 0...(count - 1) {
    //
    //            // Get point info
    //            let pointX = CGFloat(arrayPointer[Int(i)]) * PIXEL_SIZE.width
    //            let pointY = CGFloat(arrayPointer[Int(i + 1)]) * PIXEL_SIZE.height
    //            let denormPoint = CGPointMake(pointX, pointY)
    //
    //
    //            for i in 1...4 {
    //                let walker = walk(denormPoint, dir: i)
    //                hitCountR += walker.red
    //                hitCountY += walker.yellow
    //                hitCountP += walker.purple
    //            }
    //
    //
    ////            let hitCountUP    = walk(denormPoint, dir: 1)
    ////            let hitCountLEFT  = walk(denormPoint, dir: 2)
    ////            let hitCountRIGHT = walk(denormPoint, dir: 3)
    ////            let hitCountDOWN  = walk(denormPoint, dir: 4)
    ////            print("UP: \(hitCountUP)")
    ////            print("LEFT: \(hitCountLEFT)")
    ////            print("RIGHT: \(hitCountRIGHT)")
    ////            print("DOWN: \(hitCountDOWN)")
    //
    ////            // Get color channels at point on unfiltered image
    ////            if let dist = getDistanceForPixel(denormPoint) {
    ////                if dist.red <= MAXIMUM_ALLOWED_COLOR_DISTANCE {
    ////                    distanceSumR += dist.red
    ////                    hitCountR += 1
    ////                }
    ////                if dist.yellow <= MAXIMUM_ALLOWED_COLOR_DISTANCE {
    ////                    distanceSumY += dist.yellow
    ////                    hitCountY += 1
    ////                }
    ////                if dist.purple <= MAXIMUM_ALLOWED_COLOR_DISTANCE {
    ////                    distanceSumP += dist.purple
    ////                    hitCountP += 1
    ////                }
    ////            } else {
    ////                print("[ ERR ] Could not get distance from pixel")
    ////                return nil
    ////            }
    ////
    //        }
    //
    //        var plR: Double = 0.0
    //        var plY: Double = 0.0
    //        var plP: Double = 0.0
    //
    //        plR = Double(hitCountR * 40) / Double(self.PIXEL_SIZE.height * self.PIXEL_SIZE.width)
    //        plY = Double(hitCountY * 40) / Double(self.PIXEL_SIZE.height * self.PIXEL_SIZE.width)
    //        plP = Double(hitCountR * 40) / Double(self.PIXEL_SIZE.height * self.PIXEL_SIZE.width)
    //        print("\(plR, plY, plP)")
    //
    ////        // Calculate Power Levels (PL = Dav / MAX)
    ////        if hitCountR > 0 {
    ////            plR = (distanceSumR / Double(hitCountR)) / MAXIMUM_ALLOWED_COLOR_DISTANCE
    ////        }
    ////        if hitCountY > 0 {
    ////            plY = (distanceSumR / Double(hitCountY)) / MAXIMUM_ALLOWED_COLOR_DISTANCE
    ////        }
    ////        if hitCountP > 0 {
    ////            plP = (distanceSumP / Double(hitCountP)) / MAXIMUM_ALLOWED_COLOR_DISTANCE
    ////        }
    ////
    ////        print("Time: \(frameTime.value)")
    ////        print("Power R: \(plR) Y: \(plY) P: \(plP)")
    //        
    //        return (plR, plY, plP)
    //    }
    
    //    private func calculateCentroidFromRawPixelData() -> CGPoint {
    //        var currentXTotal: CGFloat = 0.0
    //        var currentYTotal: CGFloat = 0.0
    //        var currentPixelTotal: CGFloat = 0.0
    //
    //        let pixels = videoCameraRawDataOutput!.rawBytesForImage
    //
    //        for currentPixel:Int in 0...Int(pixelSize.width * pixelSize.height) {
    //            currentXTotal     += CGFloat( pixels[(currentPixel * 4)] ) / 255.0
    //            currentYTotal     += CGFloat( pixels[(currentPixel * 4) + 1] ) / 255.0
    //            currentPixelTotal += CGFloat( pixels[(currentPixel * 4) + 3] ) / 255.0
    //        }
    //
    //        let point = CGPointMake((1.0 - currentYTotal / currentPixelTotal), (currentXTotal / currentPixelTotal))
    //
    //        print(point.x)
    //        print(point.y)
    //        
    //        return point
    //    }
    
    
    //    /**
    //
    //     Uses the filtered stream to compare regions of interest with
    //     the target color. It calculates a delta of the real color to the target
    //     color and compares this value against a tolerance. Values below the tolerance
    //     will be comitted to the return image, which should only contain target color.
    //
    //     Runtime: ~0.30 Seconds
    //     Complexity: O(n^2)
    //
    //     - Parameter tolerance: The amount of drift between each color channel (0-255)
    //
    //     - Returns: `UIImage`
    //
    //     */
    //    func processColorDectionImage(tolerance: CGFloat, colorTarget: UIColor) -> UIImage {
    //        let maskedImage: GPUImageRawDataOutput = self.videoCameraRawDataOutput!
    //        let rawImage: GPUImageRawDataOutput = self.unfilteredVideoCameraRawDataOutput!
    //        let targetColor = self.convertUIColorToColorVector(colorTarget)
    //
    //        let imageWidth: Int = Int(pixelSize.width)
    //        let imageHeight: Int = Int(pixelSize.height)
    //
    //        let whiteTolerance: CGFloat = 1.0
    //        let colorTolerance: CGFloat = tolerance
    //
    //        let size: CGSize = CGSizeMake(pixelSize.width, pixelSize.height)
    //
    //        // Start creating UIImage
    //        UIGraphicsBeginImageContext(size)
    //
    //        // Set inital fill color to black
    //        UIColor.blackColor().setFill()
    //
    //        // Frame Lock
    //        maskedImage.lockFramebufferForReading()
    //        rawImage.lockFramebufferForReading()
    //
    //        // Interate through entire frame
    //        for h in (0...imageHeight) {
    //            for w in (0...imageWidth) {
    //
    //                // Color of masked byte array
    //                let pixelColor = self.videoCameraRawDataOutput!.colorAtLocation(CGPointMake(CGFloat(w), CGFloat(h)))
    //                let r = CGFloat(pixelColor.red)
    //                let g = CGFloat(pixelColor.green)
    //                let b = CGFloat(pixelColor.blue)
    //
    //                // Check if pixel color is white and check its actual color
    //                if r >= whiteTolerance && g >= whiteTolerance && b >= whiteTolerance {
    //
    //                    // Color of actual, unfiltered image
    //                    let rpxcolor = self.unfilteredVideoCameraRawDataOutput!.colorAtLocation(CGPointMake(CGFloat(w), CGFloat(h)))
    //                    let rr = CGFloat(rpxcolor.red)
    //                    let rg = CGFloat(rpxcolor.green)
    //                    let rb = CGFloat(rpxcolor.blue)
    //
    //                    // Calculate delta of target and actual color
    //                    let deltaR = abs(rr - CGFloat(targetColor.one))
    //                    let deltaG = abs(rg - CGFloat(targetColor.two))
    //                    let deltaB = abs(rb - CGFloat(targetColor.three))
    //
    //                    // Compare real color against target color
    //                    if deltaR <= colorTolerance && deltaG <= colorTolerance && deltaB <= colorTolerance {
    //
    //                        // Set the draw context to this color
    //                        UIColor(red: rr/255.0, green: rg/255.0, blue: rb/255.0, alpha: 1.0).setFill()
    //                        UIRectFill(CGRectMake(CGFloat(w), CGFloat(h), 1, 1))
    //                    }
    //                } else{
    //
    //                    // White region was not target color,
    //                    UIColor.blackColor().setFill()
    //                    UIRectFill(CGRectMake(CGFloat(w), CGFloat(h), 1, 1))
    //                }
    //            }
    //        }
    //
    //        // Unlock
    //        maskedImage.unlockFramebufferAfterReading()
    //        rawImage.unlockFramebufferAfterReading()
    //
    //        // Create the final image
    //        let imageFinal = UIGraphicsGetImageFromCurrentImageContext()
    //        UIGraphicsEndImageContext()
    //
    //        return imageFinal
    //    }
    //
    //    /**
    //
    //     Locks on frame and captures a filtered image and an unfiltered one.
    //     The (filtered) image is filtered by lumosity and binarized. The 3 target
    //     colors are then compared against the actual colors. A delta is calculated
    //     between the actual colors and target colors. If the delta is lower than a
    //     specified tolerance, then that target color's score increases by 1. Finally,
    //     a boolean tuple is returned (R,Y,P) specifying if that color was "found" in the
    //     image (its score was higher than a certain theshold).
    //
    //     Runtime: ~1 Second
    //     REALLY SLOW
    //
    //     - Parameter tolerance: The amount of drift between each color channel (0-255)
    //
    //     - Returns: Tuple: `(Rpresent, Ypresent, Ppresent)`
    //
    //     */
    //    func processColorDetectionAtInstant(tolerance: CGFloat) -> (Bool, Bool, Bool) {
    //
    //        let maskedImage: GPUImageRawDataOutput = self.videoCameraRawDataOutput!
    //        let rawImage: GPUImageRawDataOutput = self.unfilteredVideoCameraRawDataOutput!
    //
    //        let imageWidth: Int = Int(pixelSize.width)
    //        let imageHeight: Int = Int(pixelSize.height)
    //
    //        let whiteTolerance: CGFloat = 1.0
    //        let colorTolerance: CGFloat = tolerance
    //
    //        var matchedColorScoreR: Int  = 0                 // Number of pixels matching
    //        var matchedColorScoreY: Int  = 0                 // Number of pixels matching
    //        var matchedColorScoreP: Int  = 0                 // Number of pixels matching
    //        let matchedColorMinimum: Int = 1                 // This will need to change
    //
    //        let vectorTargetR = self.convertUIColorToColorVector(self.red!)
    //        let vectorTargetY = self.convertUIColorToColorVector(self.yellow!)
    //        let vectorTargetP = self.convertUIColorToColorVector(self.purple!)
    //
    //        // Frame Lock
    //        maskedImage.lockFramebufferForReading()
    //        rawImage.lockFramebufferForReading()
    //
    //        // Interate through entire frame
    //        for w in 0...imageWidth {
    //            for h in 0...imageHeight {
    //
    //                // Color of masked byte array
    //                let pixelColor = self.videoCameraRawDataOutput!.colorAtLocation(CGPointMake(CGFloat(w), CGFloat(h)))
    //                let r = CGFloat(pixelColor.red)
    //                let g = CGFloat(pixelColor.green)
    //                let b = CGFloat(pixelColor.blue)
    //
    //                // Check if pixel color is white and check its actual color
    //                if r >= whiteTolerance && g >= whiteTolerance && b >= whiteTolerance {
    //
    //                    // Color of actual, unfiltered image
    //                    let rpxcolor = self.unfilteredVideoCameraRawDataOutput!.colorAtLocation(CGPointMake(CGFloat(w), CGFloat(h)))
    //                    let rr = CGFloat(rpxcolor.red)
    //                    let rg = CGFloat(rpxcolor.green)
    //                    let rb = CGFloat(rpxcolor.blue)
    //
    //                    for (i, color) in [vectorTargetR, vectorTargetY, vectorTargetP].enumerate() {
    //
    //                        // Calculate delta of target and actual color
    //                        let deltaR = abs(rr - CGFloat(color.one))
    //                        let deltaG = abs(rg - CGFloat(color.two))
    //                        let deltaB = abs(rb - CGFloat(color.three))
    //
    //                        // Compare real color against target color
    //                        if deltaR <= colorTolerance && deltaG <= colorTolerance && deltaB <= colorTolerance {
    //                            switch i {
    //                            case 0:
    //                                // Found target R
    //                                matchedColorScoreR += 1
    //                            case 1:
    //                                // Found target Y
    //                                matchedColorScoreY += 1
    //                            case 2:
    //                                // Found target P
    //                                matchedColorScoreP += 1
    //                            default:
    //                                break
    //                            }
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //
    //        // Unlock
    //        maskedImage.unlockFramebufferAfterReading()
    //        rawImage.unlockFramebufferAfterReading()
    //
    //        // Color bools       R      Y      P
    //        var returnTuple = (false, false, false)
    //
    //        // Compare to minimum
    //        if matchedColorScoreR >= matchedColorMinimum {
    //            returnTuple.0 = true
    //        }
    //        if matchedColorScoreY >= matchedColorMinimum {
    //            returnTuple.1 = true
    //        }
    //        if matchedColorScoreP >= matchedColorMinimum {
    //            returnTuple.2 = true
    //        }
    //
    //        return returnTuple
    //    }
    
    //    func maskStreamByLume(preview: GPUImageView) {
    //        // Invoke Video Camera
    //        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
    //        videoCamera?.outputImageOrientation = .Portrait
    //
    //        // Setup raw output
    //        videoCameraRawDataOutput = GPUImageRawDataOutput(imageSize: pixelSize, resultsInBGRAFormat: true)
    //        unfilteredVideoCameraRawDataOutput = GPUImageRawDataOutput(imageSize: pixelSize, resultsInBGRAFormat: true)
    //        videoCamera?.addTarget(unfilteredVideoCameraRawDataOutput)
    //
    //        // Link filters
    //        videoCamera?.addTarget(filterClosing)
    //        filterClosing?.addTarget(filterLume)
    //
    //        // Uncomment to add color thresholding filter into stream
    //        // filterClosing?.addTarget(filterColorThreshold)
    //        // filterColorThreshold?.addTarget(filterLume)
    //        
    //        filterLume?.addTarget(filterContrast)
    //        filterContrast?.addTarget(preview)
    //        filterContrast?.addTarget(videoCameraRawDataOutput)
    //        
    //        self.terminalFilterOfFilterGroup = filterContrast
    //        
    //        // Begin video capture
    //        videoCamera?.startCameraCapture()
    //    }
    
    //    func takeStillImage() -> (UIImage, UIImage) {
    //        if let filter = self.terminalFilterOfFilterGroup{
    //            if let vid = self.videoCamera {
    //                filter.useNextFrameForImageCapture()
    //                vid.useNextFrameForImageCapture()
    //                
    //                let mask = filter.imageFromCurrentFramebuffer()
    //                let color = vid.imageFromCurrentFramebuffer()
    //                
    //                return (color, mask)
    //            }
    //        }
    //    }
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

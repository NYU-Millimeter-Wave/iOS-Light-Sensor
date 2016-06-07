//
//  CameraCapture.swift
//  CameraTesting
//
//  Created by Cole Smith on 1/11/16.
//  Copyright © 2016 Cole Smith - New York Univeristy. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol CameraSessionControllerDelegate {
    optional func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!)
}

class CameraCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Class Properties
    
    /// AV Session Object
    private let captureSession = AVCaptureSession()
    
    /// AV Session Queue
    var sessionQueue: dispatch_queue_t!
    
    /// AV Session Delegate
    var sessionDelegate: CameraSessionControllerDelegate?
    
    /// AV Session Preset
    private let capturePreset = AVCaptureSessionPresetMedium
    
    /// The camera device reference, presumably the back-facing camera
    private var captureDevice: AVCaptureDevice?
    
    /// A still image captured by the current session
    private var stillImageOutput: AVCaptureStillImageOutput?
    
    /// A live-video data stream captured by the current session
    private var videoDataOutput: AVCaptureVideoDataOutput?
    
    /// Have the speaker beep according to power detection
    var beaconMode: Bool = true
    
    // MARK: - Initalizers
    
    override init() {
        super.init()

        captureSession.sessionPreset = capturePreset
        sessionQueue = dispatch_queue_create("CameraSessionController Session", DISPATCH_QUEUE_SERIAL)
        stillImageOutput = AVCaptureStillImageOutput()
        videoDataOutput = AVCaptureVideoDataOutput()
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if captureDevice == nil {
            print("[ ERR ] No suitable camera device found")
        }
    }
    
    deinit {
        stopSession()
    }
    
    // MARK: - Control Methods
    
    /**
    
    Starts the capture session and mounts the capture device
    
    - Parameter currentView :   The UIView to display the camera preview
    
    - Returns: nil
    
    */
    func startSession(currentView: UIView) {
        
        let priority = DISPATCH_QUEUE_PRIORITY_HIGH
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            do {
                
                // Attempt to add the capture device as input
                try self.captureSession.addInput(AVCaptureDeviceInput(device: self.captureDevice))
                
                // Attempt to add output to capture device
                if self.captureSession.canAddOutput(self.stillImageOutput) {
                    
                    self.captureSession.addOutput(self.stillImageOutput)
                    self.captureSession.addOutput(self.videoDataOutput)
                    
                } else { print("Output(s) not added") }
                
                if self.captureSession.sessionPreset != AVCaptureSessionPresetPhoto {
                    try! self.captureDevice!.lockForConfiguration()
                    if self.captureDevice!.focusPointOfInterestSupported{
                        //Add Focus on Point
                        self.captureDevice!.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
                    }
                    if self.captureDevice!.exposurePointOfInterestSupported{
                        //Add Exposure on Point
                        self.captureDevice!.exposureMode = AVCaptureExposureMode.AutoExpose
                    }
                    self.captureDevice!.unlockForConfiguration()
                }
                
                // Create and attach the preview of the camera to the view
                let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                previewLayer!.frame = currentView.layer.bounds
                currentView.layer.addSublayer(previewLayer)
                
                // Configure the video settings
//                self.videoDataOutput!.videoSettings = NSDictionary(object: Int(kCVPixelFormatType_32BGRA), forKey:kCVPixelBufferPixelFormatTypeKey)

                self.videoDataOutput!.alwaysDiscardsLateVideoFrames = true

                self.videoDataOutput!.setSampleBufferDelegate(self, queue: self.sessionQueue)
                
                // Begin camera capture
                self.captureSession.startRunning()
                
            } catch let err as NSError {
                print("[ ERR ] An error occurred in AVCaptureSession initalization: " + err.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                // Main thread tasks here
            }
        }
    }
    
    func stopSession() {
        captureSession.stopRunning()
    }
    
    // MARK: - Capture Methods
    
    func getCalibrationColor(completion: (color: UIColor) -> Void) {
        captureImage() {
            (image: UIImage) in
            let imageAsCGImage = image.CGImage
            let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(imageAsCGImage))!
            let data = CFDataGetBytePtr(pixelData)
            
            let y: CGFloat = image.size.height / 2
            let x: CGFloat = image.size.width / 2
            
//            let pixel = Int(((CGFloat(image.size.width) * y) + x) * CGFloat(4.0))
            let pixel = Int(CGFloat((y + x) * 4.0))
            
            print("y: \(y)")
            print("x: \(x)")
            
            let r = CGFloat(data[pixel])
            let g = CGFloat(data[pixel + 1])
            let b = CGFloat(data[pixel + 2])
            let a = CGFloat(data[pixel + 3])
            let targetColor = UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a/255.0)
            
            completion(color: targetColor)
        }
    }
    
    private func captureImage(completion: (image: UIImage) -> Void) {
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput!.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                if let image = UIImage(data: imageData) {
                    completion(image: image)
                }
            }
        }
    }
    
    /**
     
     Protocol function to recieve output stream from catpure device.
     
     - Parameter captureOutput  :   AVCaptureOutput
     - Parameter sampleBuffer   :   CMSampleBuffer
     - Parameter connection     :   AVCaptureConnection
     
     - Returns: nil
     
     */
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
//        CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//        [self.delegate processNewCameraFrame:pixelBuffer];
//        let pixelBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        sessionDelegate?.cameraSessionDidOutputSampleBuffer?(sampleBuffer)
        
    }
    
    // MARK: - Utility Methods
    
    /**
    
    Starts the audio beacon that beeps relative to the detected power level
    
    - Returns: nil
    
    */
    func startBeacon() {
        
        let sound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("beep", ofType: "wav")!)
        var audioPlayer = AVAudioPlayer()
        
        audioPlayer = try! AVAudioPlayer(contentsOfURL: sound)
        audioPlayer.prepareToPlay()
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            while(self.beaconMode) {
                audioPlayer.play()
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                // Main thread tasks here
            }
        }
    }
    
    /**
     
     Creates a reticle for the video preview for color selection
     
     - Parameter parentView :   The view that the preview lies within
     - Parameter preview    :   The view that displays the live video preview
     
     - Returns: `Recticle`  :   a Reticle object ready to add
     
     */
    func generateReticle(parentView: UIView, preview: UIView) ->  Reticle {
        let scale = preview.frame.size.width * 0.05
        let centerX = (parentView.bounds.width / 2)
        let centerY = (parentView.bounds.height / 2)
        return Reticle(origin: CGPoint(x:centerX, y: centerY), size: scale)
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

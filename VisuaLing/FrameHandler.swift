//
//  FrameHandler.swift
//  AppDevelopmentWS
//
//  Created by Ilaria Poziello on 19/02/24.
//

import AVFoundation
import CoreImage
import Vision

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    private var permissionGranted   = false
    private let captureSession      = AVCaptureSession()
    private let sessionQueue        = DispatchQueue (label: "sessionQueue")
    private let context             = CIContext()
    
    var requests = [VNRequest]()
    var detectionLayer: CALayer! = nil
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            permissionGranted = true
        case .notDetermined: // The user has not yet been asked for camera access.
            requestPermission()
            
            // Combine the two other cases into the default case
        default:
            permissionGranted = false
        }
    }
    
    func requestPermission() {
        // Strong reference not a problem here but might become one in the future.
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
        }
    }
    
    func setupCaptureSession(){
        let videoOutput = AVCaptureVideoDataOutput()
        
        guard permissionGranted else { return }
        guard let videoDevice = AVCaptureDevice.default(.builtInUltraWideCamera,for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput (device: videoDevice) else { return}
        guard captureSession.canAddInput (videoDeviceInput) else { return}
        captureSession.addInput(videoDeviceInput)
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue (label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        videoOutput.connection(with:.video)?.videoOrientation = .portrait
        //videoOutput.connection(with:.video)?.videoRotationAngle = 0.0
    }
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput (_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        // All UI updates should be/ must be performed on the main queue.
        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return cgImage
    }
}



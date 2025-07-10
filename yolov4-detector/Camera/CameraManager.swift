//
//  CameraManager.swift
//  yolov4-detector
//

import Foundation
import AVFoundation
import UIKit

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer)
    func cameraManager(_ manager: CameraManager, didChangeAuthorizationStatus status: AVAuthorizationStatus)
}

class CameraManager: NSObject {
    weak var delegate: CameraManagerDelegate?
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.yolov4detector.sessionqueue")
    private let videoOutputQueue = DispatchQueue(label: "com.yolov4detector.videooutput")
    
    private var currentDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspect  // Show with black bars instead of filling
        // Lock to portrait orientation
        if let connection = layer.connection {
            connection.videoOrientation = .portrait
        }
        return layer
    }()
    
    var isRunning: Bool {
        captureSession.isRunning
    }
    
    var currentPosition: AVCaptureDevice.Position = .back
    
    var isTorchAvailable: Bool {
        currentDevice?.hasTorch ?? false
    }
    
    var isTorchOn: Bool {
        get { currentDevice?.torchMode == .on }
        set { setTorch(newValue) }
    }
    
    override init() {
        super.init()
        checkCameraAuthorization()
    }
    
    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.delegate?.cameraManager(self, didChangeAuthorizationStatus: granted ? .authorized : .denied)
                }
                if granted {
                    self.setupCaptureSession()
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.cameraManager(self, didChangeAuthorizationStatus: .denied)
            }
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        
        // Set session preset - use specific resolution for consistency
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        } else if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        // Add video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition) else {
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                videoInput = input
                currentDevice = camera
            }
        } catch {
            captureSession.commitConfiguration()
            return
        }
        
        // Configure video output
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Don't set a fixed orientation - let the system handle it based on device orientation
        if let connection = videoOutput.connection(with: .video) {
        }
        
        captureSession.commitConfiguration()
    }
    
    func startRunning() {
        sessionQueue.async { [weak self] in
            if !(self?.captureSession.isRunning ?? false) {
                self?.captureSession.startRunning()
            }
        }
    }
    
    func stopRunning() {
        sessionQueue.async { [weak self] in
            if self?.captureSession.isRunning ?? false {
                self?.captureSession.stopRunning()
            }
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.currentPosition = self.currentPosition == .back ? .front : .back
            
            self.captureSession.beginConfiguration()
            
            // Remove current input
            if let currentInput = self.videoInput {
                self.captureSession.removeInput(currentInput)
            }
            
            // Add new input
            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentPosition) else {
                self.captureSession.commitConfiguration()
                return
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.videoInput = newInput
                    self.currentDevice = newCamera
                }
            } catch {
            }
            
            // Don't set a fixed orientation - let the system handle it
            if let connection = self.videoOutput.connection(with: .video) {
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    private func setTorch(_ on: Bool) {
        guard let device = currentDevice, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        return previewLayer
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    private static var loggedOnce = false
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Log video metadata once
        if !CameraManager.loggedOnce {
            CameraManager.loggedOnce = true
            if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            }
        }
        
        delegate?.cameraManager(self, didOutput: sampleBuffer)
    }
}
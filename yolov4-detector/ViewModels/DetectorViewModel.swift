//
//  DetectorViewModel.swift
//  yolov4-detector
//

import Foundation
import SwiftUI
import AVFoundation
import Combine

class DetectorViewModel: NSObject, ObservableObject {
    @Published var detections: [Detection] = []
    @Published var stats = DetectionStats(fps: 0, inferenceTime: 0, detectionCount: 0)
    @Published var isDetecting = true
    @Published var isTorchOn = false
    @Published var confidenceThreshold: Float = 0.25
    @Published var nmsThreshold: Float = 0.45
    @Published var showSettings = false
    @Published var cameraAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var videoSize = CGSize(width: 1080, height: 1920) // Default portrait HD size
    @Published var currentModelName: String = "Loading..."
    
    private let cameraManager = CameraManager()
    private var detector = YOLOv4Detector()
    private let detectionQueue = DispatchQueue(label: "com.yolov4detector.detection", qos: .userInitiated)
    
    private var lastFrameTime = CACurrentMediaTime()
    private var frameCount = 0
    private var detectionFrameCount = 0  // Track frames actually processed
    private var fpsTimer: Timer?
    private var isProcessing = false
    
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        cameraManager.getPreviewLayer()
    }
    
    override init() {
        super.init()
        cameraManager.delegate = self
        startFPSTimer()
        updateModelName()
        
        // Listen for model changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(modelChanged),
            name: Notification.Name("ModelDidChange"),
            object: nil
        )
    }
    
    @objc private func modelChanged() {
        // Reload the detector with the new model
        detector = YOLOv4Detector()
        updateModelName()
        
    }
    
    private func updateModelName() {
        currentModelName = detector.currentModelName
    }
    
    func startCamera() {
        cameraManager.startRunning()
    }
    
    func stopCamera() {
        cameraManager.stopRunning()
    }
    
    func toggleCamera() {
        cameraManager.switchCamera()
        // Reset torch when switching cameras
        isTorchOn = false
    }
    
    func toggleTorch() {
        isTorchOn.toggle()
        cameraManager.isTorchOn = isTorchOn
    }
    
    func toggleDetection() {
        isDetecting.toggle()
        
        // Pause/resume the camera preview along with detection
        if isDetecting {
            startCamera()
        } else {
            stopCamera()
            // Clear detections when paused
            detections = []
        }
    }
    
    
    private func startFPSTimer() {
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Only update stats if detecting
            if self.isDetecting {
                let detectionFps = Double(self.detectionFrameCount)  // Use detection frame count
                self.frameCount = 0
                self.detectionFrameCount = 0  // Reset detection frame count
                
                DispatchQueue.main.async {
                    self.stats = DetectionStats(
                        fps: detectionFps,  // Show actual detection FPS
                        inferenceTime: self.detector.lastInferenceTime,
                        detectionCount: self.detections.count
                    )
                }
            } else {
                // Reset frame counts when paused
                self.frameCount = 0
                self.detectionFrameCount = 0
            }
        }
    }
    
    
    deinit {
        fpsTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

extension DetectorViewModel: CameraManagerDelegate {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        // Always count frames for accurate FPS
        frameCount += 1
        
        guard isDetecting else {
            return
        }
        
        
        // Skip if still processing previous frame
        guard !isProcessing else { return }
        
        isProcessing = true
        
        detectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Increment detection frame count
            self.detectionFrameCount += 1
            
            // Get the actual video dimensions
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let width = CVPixelBufferGetWidth(imageBuffer)
                let height = CVPixelBufferGetHeight(imageBuffer)
                
                // Always assume portrait mode - if buffer is landscape, swap dimensions
                if width > height {
                    // Image will be rotated in OpenCVWrapper, so report rotated dimensions
                    DispatchQueue.main.async {
                        self.videoSize = CGSize(width: height, height: width)
                    }
                } else {
                    // Use actual buffer dimensions
                    DispatchQueue.main.async {
                        self.videoSize = CGSize(width: width, height: height)
                    }
                }
            }
            
            let detections = self.detector.detect(
                in: sampleBuffer,
                confidenceThreshold: self.confidenceThreshold,
                nmsThreshold: self.nmsThreshold
            )
            
            DispatchQueue.main.async {
                self.detections = detections
                self.isProcessing = false
            }
        }
    }
    
    func cameraManager(_ manager: CameraManager, didChangeAuthorizationStatus status: AVAuthorizationStatus) {
        DispatchQueue.main.async {
            self.cameraAuthorizationStatus = status
        }
    }
}

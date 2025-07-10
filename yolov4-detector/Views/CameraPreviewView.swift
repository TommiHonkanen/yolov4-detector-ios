//
//  CameraPreviewView.swift
//  yolov4-detector
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Ensure proper video gravity - resizeAspect to show black bars
        previewLayer.videoGravity = .resizeAspect
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.previewLayer.frame = uiView.bounds
            CATransaction.commit()
        }
    }
}
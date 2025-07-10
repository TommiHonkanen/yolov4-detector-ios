//
//  Detection.swift
//  yolov4-detector
//

import Foundation
import CoreGraphics

struct Detection: Identifiable {
    let id = UUID()
    let classId: Int
    let className: String
    let confidence: Float
    let boundingBox: CGRect
    
    var confidencePercentage: String {
        String(format: "%.1f%%", confidence * 100)
    }
}

struct DetectionStats {
    let fps: Double
    let inferenceTime: Double
    let detectionCount: Int
}
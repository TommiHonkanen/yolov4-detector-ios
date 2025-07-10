//
//  StatsOverlayView.swift
//  yolov4-detector
//

import SwiftUI

struct StatsOverlayView: View {
    let stats: DetectionStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 16) {
                StatsItem(icon: "speedometer", value: String(format: "%.0f FPS", stats.fps))
                StatsItem(icon: "timer", value: String(format: "%.0f ms", stats.inferenceTime))
                StatsItem(icon: "eye", value: "\(stats.detectionCount)")
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
        )
    }
}

struct StatsItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
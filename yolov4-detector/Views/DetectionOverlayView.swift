//
//  DetectionOverlayView.swift
//  yolov4-detector
//

import SwiftUI

struct DetectionOverlayView: View {
    let detections: [Detection]
    let imageSize: CGSize
    
    // COCO class colors (matching Android app)
    private let classColors: [Color] = [
        .red, .green, .blue, .orange, .purple,
        .pink, .yellow, .cyan, .mint, .indigo,
        .brown, .teal, .gray, .red.opacity(0.8), .green.opacity(0.8),
        .blue.opacity(0.8), .orange.opacity(0.8), .purple.opacity(0.8),
        .pink.opacity(0.8), .yellow.opacity(0.8)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Get the actual video dimensions
                let videoWidth = imageSize.width
                let videoHeight = imageSize.height
                let videoAspectRatio = videoWidth / videoHeight
                let viewAspectRatio = size.width / size.height
                
                // Calculate scale and offsets for aspect fit
                var scale: CGFloat
                var xOffset: CGFloat = 0
                var yOffset: CGFloat = 0
                
                if videoAspectRatio > viewAspectRatio {
                    // Video is wider than view
                    scale = size.width / videoWidth
                    let scaledHeight = videoHeight * scale
                    yOffset = (size.height - scaledHeight) / 2
                } else {
                    // Video is taller than view
                    scale = size.height / videoHeight
                    let scaledWidth = videoWidth * scale
                    xOffset = (size.width - scaledWidth) / 2
                }
                
                
                for detection in detections {
                    // The coordinates now match the video dimensions
                    // No rotation needed since OpenCVWrapper handles it
                    let scaledRect = CGRect(
                        x: detection.boundingBox.minX * scale + xOffset,
                        y: detection.boundingBox.minY * scale + yOffset,
                        width: detection.boundingBox.width * scale,
                        height: detection.boundingBox.height * scale
                    )
                    
                    let color = classColors[detection.classId % classColors.count]
                    
                    // Draw bounding box
                    context.stroke(
                        Path(roundedRect: scaledRect, cornerRadius: 4),
                        with: .color(color),
                        lineWidth: 2
                    )
                    
                    // Draw label background
                    let label = "\(detection.className) \(detection.confidencePercentage)"
                    let labelSize = labelSize(for: label)
                    let labelRect = CGRect(
                        x: scaledRect.minX,
                        y: max(0, scaledRect.minY - labelSize.height - 4),
                        width: labelSize.width + 8,
                        height: labelSize.height + 4
                    )
                    
                    context.fill(
                        Path(roundedRect: labelRect, cornerRadius: 4),
                        with: .color(color.opacity(0.8))
                    )
                    
                    // Draw label text
                    context.draw(
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white),
                        at: CGPoint(x: labelRect.midX, y: labelRect.midY),
                        anchor: .center
                    )
                }
            }
        }
    }
    
    private func labelSize(for text: String) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        return size
    }
}
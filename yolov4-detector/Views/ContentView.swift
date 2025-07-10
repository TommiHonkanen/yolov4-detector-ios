//
//  ContentView.swift
//  yolov4-detector
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel = DetectorViewModel()
    @State private var showModelManager = false
    @State private var showAbout = false
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(previewLayer: viewModel.previewLayer)
                .ignoresSafeArea()
            
            // Detection overlay
            DetectionOverlayView(
                detections: viewModel.detections,
                imageSize: viewModel.videoSize
            )
            .ignoresSafeArea()
            
            // UI Controls
            VStack {
                // Top bar with stats
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        StatsOverlayView(stats: viewModel.stats)
                        // Model name display
                        HStack(spacing: 4) {
                            Image(systemName: "cube")
                                .font(.caption)
                            Text(viewModel.currentModelName)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(6)
                    }
                    Spacer()
                    // Debug info
                    if viewModel.showSettings {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Video: \(Int(viewModel.videoSize.width))×\(Int(viewModel.videoSize.height))")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                            
                            if let firstDetection = viewModel.detections.first {
                                Text("Box: \(Int(firstDetection.boundingBox.minX)),\(Int(firstDetection.boundingBox.minY)) \(Int(firstDetection.boundingBox.width))×\(Int(firstDetection.boundingBox.height))")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Settings sliders
                    if viewModel.showSettings {
                        SettingsView(
                            confidenceThreshold: $viewModel.confidenceThreshold,
                            nmsThreshold: $viewModel.nmsThreshold
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Control buttons
                    HStack(spacing: 30) {
                        // Model manager button
                        ControlButton(
                            icon: "cube",
                            isActive: false
                        ) {
                            showModelManager = true
                        }
                        
                        // Settings button
                        ControlButton(
                            icon: "slider.horizontal.3",
                            isActive: viewModel.showSettings
                        ) {
                            withAnimation(.spring()) {
                                viewModel.showSettings.toggle()
                            }
                        }
                        
                        // Main detection toggle (larger)
                        Button(action: {
                            viewModel.toggleDetection()
                        }) {
                            Image(systemName: viewModel.isDetecting ? "pause.fill" : "play.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(
                                    Circle()
                                        .fill(viewModel.isDetecting ? Color.red : Color.green)
                                )
                        }
                        
                        // Torch button
                        ControlButton(
                            icon: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill",
                            isActive: viewModel.isTorchOn
                        ) {
                            viewModel.toggleTorch()
                        }
                        
                        // Camera switch button
                        ControlButton(
                            icon: "camera.rotate",
                            isActive: false
                        ) {
                            viewModel.toggleCamera()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            // Small delay to let view settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.startCamera()
            }
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .sheet(isPresented: $showModelManager) {
            ModelManagerView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .overlay(
            // About button in top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showAbout = true }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 40, height: 40)
                            )
                    }
                }
                .padding()
                Spacer()
            }
        )
    }
}

struct ControlButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isActive ? .black : .white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isActive ? Color.white : Color.white.opacity(0.2))
                )
        }
    }
}

struct SettingsView: View {
    @Binding var confidenceThreshold: Float
    @Binding var nmsThreshold: Float
    
    var body: some View {
        VStack(spacing: 16) {
            // Confidence threshold
            VStack(alignment: .leading) {
                HStack {
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%.2f", confidenceThreshold))
                        .font(.caption.monospaced())
                        .foregroundColor(.white)
                }
                Slider(value: $confidenceThreshold, in: 0.1...0.9)
                    .accentColor(.white)
            }
            
            // NMS threshold
            VStack(alignment: .leading) {
                HStack {
                    Text("NMS")
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%.2f", nmsThreshold))
                        .font(.caption.monospaced())
                        .foregroundColor(.white)
                }
                Slider(value: $nmsThreshold, in: 0.1...0.9)
                    .accentColor(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
        )
        .padding(.horizontal)
    }
}


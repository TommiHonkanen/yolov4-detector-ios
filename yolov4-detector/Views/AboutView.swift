//
//  AboutView.swift
//  yolov4-detector
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Logo and Name
                    VStack(spacing: 16) {
                        Image("darknet_logo_blue")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 64)
                            .padding(.top, 24)
                        
                        Text("YOLOv4 Detector")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // About Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            Text("This app implements real-time object detection with the YOLOv4 (You Only Look Once) neural network using OpenCV. Use Darknet to train your own models. Import your own weights in the Model Manager.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Technologies Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Technologies")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Darknet - Open source neural network framework", systemImage: "cpu")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Label("YOLOv4 - State-of-the-art object detection model", systemImage: "eye")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Label("OpenCV - Computer vision library", systemImage: "camera.aperture")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Label("iOS AVFoundation - Modern camera API", systemImage: "video")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Learn More Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Learn More")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                LinkButton(title: "Darknet/YOLO FAQ") {
                                    openURL(URL(string: "https://www.ccoderun.ca/programming/darknet_faq/")!)
                                }
                                
                                LinkButton(title: "GitHub Repository (Darknet)") {
                                    openURL(URL(string: "https://github.com/hank-ai/darknet")!)
                                }
                                
                                LinkButton(title: "GitHub Repository (YOLOv4 Detector)") {
                                    openURL(URL(string: "https://github.com/TommiHonkanen/yolov4-detector")!)
                                }
                                
                                LinkButton(title: "OpenCV Library") {
                                    openURL(URL(string: "https://opencv.org")!)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LinkButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
            }
            .foregroundColor(.accentColor)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

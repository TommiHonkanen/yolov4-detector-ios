//
//  YOLOv4Detector.swift
//  yolov4-detector
//

import Foundation
import UIKit
import AVFoundation

class YOLOv4Detector {
    private var openCVWrapper: OpenCVWrapper?
    private(set) var currentModel: YOLOModel?
    
    var lastInferenceTime: Double {
        openCVWrapper?.lastInferenceTime ?? 0
    }
    
    var inputSize: CGSize {
        openCVWrapper?.inputSize ?? CGSize(width: 416, height: 416)
    }
    
    var lastPreprocessedImage: UIImage? {
        openCVWrapper?.lastPreprocessedImage
    }
    
    var currentModelName: String {
        currentModel?.displayName ?? "No Model"
    }
    
    init() {
        loadSelectedModel()
    }
    
    func loadSelectedModel() {
        let selectedModelId = UserDefaults.standard.string(forKey: "selectedModelId") ?? "00000000-0000-0000-0000-000000000000"
        let models = ModelStorageManager.shared.loadModels()
        
        print("Loading model with ID: \(selectedModelId)")
        print("Available models: \(models.map { "\($0.displayName) - \($0.id.uuidString)" })")
        
        // Handle legacy "yolov4-tiny-coco" ID
        let effectiveId = selectedModelId == "yolov4-tiny-coco" ? "00000000-0000-0000-0000-000000000000" : selectedModelId
        
        // Find the selected model
        if let model = models.first(where: { $0.id.uuidString == effectiveId }) {
            print("Found model: \(model.displayName)")
            loadModel(model)
        } else if let builtInModel = models.first(where: { $0.isBuiltIn }) {
            // Fallback to built-in model
            print("Falling back to built-in model")
            loadModel(builtInModel)
            // Update the stored ID to the built-in model's ID
            UserDefaults.standard.set(builtInModel.id.uuidString, forKey: "selectedModelId")
        }
    }
    
    private func loadModel(_ model: YOLOModel) {
        guard let paths = ModelStorageManager.shared.getModelPaths(for: model) else {
            print("Failed to get model paths for: \(model.displayName)")
            return
        }
        
        print("Loading model files:")
        print("  Weights: \(paths.weights)")
        print("  Config: \(paths.config)")
        print("  Names: \(paths.names)")
        
        currentModel = model
        openCVWrapper = OpenCVWrapper(
            modelPath: paths.weights,
            configPath: paths.config,
            namesPath: paths.names
        )
        
        print("Model loaded successfully: \(model.displayName)")
    }
    
    func detect(in sampleBuffer: CMSampleBuffer, confidenceThreshold: Float = 0.25, nmsThreshold: Float = 0.45) -> [Detection] {
        guard let wrapper = openCVWrapper else { return [] }
        
        let results = wrapper.detectObjects(in: sampleBuffer, 
                                          confidenceThreshold: confidenceThreshold, 
                                          nmsThreshold: nmsThreshold)
        
        return results.map { result in
            Detection(classId: Int(result.classId),
                     className: result.className,
                     confidence: result.confidence,
                     boundingBox: result.boundingBox)
        }
    }
    
    func detect(in image: UIImage, confidenceThreshold: Float = 0.25, nmsThreshold: Float = 0.45) -> [Detection] {
        guard let wrapper = openCVWrapper else { return [] }
        
        let results = wrapper.detectObjects(in: image,
                                          confidenceThreshold: confidenceThreshold,
                                          nmsThreshold: nmsThreshold)
        
        return results.map { result in
            Detection(classId: Int(result.classId),
                     className: result.className,
                     confidence: result.confidence,
                     boundingBox: result.boundingBox)
        }
    }
}
//
//  YOLOModel.swift
//  yolov4-detector
//

import Foundation

struct YOLOModel: Identifiable, Codable {
    let id: UUID
    let name: String
    let weightsFileName: String
    let configFileName: String
    let namesFileName: String
    let inputWidth: Int
    let inputHeight: Int
    let classCount: Int
    let classNames: [String]
    let dateImported: Date
    
    var displayName: String {
        name.isEmpty ? "Unnamed Model" : name
    }
    
    var inputSizeDescription: String {
        "\(inputWidth)x\(inputHeight)"
    }
    
    var isBuiltIn: Bool {
        name == "yolov4-tiny-coco"
    }
}

// Model storage manager
class ModelStorageManager {
    static let shared = ModelStorageManager()
    
    private let documentsDirectory: URL
    private let modelsDirectory: URL
    private let modelsMetadataURL: URL
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        modelsDirectory = documentsDirectory.appendingPathComponent("YOLOModels")
        modelsMetadataURL = modelsDirectory.appendingPathComponent("models.json")
        
        // Create models directory if it doesn't exist
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
    }
    
    func saveModel(_ model: YOLOModel, weightsData: Data, configData: Data, namesData: Data) throws {
        // Create model directory
        let modelDirectory = modelsDirectory.appendingPathComponent(model.id.uuidString)
        try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
        
        // Save files
        let weightsURL = modelDirectory.appendingPathComponent(model.weightsFileName)
        let configURL = modelDirectory.appendingPathComponent(model.configFileName)
        let namesURL = modelDirectory.appendingPathComponent(model.namesFileName)
        
        try weightsData.write(to: weightsURL)
        try configData.write(to: configURL)
        try namesData.write(to: namesURL)
        
        // Update metadata
        var models = loadModels()
        models.append(model)
        saveModels(models)
    }
    
    func deleteModel(_ model: YOLOModel) throws {
        guard !model.isBuiltIn else { return }
        
        // Delete model directory
        let modelDirectory = modelsDirectory.appendingPathComponent(model.id.uuidString)
        try FileManager.default.removeItem(at: modelDirectory)
        
        // Update metadata
        var models = loadModels()
        models.removeAll { $0.id == model.id }
        saveModels(models)
    }
    
    func loadModels() -> [YOLOModel] {
        // Add built-in model with a stable ID
        let builtInModel = YOLOModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, // Fixed ID for built-in model
            name: "yolov4-tiny-coco",
            weightsFileName: "yolov4-tiny.weights",
            configFileName: "yolov4-tiny.cfg",
            namesFileName: "coco.names",
            inputWidth: 416,
            inputHeight: 416,
            classCount: 80,
            classNames: loadBuiltInClassNames(),
            dateImported: Date(timeIntervalSince1970: 0)
        )
        
        var models = [builtInModel]
        
        // Load custom models
        guard let data = try? Data(contentsOf: modelsMetadataURL),
              let customModels = try? JSONDecoder().decode([YOLOModel].self, from: data) else {
            return models
        }
        
        models.append(contentsOf: customModels)
        return models
    }
    
    private func saveModels(_ models: [YOLOModel]) {
        // Filter out built-in model before saving
        let customModels = models.filter { !$0.isBuiltIn }
        guard let data = try? JSONEncoder().encode(customModels) else { return }
        try? data.write(to: modelsMetadataURL)
    }
    
    private func loadBuiltInClassNames() -> [String] {
        guard let path = Bundle.main.path(forResource: "coco", ofType: "names", inDirectory: "yolov4-tiny-coco"),
              let content = try? String(contentsOfFile: path) else {
            return []
        }
        return content.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
    
    func getModelPaths(for model: YOLOModel) -> (weights: String, config: String, names: String)? {
        if model.isBuiltIn {
            guard let weightsPath = Bundle.main.path(forResource: "yolov4-tiny", ofType: "weights", inDirectory: "yolov4-tiny-coco"),
                  let configPath = Bundle.main.path(forResource: "yolov4-tiny", ofType: "cfg", inDirectory: "yolov4-tiny-coco"),
                  let namesPath = Bundle.main.path(forResource: "coco", ofType: "names", inDirectory: "yolov4-tiny-coco") else {
                return nil
            }
            return (weightsPath, configPath, namesPath)
        } else {
            let modelDirectory = modelsDirectory.appendingPathComponent(model.id.uuidString)
            let weightsPath = modelDirectory.appendingPathComponent(model.weightsFileName).path
            let configPath = modelDirectory.appendingPathComponent(model.configFileName).path
            let namesPath = modelDirectory.appendingPathComponent(model.namesFileName).path
            return (weightsPath, configPath, namesPath)
        }
    }
}
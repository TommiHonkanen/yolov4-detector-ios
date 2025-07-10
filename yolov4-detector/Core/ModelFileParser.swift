//
//  ModelFileParser.swift
//  yolov4-detector
//

import Foundation

class ModelFileParser {
    
    // Parse .cfg file to extract network dimensions
    static func parseConfigFile(data: Data) -> (width: Int, height: Int)? {
        guard let content = String(data: data, encoding: .utf8) else { return nil }
        
        let lines = content.components(separatedBy: .newlines)
        var width: Int?
        var height: Int?
        var inNetSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check if we're entering the [net] section
            if trimmedLine == "[net]" || trimmedLine == "[net]" {
                inNetSection = true
                continue
            }
            
            // Check if we're leaving the [net] section
            if trimmedLine.hasPrefix("[") && trimmedLine != "[net]" {
                inNetSection = false
            }
            
            // Parse width and height in the [net] section
            if inNetSection {
                if trimmedLine.hasPrefix("width=") {
                    width = Int(trimmedLine.replacingOccurrences(of: "width=", with: "").trimmingCharacters(in: .whitespaces))
                } else if trimmedLine.hasPrefix("height=") {
                    height = Int(trimmedLine.replacingOccurrences(of: "height=", with: "").trimmingCharacters(in: .whitespaces))
                }
            }
            
            // Exit early if we found both values
            if let w = width, let h = height {
                return (w, h)
            }
        }
        
        return nil
    }
    
    // Parse .names file to extract class names
    static func parseNamesFile(data: Data) -> [String] {
        guard let content = String(data: data, encoding: .utf8) else { return [] }
        
        return content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    // Validate YOLO model files
    static func validateModelFiles(weightsData: Data, configData: Data, namesData: Data) -> (isValid: Bool, error: String?) {
        // Check file sizes
        if weightsData.count < 1000 {
            return (false, "Weights file appears to be too small")
        }
        
        if configData.count < 100 {
            return (false, "Config file appears to be too small")
        }
        
        if namesData.count < 10 {
            return (false, "Names file appears to be too small")
        }
        
        // Try to parse config file
        guard let dimensions = parseConfigFile(data: configData) else {
            return (false, "Failed to parse network dimensions from config file")
        }
        
        // Validate dimensions
        if dimensions.width < 32 || dimensions.height < 32 || dimensions.width > 2048 || dimensions.height > 2048 {
            return (false, "Invalid network dimensions: \(dimensions.width)x\(dimensions.height)")
        }
        
        // Parse class names
        let classNames = parseNamesFile(data: namesData)
        if classNames.isEmpty {
            return (false, "No class names found in names file")
        }
        
        return (true, nil)
    }
}
//
//  ModelImportView.swift
//  yolov4-detector
//

import SwiftUI
import UniformTypeIdentifiers

struct ModelImportView: View {
    @Environment(\.dismiss) var dismiss
    let onImport: (YOLOModel) -> Void
    
    @State private var modelName = ""
    @State private var weightsFileURL: URL?
    @State private var configFileURL: URL?
    @State private var namesFileURL: URL?
    @State private var showingFilePicker = false
    @State private var activeFileType: FileType?
    @State private var isImporting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum FileType {
        case weights, config, names
    }
    
    var isValid: Bool {
        !modelName.isEmpty && weightsFileURL != nil && configFileURL != nil && namesFileURL != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Model Name")) {
                    TextField("Enter model name", text: $modelName)
                }
                
                Section(header: Text("Model Files")) {
                    FileRow(
                        title: "Weights File (.weights)",
                        fileName: weightsFileURL?.lastPathComponent,
                        action: {
                            activeFileType = .weights
                            showingFilePicker = true
                        }
                    )
                    
                    FileRow(
                        title: "Config File (.cfg)",
                        fileName: configFileURL?.lastPathComponent,
                        action: {
                            activeFileType = .config
                            showingFilePicker = true
                        }
                    )
                    
                    FileRow(
                        title: "Names File (.names)",
                        fileName: namesFileURL?.lastPathComponent,
                        action: {
                            activeFileType = .names
                            showingFilePicker = true
                        }
                    )
                }
                
                Section {
                    Text("Select all three files from your Downloads folder to import a new YOLO model.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Import Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        importModel()
                    }
                    .disabled(!isValid || isImporting)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: allowedContentTypes,
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isImporting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Importing...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        }
    }
    
    private var allowedContentTypes: [UTType] {
        // Use more permissive content types that iOS recognizes
        switch activeFileType {
        case .weights:
            // Allow any data file for weights
            return [.data, .item]
        case .config:
            // Allow text-based files for config
            return [.plainText, .text, .item, .data]
        case .names:
            // Allow text-based files for names
            return [.plainText, .text, .item, .data]
        case .none:
            return []
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Validate file extension
            let expectedExtension: String
            switch activeFileType {
            case .weights:
                expectedExtension = "weights"
            case .config:
                expectedExtension = "cfg"
            case .names:
                expectedExtension = "names"
            case .none:
                return
            }
            
            if url.pathExtension.lowercased() != expectedExtension {
                errorMessage = "Please select a .\(expectedExtension) file"
                showingError = true
                return
            }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access file. Please ensure it's in the Downloads folder."
                showingError = true
                return
            }
            
            // Store the URL for later use
            switch activeFileType {
            case .weights:
                weightsFileURL = url
            case .config:
                configFileURL = url
            case .names:
                namesFileURL = url
            case .none:
                break
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func importModel() {
        guard let weightsURL = weightsFileURL,
              let configURL = configFileURL,
              let namesURL = namesFileURL else { return }
        
        isImporting = true
        
        Task {
            do {
                // Ensure we have access to all files
                let weightsAccess = weightsURL.startAccessingSecurityScopedResource()
                let configAccess = configURL.startAccessingSecurityScopedResource()
                let namesAccess = namesURL.startAccessingSecurityScopedResource()
                
                defer {
                    if weightsAccess { weightsURL.stopAccessingSecurityScopedResource() }
                    if configAccess { configURL.stopAccessingSecurityScopedResource() }
                    if namesAccess { namesURL.stopAccessingSecurityScopedResource() }
                }
                
                // Read file data
                let weightsData = try Data(contentsOf: weightsURL)
                let configData = try Data(contentsOf: configURL)
                let namesData = try Data(contentsOf: namesURL)
                
                // Validate files
                let validation = ModelFileParser.validateModelFiles(
                    weightsData: weightsData,
                    configData: configData,
                    namesData: namesData
                )
                
                if !validation.isValid {
                    await MainActor.run {
                        errorMessage = validation.error ?? "Invalid model files"
                        showingError = true
                        isImporting = false
                    }
                    return
                }
                
                // Parse files
                guard let dimensions = ModelFileParser.parseConfigFile(data: configData) else {
                    await MainActor.run {
                        errorMessage = "Failed to parse config file"
                        showingError = true
                        isImporting = false
                    }
                    return
                }
                
                let classNames = ModelFileParser.parseNamesFile(data: namesData)
                
                // Create model with a new UUID
                let model = YOLOModel(
                    id: UUID(),
                    name: modelName,
                    weightsFileName: weightsURL.lastPathComponent,
                    configFileName: configURL.lastPathComponent,
                    namesFileName: namesURL.lastPathComponent,
                    inputWidth: dimensions.width,
                    inputHeight: dimensions.height,
                    classCount: classNames.count,
                    classNames: classNames,
                    dateImported: Date()
                )
                
                // Save model
                try ModelStorageManager.shared.saveModel(
                    model,
                    weightsData: weightsData,
                    configData: configData,
                    namesData: namesData
                )
                
                await MainActor.run {
                    onImport(model)
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Import failed: \(error.localizedDescription)"
                    showingError = true
                    isImporting = false
                }
            }
        }
    }
}

struct FileRow: View {
    let title: String
    let fileName: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .foregroundColor(.primary)
                    if let fileName = fileName {
                        Text(fileName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: fileName != nil ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundColor(fileName != nil ? .green : .accentColor)
            }
        }
    }
}
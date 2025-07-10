//
//  ModelManagerView.swift
//  yolov4-detector
//

import SwiftUI
import UniformTypeIdentifiers

struct ModelManagerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var models: [YOLOModel] = []
    @State private var showingImporter = false
    @State private var showingDeleteAlert = false
    @State private var modelToDelete: YOLOModel?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedModel: YOLOModel?
    @AppStorage("selectedModelId") private var selectedModelId: String = "00000000-0000-0000-0000-000000000000"
    
    var body: some View {
        NavigationView {
            List {
                ForEach(models) { model in
                    ModelRow(
                        model: model,
                        isSelected: isModelSelected(model),
                        onSelect: {
                            selectModel(model)
                        },
                        onDelete: model.isBuiltIn ? nil : {
                            modelToDelete = model
                            showingDeleteAlert = true
                        }
                    )
                }
            }
            .navigationTitle("Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingImporter = true }) {
                        Label("Import Model", systemImage: "plus.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadModels()
            }
            .sheet(isPresented: $showingImporter) {
                ModelImportView { newModel in
                    models.append(newModel)
                    selectModel(newModel)
                }
            }
            .alert("Delete Model", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let model = modelToDelete {
                        deleteModel(model)
                    }
                }
            } message: {
                Text("Are you sure you want to delete '\(modelToDelete?.displayName ?? "")'? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadModels() {
        models = ModelStorageManager.shared.loadModels()
    }
    
    private func isModelSelected(_ model: YOLOModel) -> Bool {
        if model.isBuiltIn {
            return selectedModelId == "yolov4-tiny-coco" || selectedModelId == model.id.uuidString
        } else {
            return selectedModelId == model.id.uuidString
        }
    }
    
    private func selectModel(_ model: YOLOModel) {
        selectedModelId = model.id.uuidString
        selectedModel = model
        
        // Post a specific notification for model change
        NotificationCenter.default.post(name: Notification.Name("ModelDidChange"), object: nil)
    }
    
    private func deleteModel(_ model: YOLOModel) {
        do {
            try ModelStorageManager.shared.deleteModel(model)
            models.removeAll { $0.id == model.id }
            // If deleted model was selected, switch to built-in
            if selectedModelId == model.id.uuidString {
                if let builtInModel = models.first(where: { $0.isBuiltIn }) {
                    selectedModelId = builtInModel.id.uuidString
                }
            }
        } catch {
            errorMessage = "Failed to delete model: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct ModelRow: View {
    let model: YOLOModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: (() -> Void)?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.displayName)
                        .font(.headline)
                    if model.isBuiltIn {
                        Text("Built-in")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 16) {
                    Label(model.inputSizeDescription, systemImage: "viewfinder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(model.classCount) classes", systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !model.isBuiltIn {
                    Text("Imported \(model.dateImported.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
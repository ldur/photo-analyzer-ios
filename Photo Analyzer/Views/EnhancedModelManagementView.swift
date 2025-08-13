import SwiftUI

struct EnhancedModelManagementView: View {
    @StateObject private var modelDownloader = ModelDownloader()
    @StateObject private var yoloDownloader = YOLOModelDownloader()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)
                    
                    Text("Professional AI Models")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Download and manage advanced object detection models")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.appSecondary)
                
                // Tab Selector
                Picker("Model Type", selection: $selectedTab) {
                    Text("General Models").tag(0)
                    Text("YOLO Models").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.appSecondary)
                
                // Content based on selected tab
                if selectedTab == 0 {
                    GeneralModelsView(modelDownloader: modelDownloader)
                } else {
                    YOLOModelsView(yoloDownloader: yoloDownloader)
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct GeneralModelsView: View {
    @ObservedObject var modelDownloader: ModelDownloader
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(modelDownloader.availableModels, id: \.name) { model in
                    GeneralModelCard(model: model) {
                        downloadModel(model.name)
                    }
                }
            }
            .padding()
            
            // Training Guidelines
            VStack(spacing: 16) {
                Text("Custom Model Training")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ModelTrainingHelper.getTrainingGuidelines(), id: \.self) { guideline in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(guideline)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding()
                .background(Color.appSecondary)
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private func downloadModel(_ modelName: String) {
        modelDownloader.downloadModel(modelName) { success in
            if success {
                print("Successfully downloaded \(modelName)")
            } else {
                print("Failed to download \(modelName)")
            }
        }
    }
}

struct YOLOModelsView: View {
    @ObservedObject var yoloDownloader: YOLOModelDownloader
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(yoloDownloader.availableModels, id: \.name) { model in
                    YOLOModelCard(model: model) {
                        if !model.isDownloaded {
                            downloadModel(model.name)
                        } else if !model.isConverted {
                            convertModel(model.name)
                        }
                    }
                }
            }
            .padding()
            
            // Conversion Instructions
            VStack(spacing: 16) {
                Text("Model Conversion Instructions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ModelConversionHelper.getConversionInstructions(), id: \.self) { instruction in
                        HStack(alignment: .top) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.cyan)
                                .font(.caption)
                            
                            Text(instruction)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding()
                .background(Color.appSecondary)
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private func downloadModel(_ modelName: String) {
        yoloDownloader.downloadModel(modelName) { success in
            if success {
                print("Successfully downloaded \(modelName)")
            } else {
                print("Failed to download \(modelName)")
            }
        }
    }
    
    private func convertModel(_ modelName: String) {
        yoloDownloader.convertModel(modelName) { success in
            if success {
                print("Successfully converted \(modelName)")
            } else {
                print("Failed to convert \(modelName)")
            }
        }
    }
}

struct GeneralModelCard: View {
    let model: ModelDownloader.MLModelInfo
    let onDownload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(model.size)
                        .font(.caption)
                        .foregroundColor(.cyan)
                    
                    if model.isDownloaded {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else {
                        Button(action: onDownload) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.cyan)
                                .font(.title3)
                        }
                    }
                }
            }
            
            if model.isDownloaded {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Model ready for use")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.appSecondary)
        .cornerRadius(12)
    }
}

struct YOLOModelCard: View {
    let model: YOLOModelDownloader.YOLOModelInfo
    let onAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(model.size)
                        .font(.caption)
                        .foregroundColor(.cyan)
                    
                    if model.isConverted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else if model.isDownloaded {
                        Button(action: onAction) {
                            Image(systemName: "gear.circle")
                                .foregroundColor(.orange)
                                .font(.title3)
                        }
                    } else {
                        Button(action: onAction) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.cyan)
                                .font(.title3)
                        }
                    }
                }
            }
            
            // Model stats
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accuracy")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(model.accuracy)
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Speed")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(model.speed)
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            // Status
            if model.isConverted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Ready for professional detection")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } else if model.isDownloaded {
                HStack {
                    Image(systemName: "gear.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Downloaded - needs conversion")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } else {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.cyan)
                        .font(.caption)
                    
                    Text("Click to download")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
            }
        }
        .padding()
        .background(Color.appSecondary)
        .cornerRadius(12)
    }
}

#Preview {
    EnhancedModelManagementView()
}

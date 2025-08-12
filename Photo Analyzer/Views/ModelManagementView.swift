import SwiftUI

struct ModelManagementView: View {
    @StateObject private var modelDownloader = ModelDownloader()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)
                    
                    Text("AI Model Management")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Download and manage object detection models for better analysis")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.appSecondary)
                
                // Model List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(modelDownloader.availableModels, id: \.name) { model in
                            ModelCard(model: model) {
                                downloadModel(model.name)
                            }
                        }
                    }
                    .padding()
                }
                
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

struct ModelCard: View {
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

#Preview {
    ModelManagementView()
}

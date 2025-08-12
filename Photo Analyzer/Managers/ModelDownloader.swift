import Foundation
import CoreML

// MARK: - Model Downloader
class ModelDownloader: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var availableModels: [MLModelInfo] = []
    
    // Pre-trained model URLs (you can replace these with your own models)
    private let modelURLs: [String: String] = [
        "YOLOv3": "https://developer.apple.com/machine-learning/models/text/YOLOv3.mlmodel",
        "ResNet50": "https://developer.apple.com/machine-learning/models/image/ResNet50.mlmodel",
        "MobileNetV2": "https://developer.apple.com/machine-learning/models/image/MobileNetV2.mlmodel"
    ]
    
    struct MLModelInfo {
        let name: String
        let description: String
        let size: String
        let url: String
        let isDownloaded: Bool
    }
    
    init() {
        loadAvailableModels()
    }
    
    private func loadAvailableModels() {
        availableModels = [
            MLModelInfo(
                name: "YOLOv3",
                description: "Object detection model for detecting 80+ object categories",
                size: "~250MB",
                url: modelURLs["YOLOv3"] ?? "",
                isDownloaded: isModelDownloaded("YOLOv3")
            ),
            MLModelInfo(
                name: "ResNet50",
                description: "Image classification model for 1000+ categories",
                size: "~100MB",
                url: modelURLs["ResNet50"] ?? "",
                isDownloaded: isModelDownloaded("ResNet50")
            ),
            MLModelInfo(
                name: "MobileNetV2",
                description: "Lightweight image classification model",
                size: "~15MB",
                url: modelURLs["MobileNetV2"] ?? "",
                isDownloaded: isModelDownloaded("MobileNetV2")
            )
        ]
    }
    
    func downloadModel(_ modelName: String, completion: @escaping (Bool) -> Void) {
        guard let urlString = modelURLs[modelName],
              let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        DispatchQueue.main.async {
            self.isDownloading = true
            self.downloadProgress = 0.0
        }
        
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            DispatchQueue.main.async {
                self.isDownloading = false
                
                if let error = error {
                    print("Download failed: \(error)")
                    completion(false)
                    return
                }
                
                guard let localURL = localURL else {
                    completion(false)
                    return
                }
                
                // Move to app's documents directory
                if self.saveModelToDocuments(localURL: localURL, modelName: modelName) {
                    self.loadAvailableModels() // Refresh the list
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
        
        // Monitor download progress
        task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                self.downloadProgress = progress.fractionCompleted
            }
        }
        
        task.resume()
    }
    
    private func saveModelToDocuments(localURL: URL, modelName: String) -> Bool {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let destinationURL = documentsPath.appendingPathComponent("\(modelName).mlmodel")
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: localURL, to: destinationURL)
            return true
        } catch {
            print("Failed to save model: \(error)")
            return false
        }
    }
    
    private func isModelDownloaded(_ modelName: String) -> Bool {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let modelURL = documentsPath.appendingPathComponent("\(modelName).mlmodel")
        return FileManager.default.fileExists(atPath: modelURL.path)
    }
    
    func getModelURL(_ modelName: String) -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let modelURL = documentsPath.appendingPathComponent("\(modelName).mlmodel")
        return FileManager.default.fileExists(atPath: modelURL.path) ? modelURL : nil
    }
}

// MARK: - Custom Model Training Helper
class ModelTrainingHelper {
    
    // This would help you create custom models for your specific use case
    static func createCustomObjectDetectionModel() {
        // This is a placeholder for custom model creation
        // You would typically use Create ML or Core ML Tools here
        
        print("To create a custom model for detecting computers, doors, parcels:")
        print("1. Use Create ML app on macOS")
        print("2. Collect training images of your target objects")
        print("3. Label the images with bounding boxes")
        print("4. Train the model")
        print("5. Export as .mlmodel file")
        print("6. Add to your Xcode project")
    }
    
    static func getTrainingGuidelines() -> [String] {
        return [
            "Collect at least 100 images per object category",
            "Include various angles, lighting conditions, and backgrounds",
            "Use consistent labeling (bounding boxes for object detection)",
            "Split data: 70% training, 15% validation, 15% testing",
            "Consider data augmentation for better generalization",
            "Test on real-world scenarios similar to your use case"
        ]
    }
}

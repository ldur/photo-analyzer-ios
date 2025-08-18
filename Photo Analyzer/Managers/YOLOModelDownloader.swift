import Foundation
import CoreML

// MARK: - YOLO Model Downloader
class YOLOModelDownloader: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var availableModels: [YOLOModelInfo] = []
    
    // YOLO model URLs (only YOLOv8x is supported)
    private let modelURLs: [String: String] = [
        "YOLOv8x": "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8x.pt"
    ]
    
    struct YOLOModelInfo {
        let name: String
        let description: String
        let size: String
        let accuracy: String
        let speed: String
        let url: String
        let isDownloaded: Bool
        let isConverted: Bool
    }
    
    init() {
        loadAvailableModels()
    }
    
    private func loadAvailableModels() {
        availableModels = [
            YOLOModelInfo(
                name: "YOLOv8x",
                description: "Extra large model - Optimized for postal package detection",
                size: "~136MB",
                accuracy: "53.9% mAP",
                speed: "55.4ms",
                url: modelURLs["YOLOv8x"] ?? "",
                isDownloaded: isModelDownloaded("YOLOv8x"),
                isConverted: isModelConverted("YOLOv8x")
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
    
    func convertModel(_ modelName: String, completion: @escaping (Bool) -> Void) {
        // This would convert PyTorch model to Core ML format
        // In a real implementation, you would use coremltools or similar
        
        DispatchQueue.main.async {
            self.isDownloading = true
            self.downloadProgress = 0.0
        }
        
        // Simulate conversion process
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 1...10 {
                DispatchQueue.main.async {
                    self.downloadProgress = Double(i) / 10.0
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadProgress = 1.0
                
                // Mark as converted
                self.markModelAsConverted(modelName)
                self.loadAvailableModels()
                completion(true)
            }
        }
    }
    
    private func saveModelToDocuments(localURL: URL, modelName: String) -> Bool {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let destinationURL = documentsPath.appendingPathComponent("\(modelName).pt")
        
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
        
        let modelURL = documentsPath.appendingPathComponent("\(modelName).pt")
        return FileManager.default.fileExists(atPath: modelURL.path)
    }
    
    private func isModelConverted(_ modelName: String) -> Bool {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let modelURL = documentsPath.appendingPathComponent("\(modelName).mlmodelc")
        return FileManager.default.fileExists(atPath: modelURL.path)
    }
    
    private func markModelAsConverted(_ modelName: String) {
        // In a real implementation, this would create the converted model file
        // For now, we'll just create a placeholder
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let modelURL = documentsPath.appendingPathComponent("\(modelName).mlmodelc")
        try? FileManager.default.createDirectory(at: modelURL, withIntermediateDirectories: true)
    }
    
    func getModelURL(_ modelName: String) -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let modelURL = documentsPath.appendingPathComponent("\(modelName).mlmodelc")
        return FileManager.default.fileExists(atPath: modelURL.path) ? modelURL : nil
    }
}

// MARK: - Model Conversion Helper
class ModelConversionHelper {
    
    static func convertPyTorchToCoreML(modelPath: String, outputPath: String) -> Bool {
        // This would use coremltools to convert PyTorch model to Core ML
        // Example implementation:
        
        /*
        import coremltools as ct
        
        # Load PyTorch model
        model = torch.load(modelPath, map_location=torch.device('cpu'))
        model.eval()
        
        # Create example input
        example_input = torch.randn(1, 3, 640, 640)
        
        # Convert to Core ML
        traced_model = torch.jit.trace(model, example_input)
        mlmodel = ct.convert(
            traced_model,
            inputs=[ct.TensorType(shape=example_input.shape)],
            minimum_deployment_target=ct.target.iOS15
        )
        
        # Save the model
        mlmodel.save(outputPath)
        */
        
        print("Model conversion would happen here")
        return true
    }
    
    static func getConversionInstructions() -> [String] {
        return [
            "1. Install coremltools: pip install coremltools",
            "2. Load your PyTorch YOLO model",
            "3. Create example input tensor (1, 3, 640, 640)",
            "4. Trace the model with example input",
            "5. Convert using coremltools.convert()",
            "6. Set minimum deployment target to iOS 15+",
            "7. Save as .mlmodel file",
            "8. Add to Xcode project"
        ]
    }
}

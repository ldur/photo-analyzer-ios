import SwiftUI
import CoreML
import Vision
import CoreImage
import Foundation

// MARK: - Extensions
extension CGRect {
    var area: CGFloat {
        return width * height
    }
}

// MARK: - Simplified Object Detector
class SimplifiedObjectDetector: ObservableObject {
    @Published var isDetecting = false
    @Published var detectionProgress: Double = 0.0
    
    // Core ML Models
    private var objectDetectionModel: VNCoreMLModel?
    
    // Vision Framework Requests
    private let objectDetectionRequest = VNDetectRectanglesRequest()
    private let textRecognitionRequest = VNRecognizeTextRequest()
    
    init() {
        setupModels()
        configureRequests()
    }
    
    private func setupModels() {
        // Clean corrupted models first
        cleanCorruptedModels()
        
        print("🔍 Setting up YOLOv8x model...")
        
        // Debug: Show what's actually in the bundle
        if let bundlePath = Bundle.main.resourcePath {
            print("📦 Bundle path: \(bundlePath)")
            do {
                let bundleContents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                let mlFiles = bundleContents.filter { $0.contains("ml") || $0.contains("yolo") }
                print("📦 ML files in bundle: \(mlFiles)")
            } catch {
                print("❌ Error reading bundle contents: \(error)")
            }
        }
        
        // Load only YOLOv8x model
        print("🔍 Looking for model: YOLOv8x")
        if let modelURL = getModelURL(for: "YOLOv8x") {
            do {
                let model = try MLModel(contentsOf: modelURL)
                let coreMLModel = try VNCoreMLModel(for: model)
                
                objectDetectionModel = coreMLModel
                print("✅ Loaded YOLOv8x model from \(modelURL)")
            } catch {
                print("❌ Failed to load YOLOv8x: \(error)")
            }
        } else {
            print("❌ YOLOv8x model not found")
        }
        
        print("🔍 Setup complete. YOLOv8x model: \(objectDetectionModel != nil ? "✅" : "❌")")
    }
    
    private func configureRequests() {
        // Configure image classification
        // Note: usesCPUOnly is deprecated, Vision framework handles optimization automatically
        
        // Configure object detection
        objectDetectionRequest.minimumAspectRatio = 0.1
        objectDetectionRequest.maximumAspectRatio = 10.0
        objectDetectionRequest.minimumSize = 0.01
        objectDetectionRequest.maximumObservations = 20
        
        // Configure text recognition
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
    }
    
    func detectObjects(in image: UIImage, completion: @escaping ([DetectedObject]) -> Void) {
        DispatchQueue.main.async {
            self.isDetecting = true
            self.detectionProgress = 0.0
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var allDetections: [DetectedObject] = []
                
                guard let cgImage = image.cgImage else {
                    DispatchQueue.main.async {
                        self.isDetecting = false
                        completion([])
                    }
                    return
                }
                
                // Step 1: Image Classification (25%)
                DispatchQueue.main.async {
                    self.detectionProgress = 0.25
                }
                
                let classificationResults = try self.performImageClassification(cgImage: cgImage)
                allDetections.append(contentsOf: classificationResults)
                
                // Step 2: Object Detection (50%)
                DispatchQueue.main.async {
                    self.detectionProgress = 0.50
                }
                
                let objectResults = try self.performObjectDetection(cgImage: cgImage)
                allDetections.append(contentsOf: objectResults)
                
                // Step 3: Text Recognition (75%)
                DispatchQueue.main.async {
                    self.detectionProgress = 0.75
                }
                
                let textResults = try self.performTextRecognition(cgImage: cgImage)
                allDetections.append(contentsOf: textResults)
                
                // Step 4: Post-processing (100%)
                DispatchQueue.main.async {
                    self.detectionProgress = 1.0
                }
                
                let finalResults = self.postProcessDetections(allDetections)
                
                DispatchQueue.main.async {
                    self.isDetecting = false
                    completion(finalResults)
                }
                
            } catch {
                print("Detection failed: \(error)")
                DispatchQueue.main.async {
                    self.isDetecting = false
                    completion([])
                }
            }
        }
    }
    
    private func performImageClassification(cgImage: CGImage) throws -> [DetectedObject] {
        var detections: [DetectedObject] = []
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Use Core ML model if available, otherwise use Vision framework
        if let model = objectDetectionModel {
            let request = VNCoreMLRequest(model: model) { request, error in
                if let results = request.results as? [VNClassificationObservation] {
                    // Show ALL results, not just first 5
                    for observation in results {
                        if observation.confidence > 0.1 { // Lower threshold to show more results
                            detections.append(DetectedObject(
                                identifier: observation.identifier,
                                confidence: Double(observation.confidence),
                                boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                                localizedName: observation.identifier.capitalized
                            ))
                        }
                    }
                }
            }
            try handler.perform([request])
        } else {
            // Fallback to basic object detection using Vision framework
            try handler.perform([objectDetectionRequest])
            
            if let results = objectDetectionRequest.results as? [VNRectangleObservation] {
                for observation in results {
                    if observation.confidence > 0.1 {
                        detections.append(DetectedObject(
                            identifier: "rectangle",
                            confidence: Double(observation.confidence),
                            boundingBox: observation.boundingBox,
                            localizedName: "Rectangle"
                        ))
                    }
                }
            }
        }
        
        return detections
    }
    
    private func performObjectDetection(cgImage: CGImage) throws -> [DetectedObject] {
        var detections: [DetectedObject] = []
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Use Core ML model if available, otherwise use Vision framework
        if let model = objectDetectionModel {
            // Check if this is a YOLOv8x model by checking available models
            let availableModelsList = getAvailableModels()
            print("🔍 Object Detection - Available models: \(availableModelsList)")
            
            if availableModelsList.contains("YOLOv8x") {
                // Handle YOLOv8x model specifically
                print("🎯 Using YOLOv8x model for object detection")
                detections = try performYOLOv8Detection(cgImage: cgImage, model: model)
            } else {
                // Handle other Core ML models (like Apple's built-in object detection models)
                let request = VNCoreMLRequest(model: model) { request, error in
                    if let results = request.results as? [VNRecognizedObjectObservation] {
                        for observation in results {
                            if observation.confidence > 0.1 {
                                detections.append(DetectedObject(
                                    identifier: observation.labels.first?.identifier ?? "object",
                                    confidence: Double(observation.confidence),
                                    boundingBox: observation.boundingBox,
                                    localizedName: observation.labels.first?.identifier.capitalized ?? "Object"
                                ))
                            }
                        }
                    }
                }
                try handler.perform([request])
            }
        } else {
            // Fallback to Vision framework rectangle detection
            print("⚠️ No object detection model available, using Vision framework rectangle detection")
            try handler.perform([objectDetectionRequest])
            
            if let results = objectDetectionRequest.results as? [VNRectangleObservation] {
                print("🔍 Found \(results.count) rectangles using Vision framework")
                for observation in results {
                    detections.append(DetectedObject(
                        identifier: "rectangle",
                        confidence: Double(observation.confidence),
                        boundingBox: observation.boundingBox,
                        localizedName: "Rectangle"
                    ))
                }
            }
        }
        
        return detections
    }
    
    // MARK: - YOLOv8 Specific Processing
    
    /// YOLO v8 COCO dataset class names (80 classes)
    private let yoloClassNames = [
        "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat",
        "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat",
        "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack",
        "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball",
        "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
        "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
        "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake",
        "chair", "couch", "potted plant", "bed", "dining table", "toilet", "tv", "laptop",
        "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
        "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
    ]
    
    private func performYOLOv8Detection(cgImage: CGImage, model: VNCoreMLModel) throws -> [DetectedObject] {
        var detections: [DetectedObject] = []
        
        print("🎯 Starting YOLOv8 detection...")
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ YOLOv8 prediction error: \(error)")
                return
            }
            
            print("✅ YOLOv8 prediction completed")
            
            // YOLOv8 outputs raw predictions that need post-processing
            if let results = request.results as? [VNCoreMLFeatureValueObservation] {
                print("🔍 Processing \(results.count) YOLOv8 output tensors")
                
                // Debug each output tensor
                for (index, result) in results.enumerated() {
                    print("🔍 Result \(index): featureName=\(result.featureName ?? "unknown")")
                    if let multiArray = result.featureValue.multiArrayValue {
                        print("🔍 Result \(index) shape: \(multiArray.shape), dataType: \(multiArray.dataType)")
                        // Show first few values
                        let count = min(10, multiArray.count)
                        for i in 0..<count {
                            let value = multiArray[i].doubleValue
                            print("🔍 Result \(index) value[\(i)]: \(value)")
                        }
                    }
                }
                
                detections = self.parseYOLOv8Outputs(results)
                print("🎯 YOLOv8 detected \(detections.count) objects")
            } else {
                print("⚠️ YOLOv8 results are not VNCoreMLFeatureValueObservation")
                print("🔍 Actual result types: \(request.results?.map { type(of: $0) } ?? [])")
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        return detections
    }
    
    private func parseYOLOv8Outputs(_ results: [VNCoreMLFeatureValueObservation]) -> [DetectedObject] {
        var detections: [DetectedObject] = []
        
        // YOLOv8 typically outputs a tensor with shape [1, 84, 8400] or similar
        // where 84 = 4 (bbox coords) + 80 (class probabilities)
        // and 8400 = number of predictions
        
        for result in results {
            if let multiArray = result.featureValue.multiArrayValue {
                detections.append(contentsOf: parseYOLOTensor(multiArray))
            }
        }
        
        // Apply Non-Maximum Suppression to remove duplicate detections
        detections = applyNMS(detections)
        
        return detections.filter { $0.confidence > 0.25 } // Higher threshold for YOLO
    }
    
    private func parseYOLOTensor(_ multiArray: MLMultiArray) -> [DetectedObject] {
        var detections: [DetectedObject] = []
        
        // YOLOv8 output format: [batch, 84, 8400]
        // 84 = 4 bbox coords + 80 class scores
        let shape = multiArray.shape.map { $0.intValue }
        
        print("🔍 YOLO tensor shape: \(shape)")
        print("🔍 YOLO tensor dataType: \(multiArray.dataType)")
        print("🔍 YOLO tensor strides: \(multiArray.strides)")
        
        guard shape.count >= 2 else {
            print("⚠️ Unexpected YOLO tensor shape: \(shape)")
            return detections
        }
        
        let numClasses = 80
        // CORRECTED: YOLOv8 format is [batch, anchors, features] = [1, 8400, 84]
        let numPredictions = shape.count >= 3 ? shape[1] : shape[0]  // anchors = 8400
        
        print("🔍 Processing \(min(numPredictions, 100)) predictions...")
        
        for i in 0..<min(numPredictions, 100) { // Limit to first 100 predictions for performance
            // CORRECTED: Extract bbox coordinates using transposed format [batch, anchor, feature]
            let centerX = multiArray[[0, i, 0] as [NSNumber]].doubleValue
            let centerY = multiArray[[0, i, 1] as [NSNumber]].doubleValue
            let width = multiArray[[0, i, 2] as [NSNumber]].doubleValue
            let height = multiArray[[0, i, 3] as [NSNumber]].doubleValue
            
            // Debug: Show corrected tensor values for first prediction
            if i == 0 {
                print("🔍 CORRECTED tensor values for prediction 0:")
                print("  - [0,0,0] (centerX): \(centerX)")
                print("  - [0,0,1] (centerY): \(centerY)")
                print("  - [0,0,2] (width): \(width)")
                print("  - [0,0,3] (height): \(height)")
                print("  - [0,0,4] (class 0): \(multiArray[[0, 0, 4] as [NSNumber]].doubleValue)")
                print("  - [0,0,44] (banana): \(multiArray[[0, 0, 44] as [NSNumber]].doubleValue)")
                print("  - [0,0,83] (class 79): \(multiArray[[0, 0, 83] as [NSNumber]].doubleValue)")
            }
            
            // Find class with highest confidence
            var maxConfidence: Double = 0
            var bestClassIndex = 0
            
            for classIndex in 0..<numClasses {
                // CORRECTED: Use transposed format [batch, anchor, feature]
                let confidence = multiArray[[0, i, 4 + classIndex] as [NSNumber]].doubleValue
                if confidence > maxConfidence {
                    maxConfidence = confidence
                    bestClassIndex = classIndex
                }
            }
            
            // Debug the first few predictions
            if i < 5 {
                print("🔍 Prediction \(i): bbox=(\(centerX), \(centerY), \(width), \(height)), maxConf=\(maxConfidence), class=\(bestClassIndex)")
            }
            
            // Apply sigmoid to confidence scores (YOLO often outputs logits)
            maxConfidence = 1.0 / (1.0 + exp(-maxConfidence))
            
            // Debug the first few predictions with sigmoid applied
            if i < 5 {
                print("🔍 Prediction \(i) after sigmoid: maxConf=\(maxConfidence)")
            }
            
            // Use higher confidence threshold now that we have real values!
            if maxConfidence > 0.5 {
                // Convert YOLO bbox format to Vision framework format
                let x = centerX - width / 2
                let y = centerY - height / 2
                let boundingBox = CGRect(x: x, y: y, width: width, height: height)
                
                let className = bestClassIndex < yoloClassNames.count ? yoloClassNames[bestClassIndex] : "object"
                
                detections.append(DetectedObject(
                    identifier: className,
                    confidence: maxConfidence,
                    boundingBox: boundingBox,
                    localizedName: className.capitalized
                ))
            }
        }
        
        print("🔍 Found \(detections.count) detections above confidence threshold 0.5")
        return detections
    }
    
    private func applyNMS(_ detections: [DetectedObject], threshold: Double = 0.5) -> [DetectedObject] {
        // Simple Non-Maximum Suppression
        var result: [DetectedObject] = []
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        
        for detection in sortedDetections {
            let shouldAdd = !result.contains { existing in
                // Calculate IoU (Intersection over Union)
                let intersection = detection.boundingBox.intersection(existing.boundingBox)
                let union = detection.boundingBox.union(existing.boundingBox)
                let iou = intersection.area / union.area
                
                return iou > threshold && detection.identifier == existing.identifier
            }
            
            if shouldAdd {
                result.append(detection)
            }
        }
        
        return result
    }
    
    private func performTextRecognition(cgImage: CGImage) throws -> [DetectedObject] {
        var detections: [DetectedObject] = []
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([textRecognitionRequest])
        
        if let results = textRecognitionRequest.results as? [VNRecognizedTextObservation] {
            for observation in results.prefix(5) {
                if let topCandidate = observation.topCandidates(1).first {
                    detections.append(DetectedObject(
                        identifier: "text",
                        confidence: Double(topCandidate.confidence),
                        boundingBox: observation.boundingBox,
                        localizedName: "Text: \(topCandidate.string)"
                    ))
                }
            }
        }
        
        return detections
    }
    
    private func postProcessDetections(_ detections: [DetectedObject]) -> [DetectedObject] {
        // Remove duplicates and keep highest confidence
        let uniqueDetections = Dictionary(grouping: detections) { $0.identifier }
            .compactMap { _, objects in
                objects.max { $0.confidence < $1.confidence }
            }
        
        // Sort by confidence and filter low-confidence detections
        return uniqueDetections
            .filter { $0.confidence > 0.2 }
            .sorted { $0.confidence > $1.confidence }
    }
    
    private func getModelURL(for modelName: String) -> URL? {
        // Check for different Core ML formats
        let extensions = ["mlmodelc", "mlpackage", "mlmodel"]
        
        // Handle YOLOv8x special case - it might be named "yolov8x 2" in the file system
        let modelVariants = modelName == "YOLOv8x" ? ["yolov8x 2", modelName, "yolov8x", "YOLOv8x 2"] : [modelName]
        
        for variant in modelVariants {
            for ext in extensions {
                // Check if model exists in app bundle
                print("🔍 Checking bundle for: \(variant).\(ext)")
                if let bundleURL = Bundle.main.url(forResource: variant, withExtension: ext) {
                    print("✅ Found model: \(variant).\(ext) in bundle at: \(bundleURL)")
                    return bundleURL
                } else {
                    print("❌ Not found in bundle: \(variant).\(ext)")
                }
                
                // Check if model exists in documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                let modelURL = documentsPath?.appendingPathComponent("\(variant).\(ext)")
                
                print("🔍 Checking documents for: \(variant).\(ext) at: \(modelURL?.path ?? "nil")")
                if let url = modelURL, FileManager.default.fileExists(atPath: url.path) {
                    print("✅ Found model: \(variant).\(ext) in documents")
                    return url
                } else {
                    print("❌ Not found in documents: \(variant).\(ext)")
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Public Methods
    
    func getAvailableModels() -> [String] {
        var availableModels: [String] = []
        let modelNames = ["YOLOv8x"]
        
        for modelName in modelNames {
            if getModelURL(for: modelName) != nil {
                availableModels.append(modelName)
            }
        }
        
        return availableModels
    }
    
    func getDetectionStatus() -> String {
        let models = getAvailableModels()
        if models.isEmpty {
            return "No ML models available. Using basic Vision framework only."
        } else {
            return "Using models: \(models.joined(separator: ", "))"
        }
    }
    
    // MARK: - Model Management
    
    private func cleanCorruptedModels() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let modelExtensions = ["mlmodel", "mlmodelc", "mlpackage"]
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            
            for item in contents {
                let itemName = item.lastPathComponent
                
                // Check if it's a model file
                if modelExtensions.contains(where: { itemName.hasSuffix($0) }) {
                    print("🧹 Cleaning potentially corrupted model: \(itemName)")
                    try FileManager.default.removeItem(at: item)
                    print("✅ Removed: \(itemName)")
                }
            }
        } catch {
            print("❌ Error cleaning models: \(error)")
        }
    }
}

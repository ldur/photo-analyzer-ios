import SwiftUI
import Vision
import CoreML
import CoreImage

// MARK: - Advanced Object Detection
class AdvancedObjectDetector: ObservableObject {
    @Published var isDetecting = false
    @Published var detectionProgress: Double = 0.0
    
    // Core ML Models
    private var objectDetectionModel: VNCoreMLModel?
    private var classificationModel: VNCoreMLModel?
    
    // Vision Requests
    private let rectangleDetectionRequest = VNDetectRectanglesRequest()
    private let documentDetectionRequest = VNDetectDocumentSegmentationRequest()
    private let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
    
    init() {
        setupModels()
        setupRequests()
    }
    
    private func setupModels() {
        // Try to load YOLO or similar object detection model
        if let modelURL = Bundle.main.url(forResource: "YOLOv3", withExtension: "mlmodelc") {
            do {
                let model = try MLModel(contentsOf: modelURL)
                objectDetectionModel = try VNCoreMLModel(for: model)
            } catch {
                print("Failed to load YOLOv3 model: \(error)")
            }
        }
        
        // Try to load ResNet or similar classification model
        if let modelURL = Bundle.main.url(forResource: "ResNet50", withExtension: "mlmodelc") {
            do {
                let model = try MLModel(contentsOf: modelURL)
                classificationModel = try VNCoreMLModel(for: model)
            } catch {
                print("Failed to load ResNet50 model: \(error)")
            }
        }
    }
    
    private func setupRequests() {
        // Configure rectangle detection for better object detection
        rectangleDetectionRequest.minimumAspectRatio = 0.1
        rectangleDetectionRequest.maximumAspectRatio = 10.0
        rectangleDetectionRequest.minimumSize = 0.01
        rectangleDetectionRequest.maximumObservations = 20
        rectangleDetectionRequest.quadratureTolerance = 20
        rectangleDetectionRequest.minimumConfidence = 0.5
        
        // Configure document detection for parcel detection
        documentDetectionRequest.revision = VNDetectDocumentSegmentationRequestRevision1
        
        // Configure saliency detection for attention-based analysis
        saliencyRequest.revision = VNGenerateAttentionBasedSaliencyImageRequestRevision1
    }
    
    func detectObjects(in image: UIImage, completion: @escaping ([DetectedObject]) -> Void) {
        DispatchQueue.main.async {
            self.isDetecting = true
            self.detectionProgress = 0.0
        }
        
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                self.isDetecting = false
                completion([])
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var allDetectedObjects: [DetectedObject] = []
            
            do {
                // Step 1: Basic rectangle detection
                DispatchQueue.main.async {
                    self.detectionProgress = 0.2
                }
                
                let rectangleObjects = try self.detectRectangles(in: cgImage)
                allDetectedObjects.append(contentsOf: rectangleObjects)
                
                // Step 2: Document segmentation
                DispatchQueue.main.async {
                    self.detectionProgress = 0.4
                }
                
                let documentObjects = try self.detectDocuments(in: cgImage)
                allDetectedObjects.append(contentsOf: documentObjects)
                
                // Step 3: Saliency-based detection
                DispatchQueue.main.async {
                    self.detectionProgress = 0.6
                }
                
                let saliencyObjects = try self.detectSalientObjects(in: cgImage)
                allDetectedObjects.append(contentsOf: saliencyObjects)
                
                // Step 4: Core ML object detection
                DispatchQueue.main.async {
                    self.detectionProgress = 0.8
                }
                
                let coreMLObjects = try self.detectWithCoreML(in: cgImage)
                allDetectedObjects.append(contentsOf: coreMLObjects)
                
                // Step 5: Post-process and classify objects
                DispatchQueue.main.async {
                    self.detectionProgress = 0.9
                }
                
                let classifiedObjects = self.classifyAndFilterObjects(allDetectedObjects, in: image)
                
                DispatchQueue.main.async {
                    self.isDetecting = false
                    self.detectionProgress = 1.0
                    completion(classifiedObjects)
                }
                
            } catch {
                print("Advanced object detection failed: \(error)")
                DispatchQueue.main.async {
                    self.isDetecting = false
                    completion([])
                }
            }
        }
    }
    
    private func detectRectangles(in cgImage: CGImage) throws -> [DetectedObject] {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([rectangleDetectionRequest])
        
        guard let results = rectangleDetectionRequest.results as? [VNRectangleObservation] else {
            return []
        }
        
        return results.compactMap { observation in
            let aspectRatio = observation.boundingBox.width / observation.boundingBox.height
            let area = observation.boundingBox.width * observation.boundingBox.height
            
            // Enhanced classification based on geometric properties
            let objectType = self.classifyRectangle(
                aspectRatio: aspectRatio,
                area: area,
                confidence: Double(observation.confidence)
            )
            
            return DetectedObject(
                identifier: objectType.identifier,
                confidence: Double(observation.confidence),
                boundingBox: observation.boundingBox,
                localizedName: objectType.localizedName
            )
        }
    }
    
    private func detectDocuments(in cgImage: CGImage) throws -> [DetectedObject] {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([documentDetectionRequest])
        
        guard let results = documentDetectionRequest.results as? [VNRectangleObservation] else {
            return []
        }
        
        return results.map { observation in
            DetectedObject(
                identifier: "document",
                confidence: Double(observation.confidence),
                boundingBox: observation.boundingBox,
                localizedName: "Document"
            )
        }
    }
    
    private func detectSalientObjects(in cgImage: CGImage) throws -> [DetectedObject] {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([saliencyRequest])
        
        guard let results = saliencyRequest.results as? [VNSaliencyImageObservation] else {
            return []
        }
        
        var salientObjects: [DetectedObject] = []
        
        for observation in results {
            if let salientRegions = observation.salientObjects {
                for region in salientRegions {
                    let object = DetectedObject(
                        identifier: "salient_object",
                        confidence: Double(region.confidence),
                        boundingBox: region.boundingBox,
                        localizedName: "Salient Object"
                    )
                    salientObjects.append(object)
                }
            }
        }
        
        return salientObjects
    }
    
    private func detectWithCoreML(in cgImage: CGImage) throws -> [DetectedObject] {
        guard let model = objectDetectionModel else {
            return []
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            // This will be handled in the completion
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return []
        }
        
        return results.compactMap { observation in
            guard let topLabel = observation.labels.first else { return nil }
            
            return DetectedObject(
                identifier: topLabel.identifier,
                confidence: Double(topLabel.confidence),
                boundingBox: observation.boundingBox,
                localizedName: topLabel.identifier
            )
        }
    }
    
    private func classifyRectangle(aspectRatio: CGFloat, area: CGFloat, confidence: Double) -> (identifier: String, localizedName: String) {
        // Computer screen detection
        if aspectRatio >= 1.2 && aspectRatio <= 2.0 && area > 0.1 && confidence > 0.7 {
            return ("computer_screen", "Computer Screen")
        }
        
        // Door detection
        if aspectRatio >= 0.3 && aspectRatio <= 0.7 && area > 0.15 && confidence > 0.6 {
            return ("door", "Door")
        }
        
        // Parcel detection
        if aspectRatio >= 0.8 && aspectRatio <= 1.5 && area > 0.05 && area < 0.3 && confidence > 0.5 {
            return ("parcel", "Parcel")
        }
        
        // Window detection
        if aspectRatio >= 0.8 && aspectRatio <= 1.2 && area > 0.08 && confidence > 0.6 {
            return ("window", "Window")
        }
        
        // Table detection
        if aspectRatio >= 1.5 && aspectRatio <= 3.0 && area > 0.2 && confidence > 0.5 {
            return ("table", "Table")
        }
        
        // Generic rectangle
        return ("rectangle", "Rectangle")
    }
    
    private func classifyAndFilterObjects(_ objects: [DetectedObject], in image: UIImage) -> [DetectedObject] {
        var classifiedObjects: [DetectedObject] = []
        var processedAreas: Set<String> = []
        
        for object in objects {
            // Create a unique identifier for the bounding box area to avoid duplicates
            let areaKey = "\(Int(object.boundingBox.origin.x * 100))_\(Int(object.boundingBox.origin.y * 100))_\(Int(object.boundingBox.width * 100))_\(Int(object.boundingBox.height * 100))"
            
            if !processedAreas.contains(areaKey) {
                processedAreas.insert(areaKey)
                
                // Apply additional classification based on image context
                let enhancedObject = enhanceObjectClassification(object, in: image)
                classifiedObjects.append(enhancedObject)
            }
        }
        
        // Sort by confidence and remove low-confidence detections
        return classifiedObjects
            .filter { $0.confidence > 0.3 }
            .sorted { $0.confidence > $1.confidence }
    }
    
    private func enhanceObjectClassification(_ object: DetectedObject, in image: UIImage) -> DetectedObject {
        // Apply additional context-based classification
        
        // Check for specific object patterns
        if object.identifier == "rectangle" {
            // Analyze the bounding box position and size for better classification
            let centerX = object.boundingBox.origin.x + object.boundingBox.width / 2
            let centerY = object.boundingBox.origin.y + object.boundingBox.height / 2
            
            // If object is in the center and large, it might be a computer screen
            if centerX > 0.3 && centerX < 0.7 && centerY > 0.3 && centerY < 0.7 && object.boundingBox.width * object.boundingBox.height > 0.1 {
                return DetectedObject(
                    identifier: "computer_screen",
                    confidence: object.confidence * 1.2, // Boost confidence
                    boundingBox: object.boundingBox,
                    localizedName: "Computer Screen"
                )
            }
            
            // If object is at the bottom and wide, it might be a table
            if centerY > 0.6 && object.boundingBox.width > object.boundingBox.height * 1.5 {
                return DetectedObject(
                    identifier: "table",
                    confidence: object.confidence * 1.1,
                    boundingBox: object.boundingBox,
                    localizedName: "Table"
                )
            }
        }
        
        return object
    }
}

// MARK: - Object Detection Categories
enum ObjectCategory: String, CaseIterable {
    case computer = "computer"
    case door = "door"
    case parcel = "parcel"
    case window = "window"
    case table = "table"
    case chair = "chair"
    case screen = "screen"
    case document = "document"
    
    var displayName: String {
        switch self {
        case .computer: return "Computer"
        case .door: return "Door"
        case .parcel: return "Parcel"
        case .window: return "Window"
        case .table: return "Table"
        case .chair: return "Chair"
        case .screen: return "Screen"
        case .document: return "Document"
        }
    }
    
    var confidenceThreshold: Double {
        switch self {
        case .computer: return 0.7
        case .door: return 0.6
        case .parcel: return 0.5
        case .window: return 0.6
        case .table: return 0.5
        case .chair: return 0.5
        case .screen: return 0.7
        case .document: return 0.6
        }
    }
}

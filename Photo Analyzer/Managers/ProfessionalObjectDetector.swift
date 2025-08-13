import SwiftUI
import CoreML
import Vision
import CoreImage
import Accelerate

// MARK: - Professional Object Detector
class ProfessionalObjectDetector: ObservableObject {
    @Published var isDetecting = false
    @Published var detectionProgress: Double = 0.0
    
    // Core ML Models
    private var yoloModel: VNCoreMLModel?
    private var classificationModel: VNCoreMLModel?
    
    // Detection configuration
    private let confidenceThreshold: Float = 0.5
    private let nmsThreshold: Float = 0.4
    private let maxDetections = 20
    
    // Enhanced labels with custom categories
    private let enhancedLabels = [
        // Computers and Electronics
        "computer", "laptop", "desktop", "monitor", "screen", "tv", "television", "keyboard", "mouse", "remote",
        
        // Doors and Entrances
        "door", "entrance", "exit", "gateway", "gate", "entrance door", "exit door", "front door", "back door",
        
        // Parcels and Packages
        "parcel", "package", "box", "delivery", "mail", "shipping box", "cardboard box", "package box",
        
        // Windows and Glass
        "window", "glass", "pane", "window pane", "glass window", "sliding door", "glass door",
        
        // Furniture
        "table", "desk", "surface", "chair", "seat", "furniture", "couch", "sofa", "bed", "dining table",
        
        // General Objects
        "person", "car", "bicycle", "motorcycle", "bus", "truck", "boat", "airplane", "train",
        "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog",
        "backpack", "umbrella", "handbag", "suitcase", "bottle", "cup", "fork", "knife", "spoon",
        "bowl", "banana", "apple", "sandwich", "orange", "pizza", "donut", "cake", "toilet",
        "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase"
    ]
    
    init() {
        setupModels()
    }
    
    private func setupModels() {
        // Try to load YOLO model
        if let modelURL = Bundle.main.url(forResource: "YOLOv8n", withExtension: "mlmodelc") {
            do {
                let model = try MLModel(contentsOf: modelURL)
                yoloModel = try VNCoreMLModel(for: model)
                print("YOLO model loaded successfully")
            } catch {
                print("Failed to load YOLO model: \(error)")
            }
        }
        
        // Try to load classification model
        if let modelURL = Bundle.main.url(forResource: "ResNet50", withExtension: "mlmodelc") {
            do {
                let model = try MLModel(contentsOf: modelURL)
                classificationModel = try VNCoreMLModel(for: model)
                print("Classification model loaded successfully")
            } catch {
                print("Failed to load classification model: \(error)")
            }
        }
    }
    
    func detectObjects(in image: UIImage, completion: @escaping ([DetectedObject]) -> Void) {
        DispatchQueue.main.async {
            self.isDetecting = true
            self.detectionProgress = 0.0
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var allDetections: [DetectedObject] = []
                
                // Step 1: YOLO Object Detection
                DispatchQueue.main.async {
                    self.detectionProgress = 0.3
                }
                
                if let yoloDetections = try self.performYOLODetection(image: image) {
                    allDetections.append(contentsOf: yoloDetections)
                }
                
                // Step 2: Enhanced Vision Detection
                DispatchQueue.main.async {
                    self.detectionProgress = 0.6
                }
                
                let visionDetections = try self.performEnhancedVisionDetection(image: image)
                allDetections.append(contentsOf: visionDetections)
                
                // Step 3: Post-process and merge results
                DispatchQueue.main.async {
                    self.detectionProgress = 0.8
                }
                
                let finalDetections = self.postProcessDetections(allDetections, image: image)
                
                DispatchQueue.main.async {
                    self.isDetecting = false
                    self.detectionProgress = 1.0
                    completion(finalDetections)
                }
                
            } catch {
                print("Professional detection failed: \(error)")
                DispatchQueue.main.async {
                    self.isDetecting = false
                    completion([])
                }
            }
        }
    }
    
    private func performYOLODetection(image: UIImage) throws -> [DetectedObject]? {
        guard let model = yoloModel, let cgImage = image.cgImage else { return nil }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            // This will be handled in the completion
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return nil
        }
        
        return results.compactMap { observation in
            guard let topLabel = observation.labels.first else { return nil }
            
            // Filter for objects of interest
            let label = topLabel.identifier.lowercased()
            if self.isObjectOfInterest(label) {
                return DetectedObject(
                    identifier: label,
                    confidence: Double(topLabel.confidence),
                    boundingBox: observation.boundingBox,
                    localizedName: self.getLocalizedName(for: label)
                )
            }
            
            return nil
        }
    }
    
    private func performEnhancedVisionDetection(image: UIImage) throws -> [DetectedObject] {
        guard let cgImage = image.cgImage else { return [] }
        
        var detections: [DetectedObject] = []
        
        // Rectangle detection for geometric objects
        let rectangleRequest = VNDetectRectanglesRequest()
        rectangleRequest.minimumAspectRatio = 0.1
        rectangleRequest.maximumAspectRatio = 10.0
        rectangleRequest.minimumSize = 0.01
        rectangleRequest.maximumObservations = 20
        rectangleRequest.quadratureTolerance = 20
        rectangleRequest.minimumConfidence = 0.5
        
        let rectangleHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try rectangleHandler.perform([rectangleRequest])
        
        if let rectangleResults = rectangleRequest.results as? [VNRectangleObservation] {
            for observation in rectangleResults {
                let objectType = classifyRectangle(observation)
                if let type = objectType {
                    let detection = DetectedObject(
                        identifier: type.identifier,
                        confidence: Double(observation.confidence),
                        boundingBox: observation.boundingBox,
                        localizedName: type.localizedName
                    )
                    detections.append(detection)
                }
            }
        }
        
        // Document detection for parcels
        let documentRequest = VNDetectDocumentSegmentationRequest()
        documentRequest.revision = VNDetectDocumentSegmentationRequestRevision1
        
        let documentHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try documentHandler.perform([documentRequest])
        
        if let documentResults = documentRequest.results as? [VNRectangleObservation] {
            for observation in documentResults {
                let detection = DetectedObject(
                    identifier: "parcel",
                    confidence: Double(observation.confidence),
                    boundingBox: observation.boundingBox,
                    localizedName: "Parcel"
                )
                detections.append(detection)
            }
        }
        
        return detections
    }
    
    private func classifyRectangle(_ observation: VNRectangleObservation) -> (identifier: String, localizedName: String)? {
        let aspectRatio = observation.boundingBox.width / observation.boundingBox.height
        let area = observation.boundingBox.width * observation.boundingBox.height
        let confidence = Double(observation.confidence)
        
        // Computer screen detection
        if aspectRatio >= 1.2 && aspectRatio <= 2.0 && area > 0.1 && confidence > 0.7 {
            return ("computer_screen", "Computer Screen")
        }
        
        // Door detection
        if aspectRatio >= 0.3 && aspectRatio <= 0.7 && area > 0.15 && confidence > 0.6 {
            return ("door", "Door")
        }
        
        // Window detection
        if aspectRatio >= 0.8 && aspectRatio <= 1.2 && area > 0.08 && confidence > 0.6 {
            return ("window", "Window")
        }
        
        // Table detection
        if aspectRatio >= 1.5 && aspectRatio <= 3.0 && area > 0.2 && confidence > 0.5 {
            return ("table", "Table")
        }
        
        // Parcel detection
        if aspectRatio >= 0.8 && aspectRatio <= 1.5 && area > 0.05 && area < 0.3 && confidence > 0.5 {
            return ("parcel", "Parcel")
        }
        
        return nil
    }
    
    private func isObjectOfInterest(_ label: String) -> Bool {
        return enhancedLabels.contains { enhancedLabel in
            label.contains(enhancedLabel) || enhancedLabel.contains(label)
        }
    }
    
    private func postProcessDetections(_ detections: [DetectedObject], image: UIImage) -> [DetectedObject] {
        // Remove duplicates based on bounding box overlap
        var uniqueDetections: [DetectedObject] = []
        var processedAreas: Set<String> = []
        
        for detection in detections {
            let areaKey = "\(Int(detection.boundingBox.origin.x * 100))_\(Int(detection.boundingBox.origin.y * 100))_\(Int(detection.boundingBox.width * 100))_\(Int(detection.boundingBox.height * 100))"
            
            if !processedAreas.contains(areaKey) {
                processedAreas.insert(areaKey)
                
                // Apply context-based enhancement
                let enhancedDetection = enhanceDetection(detection, in: image)
                uniqueDetections.append(enhancedDetection)
            }
        }
        
        // Sort by confidence and apply NMS
        let sortedDetections = uniqueDetections.sorted { $0.confidence > $1.confidence }
        let nmsDetections = applyNMS(sortedDetections)
        
        return nmsDetections.prefix(maxDetections).filter { $0.confidence > Double(confidenceThreshold) }
    }
    
    private func enhanceDetection(_ detection: DetectedObject, in image: UIImage) -> DetectedObject {
        // Apply context-based enhancement
        let centerX = detection.boundingBox.origin.x + detection.boundingBox.width / 2
        let centerY = detection.boundingBox.origin.y + detection.boundingBox.height / 2
        
        // Enhance computer detection
        if detection.identifier == "computer" || detection.identifier == "laptop" {
            if centerX > 0.3 && centerX < 0.7 && centerY > 0.3 && centerY < 0.7 {
                return DetectedObject(
                    identifier: "computer_screen",
                    confidence: detection.confidence * 1.2,
                    boundingBox: detection.boundingBox,
                    localizedName: "Computer Screen"
                )
            }
        }
        
        // Enhance door detection
        if detection.identifier == "door" {
            if centerY > 0.4 && centerY < 0.8 {
                return DetectedObject(
                    identifier: "door",
                    confidence: detection.confidence * 1.1,
                    boundingBox: detection.boundingBox,
                    localizedName: "Door"
                )
            }
        }
        
        return detection
    }
    
    private func applyNMS(_ detections: [DetectedObject]) -> [DetectedObject] {
        var result: [DetectedObject] = []
        var used = Set<Int>()
        
        for i in 0..<detections.count {
            if used.contains(i) { continue }
            
            result.append(detections[i])
            used.insert(i)
            
            for j in (i+1)..<detections.count {
                if used.contains(j) { continue }
                
                let iou = calculateIOU(
                    detections[i].boundingBox,
                    detections[j].boundingBox
                )
                
                if iou > nmsThreshold {
                    used.insert(j)
                }
            }
        }
        
        return result
    }
    
    private func calculateIOU(_ box1: CGRect, _ box2: CGRect) -> Float {
        let intersection = box1.intersection(box2)
        let union = box1.union(box2)
        
        if union.width * union.height == 0 {
            return 0
        }
        
        return Float((intersection.width * intersection.height) / (union.width * union.height))
    }
    
    private func getLocalizedName(for label: String) -> String {
        let labelMapping: [String: String] = [
            "computer": "Computer",
            "laptop": "Laptop",
            "desktop": "Desktop Computer",
            "monitor": "Monitor",
            "screen": "Screen",
            "tv": "Television",
            "television": "Television",
            "keyboard": "Keyboard",
            "mouse": "Mouse",
            "remote": "Remote Control",
            "door": "Door",
            "entrance": "Entrance",
            "exit": "Exit",
            "gateway": "Gateway",
            "gate": "Gate",
            "parcel": "Parcel",
            "package": "Package",
            "box": "Box",
            "delivery": "Delivery",
            "mail": "Mail",
            "window": "Window",
            "glass": "Glass",
            "pane": "Window Pane",
            "table": "Table",
            "desk": "Desk",
            "surface": "Surface",
            "chair": "Chair",
            "seat": "Seat",
            "furniture": "Furniture",
            "couch": "Couch",
            "sofa": "Sofa",
            "bed": "Bed",
            "dining table": "Dining Table",
            "computer_screen": "Computer Screen"
        ]
        
        return labelMapping[label] ?? label.capitalized
    }
}

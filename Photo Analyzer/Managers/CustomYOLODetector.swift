//
//  CustomYOLODetector.swift
//  Photo Analyzer
//
//  Single-model object detection system focused on custom-trained YOLOv8x
//

import Foundation
import Vision
import CoreML
import UIKit

class CustomYOLODetector: ObservableObject {
    @Published var isDetecting = false
    @Published var detectionProgress: Double = 0.0
    @Published var currentModelVersion: String = "v1.0"
    
    // Single custom YOLOv8x model
    private var customYOLOModel: VNCoreMLModel?
    private var modelMetadata: ModelMetadata?
    
    // Target object classes (customizable)
    private var targetClasses: [String] = [
        "computer", "door", "parcel", "parcel_at_door", "cup", "banana", 
        "person", "car", "phone", "keys", "package", "mail"
    ]
    
    init() {
        loadCustomModel()
    }
    
    // MARK: - Model Management
    
    private func loadCustomModel() {
        // Try to load custom trained model first, fallback to base YOLOv8x
        if let customModel = loadModelWithFallback() {
            self.customYOLOModel = customModel
            print("✅ Loaded custom YOLOv8x model")
        } else {
            print("❌ No detection model available")
        }
    }
    
    private func loadModelWithFallback() -> VNCoreMLModel? {
        // Priority order for model loading
        let modelCandidates = [
            "CustomYOLOv8x",     // User's trained model
            "yolov8x 2",         // Current working model
            "YOLOv8x",           // Standard YOLOv8x
            "yolov8x"            // Alternative naming
        ]
        
        for modelName in modelCandidates {
            if let modelURL = getModelURL(for: modelName),
               let model = try? MLModel(contentsOf: modelURL),
               let visionModel = try? VNCoreMLModel(for: model) {
                
                // Load model metadata if available
                loadModelMetadata(for: modelName)
                
                print("✅ Loaded model: \(modelName)")
                return visionModel
            }
        }
        
        return nil
    }
    
    private func getModelURL(for modelName: String) -> URL? {
        // Check bundle first
        let extensions = ["mlmodelc", "mlpackage", "mlmodel"]
        
        for ext in extensions {
            if let bundleURL = Bundle.main.url(forResource: modelName, withExtension: ext) {
                return bundleURL
            }
        }
        
        // Check documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        for ext in extensions {
            let fileURL = documentsPath.appendingPathComponent("\(modelName).\(ext)")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
        }
        
        return nil
    }
    
    // MARK: - Object Detection
    
    func detectObjects(in image: UIImage, completion: @escaping ([DetectedObject]) -> Void) {
        guard let customYOLOModel = customYOLOModel,
              let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        DispatchQueue.main.async {
            self.isDetecting = true
            self.detectionProgress = 0.0
        }
        
        let request = VNCoreMLRequest(model: customYOLOModel) { [weak self] request, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isDetecting = false
                self.detectionProgress = 1.0
            }
            
            if let error = error {
                print("❌ Detection error: \(error)")
                completion([])
                return
            }
            
            let detections = self.parseCustomYOLOResults(request.results)
            completion(detections)
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("❌ Vision request failed: \(error)")
                DispatchQueue.main.async {
                    self.isDetecting = false
                    completion([])
                }
            }
        }
    }
    
    private func parseCustomYOLOResults(_ results: [VNObservation]?) -> [DetectedObject] {
        guard let results = results as? [VNCoreMLFeatureValueObservation],
              let firstResult = results.first,
              let multiArray = firstResult.featureValue.multiArrayValue else {
            return []
        }
        
        return parseYOLOTensor(multiArray)
    }
    
    private func parseYOLOTensor(_ multiArray: MLMultiArray) -> [DetectedObject] {
        let shape = multiArray.shape.map { $0.intValue }
        
        guard shape.count == 3 else {
            print("❌ Unexpected tensor shape: \(shape)")
            return []
        }
        
        // YOLOv8 format: [batch, anchors, features] = [1, 8400, 84]
        let numAnchors = shape[1]
        let numFeatures = shape[2]
        let numClasses = numFeatures - 4 // Subtract bbox coordinates
        
        var detections: [DetectedObject] = []
        
        // Process all anchors (limit for performance if needed)
        let maxAnchors = min(numAnchors, 1000)
        
        for i in 0..<maxAnchors {
            // Extract bounding box: [centerX, centerY, width, height]
            let centerX = multiArray[[0, i, 0] as [NSNumber]].doubleValue
            let centerY = multiArray[[0, i, 1] as [NSNumber]].doubleValue
            let width = multiArray[[0, i, 2] as [NSNumber]].doubleValue
            let height = multiArray[[0, i, 3] as [NSNumber]].doubleValue
            
            // Find highest confidence class
            var maxConfidence: Double = 0
            var bestClassIndex = 0
            
            for classIndex in 0..<numClasses {
                let confidence = multiArray[[0, i, 4 + classIndex] as [NSNumber]].doubleValue
                if confidence > maxConfidence {
                    maxConfidence = confidence
                    bestClassIndex = classIndex
                }
            }
            
            // Apply sigmoid activation
            maxConfidence = 1.0 / (1.0 + exp(-maxConfidence))
            
            // Filter by confidence threshold
            if maxConfidence > 0.5 {
                let bbox = CGRect(
                    x: centerX - width/2,
                    y: centerY - height/2,
                    width: width,
                    height: height
                )
                
                let className = getClassName(for: bestClassIndex)
                
                let detection = DetectedObject(
                    identifier: className,
                    confidence: maxConfidence,
                    boundingBox: bbox,
                    localizedName: className.capitalized
                )
                
                detections.append(detection)
            }
        }
        
        // Apply Non-Maximum Suppression
        return applyNMS(detections)
    }
    
    private func getClassName(for classIndex: Int) -> String {
        // Use custom class names if available, fallback to COCO classes
        if let metadata = modelMetadata,
           classIndex < metadata.classNames.count {
            return metadata.classNames[classIndex]
        }
        
        // COCO class names (base YOLOv8)
        let cocoClasses = [
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
        
        return classIndex < cocoClasses.count ? cocoClasses[classIndex] : "object"
    }
    
    private func applyNMS(_ detections: [DetectedObject], threshold: Double = 0.5) -> [DetectedObject] {
        // Sort by confidence (highest first)
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var selectedDetections: [DetectedObject] = []
        
        for detection in sortedDetections {
            var shouldSelect = true
            
            for selectedDetection in selectedDetections {
                let iou = calculateIoU(detection.boundingBox, selectedDetection.boundingBox)
                if iou > threshold {
                    shouldSelect = false
                    break
                }
            }
            
            if shouldSelect {
                selectedDetections.append(detection)
            }
        }
        
        return selectedDetections
    }
    
    private func calculateIoU(_ box1: CGRect, _ box2: CGRect) -> Double {
        let intersection = box1.intersection(box2)
        let intersectionArea = intersection.width * intersection.height
        let unionArea = box1.width * box1.height + box2.width * box2.height - intersectionArea
        
        return unionArea > 0 ? Double(intersectionArea / unionArea) : 0
    }
    
    // MARK: - Model Metadata
    
    private func loadModelMetadata(for modelName: String) {
        // Try to load custom metadata file
        if let metadataURL = getMetadataURL(for: modelName),
           let data = try? Data(contentsOf: metadataURL),
           let metadata = try? JSONDecoder().decode(ModelMetadata.self, from: data) {
            self.modelMetadata = metadata
            self.currentModelVersion = metadata.version
            self.targetClasses = metadata.classNames
            print("✅ Loaded model metadata: \(metadata.version)")
        }
    }
    
    private func getMetadataURL(for modelName: String) -> URL? {
        // Check for metadata file in documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let metadataURL = documentsPath.appendingPathComponent("\(modelName)_metadata.json")
        return FileManager.default.fileExists(atPath: metadataURL.path) ? metadataURL : nil
    }
    
    // MARK: - Public Interface
    
    func getAvailableClasses() -> [String] {
        return targetClasses
    }
    
    func getModelInfo() -> String {
        if let metadata = modelMetadata {
            return "Custom Model v\(metadata.version) - \(metadata.classNames.count) classes"
        } else {
            return "Base YOLOv8x - 80 COCO classes"
        }
    }
    
    func isCustomModelLoaded() -> Bool {
        return modelMetadata != nil
    }
}

// MARK: - Model Metadata Structure

struct ModelMetadata: Codable {
    let version: String
    let classNames: [String]
    let trainingDate: String
    let accuracy: Double?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case version, classNames, trainingDate, accuracy, description
    }
}

// Note: DetectedObject is defined in AIAnalyzer.swift to avoid duplication

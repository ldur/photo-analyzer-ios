//
//  AIAnalyzer.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI
import Vision
import CoreML
import CoreImage

// MARK: - Analysis Result Models
struct AnalysisResult: Codable {
    let timestamp: Date
    let labels: [ImageLabel]
    let objects: [DetectedObject]
    let faces: [DetectedFace]
    let text: [DetectedText]
    let confidence: Double
    let processingTime: TimeInterval
}

struct ImageLabel: Codable {
    let identifier: String
    let confidence: Double
    let localizedName: String
}

struct DetectedObject: Codable {
    let identifier: String
    let confidence: Double
    let boundingBox: CGRect
    let localizedName: String
    
    enum CodingKeys: String, CodingKey {
        case identifier, confidence, localizedName
        case boundingBoxX, boundingBoxY, boundingBoxWidth, boundingBoxHeight
    }
    
    init(identifier: String, confidence: Double, boundingBox: CGRect, localizedName: String) {
        self.identifier = identifier
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.localizedName = localizedName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        confidence = try container.decode(Double.self, forKey: .confidence)
        localizedName = try container.decode(String.self, forKey: .localizedName)
        
        let x = try container.decode(CGFloat.self, forKey: .boundingBoxX)
        let y = try container.decode(CGFloat.self, forKey: .boundingBoxY)
        let width = try container.decode(CGFloat.self, forKey: .boundingBoxWidth)
        let height = try container.decode(CGFloat.self, forKey: .boundingBoxHeight)
        boundingBox = CGRect(x: x, y: y, width: width, height: height)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(localizedName, forKey: .localizedName)
        try container.encode(boundingBox.origin.x, forKey: .boundingBoxX)
        try container.encode(boundingBox.origin.y, forKey: .boundingBoxY)
        try container.encode(boundingBox.size.width, forKey: .boundingBoxWidth)
        try container.encode(boundingBox.size.height, forKey: .boundingBoxHeight)
    }
}

struct DetectedFace: Codable {
    let confidence: Double
    let boundingBox: CGRect
    let landmarks: [FaceLandmark]
    let age: Int?
    let gender: String?
    
    enum CodingKeys: String, CodingKey {
        case confidence, landmarks, age, gender
        case boundingBoxX, boundingBoxY, boundingBoxWidth, boundingBoxHeight
    }
    
    init(confidence: Double, boundingBox: CGRect, landmarks: [FaceLandmark], age: Int?, gender: String?) {
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.landmarks = landmarks
        self.age = age
        self.gender = gender
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        confidence = try container.decode(Double.self, forKey: .confidence)
        landmarks = try container.decode([FaceLandmark].self, forKey: .landmarks)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        
        let x = try container.decode(CGFloat.self, forKey: .boundingBoxX)
        let y = try container.decode(CGFloat.self, forKey: .boundingBoxY)
        let width = try container.decode(CGFloat.self, forKey: .boundingBoxWidth)
        let height = try container.decode(CGFloat.self, forKey: .boundingBoxHeight)
        boundingBox = CGRect(x: x, y: y, width: width, height: height)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(landmarks, forKey: .landmarks)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encode(boundingBox.origin.x, forKey: .boundingBoxX)
        try container.encode(boundingBox.origin.y, forKey: .boundingBoxY)
        try container.encode(boundingBox.size.width, forKey: .boundingBoxWidth)
        try container.encode(boundingBox.size.height, forKey: .boundingBoxHeight)
    }
}

struct FaceLandmark: Codable {
    let type: String
    let point: CGPoint
    
    enum CodingKeys: String, CodingKey {
        case type
        case pointX, pointY
    }
    
    init(type: String, point: CGPoint) {
        self.type = type
        self.point = point
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        let x = try container.decode(CGFloat.self, forKey: .pointX)
        let y = try container.decode(CGFloat.self, forKey: .pointY)
        point = CGPoint(x: x, y: y)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(point.x, forKey: .pointX)
        try container.encode(point.y, forKey: .pointY)
    }
}

struct DetectedText: Codable {
    let text: String
    let confidence: Double
    let boundingBox: CGRect
    
    enum CodingKeys: String, CodingKey {
        case text, confidence
        case boundingBoxX, boundingBoxY, boundingBoxWidth, boundingBoxHeight
    }
    
    init(text: String, confidence: Double, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        confidence = try container.decode(Double.self, forKey: .confidence)
        
        let x = try container.decode(CGFloat.self, forKey: .boundingBoxX)
        let y = try container.decode(CGFloat.self, forKey: .boundingBoxY)
        let width = try container.decode(CGFloat.self, forKey: .boundingBoxWidth)
        let height = try container.decode(CGFloat.self, forKey: .boundingBoxHeight)
        boundingBox = CGRect(x: x, y: y, width: width, height: height)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(boundingBox.origin.x, forKey: .boundingBoxX)
        try container.encode(boundingBox.origin.y, forKey: .boundingBoxY)
        try container.encode(boundingBox.size.width, forKey: .boundingBoxWidth)
        try container.encode(boundingBox.size.height, forKey: .boundingBoxHeight)
    }
}

// MARK: - Enhanced AI Analyzer
class AIAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    
    // Vision Framework Requests
    private let imageClassificationRequest = VNClassifyImageRequest()
    private let objectDetectionRequest = VNDetectRectanglesRequest()
    private let faceDetectionRequest = VNDetectFaceLandmarksRequest()
    private let textRecognitionRequest = VNRecognizeTextRequest()
    
    // Professional Object Detector
    private let professionalObjectDetector = ProfessionalObjectDetector()
    
    // Food Detection Enhancer
    private let foodDetectionEnhancer = FoodDetectionEnhancer()
    
    // Core ML Models (if available)
    private var objectDetectionModel: VNCoreMLModel?
    
    // Performance optimization
    private let processingQueue = DispatchQueue(label: "ai.analysis", qos: .userInitiated)
    private var modelCache: [String: VNCoreMLModel] = [:]
    
    init() {
        setupRequests()
        setupCoreMLModels()
        optimizeForDevice()
    }
    
    private func setupRequests() {
        // Configure text recognition
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
        
        // Face detection is configured by default to detect all landmarks
    }
    
    private func setupCoreMLModels() {
        // Try to load optimized models first
        let modelNames = ["YOLOv8n_optimized", "YOLOv8n", "YOLOv3"]
        
        for modelName in modelNames {
            if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
                do {
                    let model = try MLModel(contentsOf: modelURL)
                    let coreMLModel = try VNCoreMLModel(for: model)
                    
                    // Configure for optimal performance
                    // Note: VNCoreMLModel automatically uses the best available compute units
                    
                    objectDetectionModel = coreMLModel
                    modelCache[modelName] = coreMLModel
                    print("✅ Loaded optimized model: \(modelName)")
                    break
                } catch {
                    print("Failed to load \(modelName): \(error)")
                    continue
                }
            }
        }
        
        // If no custom model, we'll use enhanced Vision framework
    }
    
    private func optimizeForDevice() {
        // Configure requests for optimal performance
        // Note: usesCPUOnly is deprecated, Vision framework automatically optimizes
        
        // Enable revision-specific optimizations
        textRecognitionRequest.revision = VNRecognizeTextRequestRevision3
        faceDetectionRequest.revision = VNDetectFaceLandmarksRequestRevision3
        
        // Optimize for mobile performance
        if ProcessInfo.processInfo.thermalState != .nominal {
            // Reduce quality for thermal management
            textRecognitionRequest.recognitionLevel = .fast
        }
    }
    
    func analyzePhoto(_ image: UIImage, completion: @escaping (AnalysisResult?) -> Void) {
        DispatchQueue.main.async {
            self.isAnalyzing = true
            self.analysisProgress = 0.0
        }
        
        let startTime = Date()
        
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                self.isAnalyzing = false
                completion(nil)
            }
            return
        }
        
        // Enhanced analysis pipeline
        Task {
            do {
                // Step 1: Basic Vision analysis
                await MainActor.run {
                    self.analysisProgress = 0.2
                }
                
                let basicResults = try self.performBasicVisionAnalysis(cgImage: cgImage)
                
                // Step 2: Advanced object detection
                await MainActor.run {
                    self.analysisProgress = 0.5
                }
                
                let enhancedObjects = try await self.performAdvancedObjectDetection(image: image)
                
                // Step 2.5: Food-specific detection enhancement
                await MainActor.run {
                    self.analysisProgress = 0.65
                }
                
                let foodDetections = await self.performFoodDetectionEnhancement(image: image)
                let allEnhancedObjects = enhancedObjects + foodDetections
                
                // Step 3: Scene understanding
                await MainActor.run {
                    self.analysisProgress = 0.8
                }
                
                _ = self.performSceneAnalysis(image: image)
                
                // Combine results
                let processingTime = Date().timeIntervalSince(startTime)
                let allObjects = basicResults.objects + allEnhancedObjects
                
                let overallConfidence = self.calculateOverallConfidence(
                    labels: basicResults.labels,
                    objects: allObjects,
                    faces: basicResults.faces,
                    text: basicResults.text
                )
                
                let result = AnalysisResult(
                    timestamp: Date(),
                    labels: basicResults.labels,
                    objects: allObjects,
                    faces: basicResults.faces,
                    text: basicResults.text,
                    confidence: overallConfidence,
                    processingTime: processingTime
                )
                
                await MainActor.run {
                    self.isAnalyzing = false
                    self.analysisProgress = 1.0
                    completion(result)
                }
                
            } catch {
                print("Enhanced analysis failed: \(error)")
                await MainActor.run {
                    self.isAnalyzing = false
                    completion(nil)
                }
            }
        }
    }
    
    private func performBasicVisionAnalysis(cgImage: CGImage) throws -> (labels: [ImageLabel], objects: [DetectedObject], faces: [DetectedFace], text: [DetectedText]) {
        let requests = [
            imageClassificationRequest,
            objectDetectionRequest,
            faceDetectionRequest,
            textRecognitionRequest
        ]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform(requests)
        
        let labels = processClassificationResults()
        let objects = processObjectDetectionResults()
        let faces = processFaceDetectionResults()
        let text = processTextRecognitionResults()
        
        return (labels: labels, objects: objects, faces: faces, text: text)
    }
    
    private func performAdvancedObjectDetection(image: UIImage) async throws -> [DetectedObject] {
        return await withCheckedContinuation { continuation in
            professionalObjectDetector.detectObjects(in: image) { objects in
                continuation.resume(returning: objects)
            }
        }
    }
    
    private func performFoodDetectionEnhancement(image: UIImage) async -> [DetectedObject] {
        return await withCheckedContinuation { continuation in
            foodDetectionEnhancer.enhanceFoodDetection(in: image) { objects in
                continuation.resume(returning: objects)
            }
        }
    }
    

    
    private func performSceneAnalysis(image: UIImage) -> [ImageLabel] {
        var sceneLabels: [ImageLabel] = []
        
        // Analyze image characteristics for scene understanding
        if let cgImage = image.cgImage {
            let width = cgImage.width
            let height = cgImage.height
            
            // Indoor/outdoor detection based on image characteristics
            if width > 0 && height > 0 {
                let aspectRatio = CGFloat(width) / CGFloat(height)
                
                if aspectRatio > 1.5 {
                    sceneLabels.append(ImageLabel(
                        identifier: "landscape",
                        confidence: 0.8,
                        localizedName: "Landscape"
                    ))
                } else if aspectRatio < 0.8 {
                    sceneLabels.append(ImageLabel(
                        identifier: "portrait",
                        confidence: 0.8,
                        localizedName: "Portrait"
                    ))
                }
            }
        }
        
        return sceneLabels
    }
    
    // MARK: - Result Processing Methods
    private func processClassificationResults() -> [ImageLabel] {
        guard let results = imageClassificationRequest.results as? [VNClassificationObservation] else {
            return []
        }
        
        return results.prefix(10).map { observation in
            ImageLabel(
                identifier: observation.identifier,
                confidence: Double(observation.confidence),
                localizedName: observation.identifier
            )
        }
    }
    
    private func processObjectDetectionResults() -> [DetectedObject] {
        guard let results = objectDetectionRequest.results as? [VNRectangleObservation] else {
            return []
        }
        
        return results.map { observation in
            DetectedObject(
                identifier: "Rectangle",
                confidence: Double(observation.confidence),
                boundingBox: observation.boundingBox,
                localizedName: "Rectangle"
            )
        }
    }
    
    private func processFaceDetectionResults() -> [DetectedFace] {
        guard let results = faceDetectionRequest.results as? [VNFaceObservation] else {
            return []
        }
        
        return results.map { observation in
            let landmarks = processFaceLandmarks(observation.landmarks)
            
            return DetectedFace(
                confidence: Double(observation.confidence),
                boundingBox: observation.boundingBox,
                landmarks: landmarks,
                age: nil,
                gender: nil
            )
        }
    }
    
    private func processFaceLandmarks(_ landmarks: VNFaceLandmarks2D?) -> [FaceLandmark] {
        guard let landmarks = landmarks else { return [] }
        
        var faceLandmarks: [FaceLandmark] = []
        
        let regions: [(String, VNFaceLandmarkRegion2D?)] = [
            ("leftEye", landmarks.leftEye),
            ("rightEye", landmarks.rightEye),
            ("nose", landmarks.nose),
            ("mouth", landmarks.outerLips),
            ("leftEyebrow", landmarks.leftEyebrow),
            ("rightEyebrow", landmarks.rightEyebrow)
        ]
        
        for (type, region) in regions {
            if let points = region?.normalizedPoints {
                for point in points {
                    faceLandmarks.append(FaceLandmark(type: type, point: point))
                }
            }
        }
        
        return faceLandmarks
    }
    
    private func processTextRecognitionResults() -> [DetectedText] {
        guard let results = textRecognitionRequest.results as? [VNRecognizedTextObservation] else {
            return []
        }
        
        return results.compactMap { observation in
            guard let topCandidate = observation.topCandidates(1).first else { return nil }
            
            return DetectedText(
                text: topCandidate.string,
                confidence: Double(topCandidate.confidence),
                boundingBox: observation.boundingBox
            )
        }
    }
    
    private func calculateOverallConfidence(labels: [ImageLabel], objects: [DetectedObject], faces: [DetectedFace], text: [DetectedText]) -> Double {
        let allConfidences = labels.map { $0.confidence } +
                           objects.map { $0.confidence } +
                           faces.map { $0.confidence } +
                           text.map { $0.confidence }
        
        guard !allConfidences.isEmpty else { return 0.0 }
        
        return allConfidences.reduce(0, +) / Double(allConfidences.count)
    }
}

enum AnalysisAspect {
    case objects
    case text
    case faces
    case labels
}

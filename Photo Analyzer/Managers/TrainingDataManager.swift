//
//  TrainingDataManager.swift
//  Photo Analyzer
//
//  Manages collection and labeling of training data for custom YOLOv8x model
//

import Foundation
import UIKit
import SwiftData

class TrainingDataManager: ObservableObject {
    @Published var isCollectingData = false
    @Published var labeledPhotos: [LabeledPhoto] = []
    @Published var availableLabels: [String] = [
        "computer", "door", "parcel", "parcel_at_door", "cup", "person", 
        "car", "phone", "keys", "package", "mail", "other"
    ]
    
    private let documentsPath: URL
    private let trainingDataPath: URL
    
    init() {
        self.documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.trainingDataPath = documentsPath.appendingPathComponent("TrainingData")
        
        setupTrainingDirectory()
        loadExistingData()
    }
    
    // MARK: - Setup
    
    private func setupTrainingDirectory() {
        try? FileManager.default.createDirectory(at: trainingDataPath, withIntermediateDirectories: true)
        
        // Create subdirectories for each label
        for label in availableLabels {
            let labelPath = trainingDataPath.appendingPathComponent(label)
            try? FileManager.default.createDirectory(at: labelPath, withIntermediateDirectories: true)
        }
    }
    
    private func loadExistingData() {
        // Load previously labeled photos
        for label in availableLabels {
            let labelPath = trainingDataPath.appendingPathComponent(label)
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: labelPath, includingPropertiesForKeys: nil)
                
                for file in files where file.pathExtension.lowercased() == "jpg" {
                    let labeledPhoto = LabeledPhoto(
                        id: UUID(),
                        imagePath: file.path,
                        label: label,
                        boundingBoxes: [],
                        createdDate: Date()
                    )
                    labeledPhotos.append(labeledPhoto)
                }
            } catch {
                print("❌ Error loading training data for \(label): \(error)")
            }
        }
    }
    
    // MARK: - Data Collection
    
    func addLabeledPhoto(_ image: UIImage, label: String, boundingBoxes: [BoundingBox] = []) {
        let photoId = UUID()
        let fileName = "\(photoId.uuidString).jpg"
        let labelPath = trainingDataPath.appendingPathComponent(label)
        let filePath = labelPath.appendingPathComponent(fileName)
        
        // Save image
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: filePath)
                
                // Create labeled photo record
                let labeledPhoto = LabeledPhoto(
                    id: photoId,
                    imagePath: filePath.path,
                    label: label,
                    boundingBoxes: boundingBoxes,
                    createdDate: Date()
                )
                
                labeledPhotos.append(labeledPhoto)
                
                // Save metadata
                saveLabelMetadata(for: labeledPhoto)
                
                print("✅ Added labeled photo: \(label)")
                
            } catch {
                print("❌ Error saving training image: \(error)")
            }
        }
    }
    
    private func saveLabelMetadata(for labeledPhoto: LabeledPhoto) {
        let metadataURL = URL(fileURLWithPath: labeledPhoto.imagePath).appendingPathExtension("json")
        
        do {
            let metadata = LabelMetadata(
                label: labeledPhoto.label,
                boundingBoxes: labeledPhoto.boundingBoxes,
                createdDate: labeledPhoto.createdDate
            )
            
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataURL)
            
        } catch {
            print("❌ Error saving label metadata: \(error)")
        }
    }
    
    // MARK: - Training Data Export
    
    func exportTrainingData() -> URL? {
        _ = documentsPath.appendingPathComponent("TrainingExport_\(Date().timeIntervalSince1970).zip")
        
        // Create training manifest
        let manifest = TrainingManifest(
            version: "1.0",
            classes: availableLabels,
            totalImages: labeledPhotos.count,
            createdDate: Date(),
            photos: labeledPhotos
        )
        
        do {
            let manifestData = try JSONEncoder().encode(manifest)
            let manifestURL = trainingDataPath.appendingPathComponent("manifest.json")
            try manifestData.write(to: manifestURL)
            
            // TODO: Create ZIP archive of training data
            // For now, return the training data directory
            return trainingDataPath
            
        } catch {
            print("❌ Error exporting training data: \(error)")
            return nil
        }
    }
    
    // MARK: - Statistics
    
    func getTrainingStats() -> TrainingStats {
        var classCounts: [String: Int] = [:]
        
        for label in availableLabels {
            classCounts[label] = labeledPhotos.filter { $0.label == label }.count
        }
        
        return TrainingStats(
            totalPhotos: labeledPhotos.count,
            classDistribution: classCounts,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Computed Properties
    
    var labeledPhotosCount: Int {
        return labeledPhotos.count
    }
    
    var isReadyForTraining: Bool {
        // Need at least 5 labeled photos and at least 2 different labels
        return labeledPhotos.count >= 5 && availableLabels.count >= 2
    }
    
    // MARK: - Label Management
    
    func addCustomLabel(_ label: String) {
        guard !availableLabels.contains(label) else { return }
        
        availableLabels.append(label)
        
        // Create directory for new label
        let labelPath = trainingDataPath.appendingPathComponent(label)
        try? FileManager.default.createDirectory(at: labelPath, withIntermediateDirectories: true)
    }
    
    func removeLabel(_ label: String) {
        guard let index = availableLabels.firstIndex(of: label) else { return }
        
        availableLabels.remove(at: index)
        
        // Remove photos with this label
        labeledPhotos.removeAll { $0.label == label }
        
        // Remove directory
        let labelPath = trainingDataPath.appendingPathComponent(label)
        try? FileManager.default.removeItem(at: labelPath)
    }
}

// MARK: - Data Structures

struct LabeledPhoto: Identifiable, Codable {
    let id: UUID
    let imagePath: String
    let label: String
    let boundingBoxes: [BoundingBox]
    let createdDate: Date
}

struct BoundingBox: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let label: String
}

struct LabelMetadata: Codable {
    let label: String
    let boundingBoxes: [BoundingBox]
    let createdDate: Date
}

struct TrainingManifest: Codable {
    let version: String
    let classes: [String]
    let totalImages: Int
    let createdDate: Date
    let photos: [LabeledPhoto]
}

struct TrainingStats {
    let totalPhotos: Int
    let classDistribution: [String: Int]
    let lastUpdated: Date
}

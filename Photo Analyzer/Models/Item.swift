//
//  Photo.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import Foundation
import SwiftData
import Photos

@Model
final class Photo {
    var assetIdentifier: String
    var creationDate: Date
    var thumbnailData: Data?
    var isAnalyzed: Bool
    var analysisResult: Data? // Store AnalysisResult as encoded data
    var analysisDate: Date?
    var trainingLabel: String? // For custom model training (deprecated - use labels relationship)
    
    // Many-to-many relationship with Label
    @Relationship var labels: [Label] = []
    
    // One-to-one relationship with ClassificationResult
    @Relationship var classificationResult: ClassificationResult?
    
    init(assetIdentifier: String, creationDate: Date = Date(), thumbnailData: Data? = nil) {
        self.assetIdentifier = assetIdentifier
        self.creationDate = creationDate
        self.thumbnailData = thumbnailData
        self.isAnalyzed = false
        self.analysisResult = nil
        self.analysisDate = nil
        self.trainingLabel = nil
    }
    
    func setAnalysisResult(_ result: AnalysisResult) {
        self.analysisResult = try? JSONEncoder().encode(result)
        self.analysisDate = Date()
        self.isAnalyzed = true
    }
    
    func getAnalysisResult() -> AnalysisResult? {
        guard let data = analysisResult else { return nil }
        return try? JSONDecoder().decode(AnalysisResult.self, from: data)
    }
    
    var hasTrainingLabel: Bool {
        return trainingLabel != nil && !trainingLabel!.isEmpty
    }
    
    // MARK: - Label Management
    
    var hasLabels: Bool {
        return !labels.isEmpty
    }
    
    var labelNames: [String] {
        return labels.map { $0.name }
    }
    
    var displayLabels: String {
        return labels.map { $0.displayName }.joined(separator: ", ")
    }
    
    func addLabel(_ label: Label) {
        if !labels.contains(where: { $0.name == label.name }) {
            labels.append(label)
            label.incrementUsage()
        }
    }
    
    func removeLabel(_ label: Label) {
        if let index = labels.firstIndex(where: { $0.name == label.name }) {
            labels.remove(at: index)
            label.decrementUsage()
        }
    }
    
    func hasLabel(_ labelName: String) -> Bool {
        return labels.contains { $0.name.lowercased() == labelName.lowercased() }
    }
    
    func clearLabels() {
        for label in labels {
            label.decrementUsage()
        }
        labels.removeAll()
    }
}

//
//  PostalClassificationManager.swift
//  Photo Analyzer
//
//  Manager for postal package classification and scoring
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class PostalClassificationManager: ObservableObject {
    
    /// Classify a photo based on its manually applied labels
    func classifyPhoto(_ photo: Photo, modelContext: ModelContext) {
        // Get label counts from the photo's labels
        var labelCounts: [String: Int] = [:]
        
        // Count occurrences of each label
        for label in photo.labels {
            labelCounts[label.name, default: 0] += 1
        }
        
        // If no labels, mark as ingen objekter (no_objects)
        if labelCounts.isEmpty {
            labelCounts["ingen objekter"] = 1
        }
        
        // Calculate score using the classification logic
        let result = ClassificationResult.calculateScore(from: labelCounts)
        
        // Create or update classification result
        if let existingResult = photo.classificationResult {
            // Update existing result
            existingResult.score = result.score
            existingResult.detectedLabels = Array(labelCounts.keys)
            existingResult.reasoning = result.reasoning
            existingResult.classificationDate = Date()
        } else {
            // Create new result
            let classificationResult = ClassificationResult(
                photoAssetIdentifier: photo.assetIdentifier,
                score: result.score,
                detectedLabels: Array(labelCounts.keys),
                reasoning: result.reasoning
            )
            
            // Insert into context and link to photo
            modelContext.insert(classificationResult)
            photo.classificationResult = classificationResult
        }
        
        // Save the context
        do {
            try modelContext.save()
            print("✅ Classification updated for photo: Score \(result.score) - \(result.reasoning)")
        } catch {
            print("❌ Failed to save classification result: \(error)")
        }
    }
    
    /// Batch classify all photos that have labels but no classification
    func classifyAllPhotos(photos: [Photo], modelContext: ModelContext) {
        var classifiedCount = 0
        
        for photo in photos {
            if photo.hasLabels {
                classifyPhoto(photo, modelContext: modelContext)
                classifiedCount += 1
            }
        }
        
        print("✅ Classified \(classifiedCount) photos")
    }
    
    /// Get classification statistics
    func getClassificationStats(photos: [Photo]) -> ClassificationStats {
        let classifiedPhotos = photos.filter { $0.classificationResult != nil }
        let totalPhotos = photos.count
        let unclassifiedPhotos = totalPhotos - classifiedPhotos.count
        
        var scoreDistribution: [String: Int] = [:]
        var averageScore: Double = 0.0
        
        if !classifiedPhotos.isEmpty {
            let totalScore = classifiedPhotos.reduce(0.0) { sum, photo in
                let score = photo.classificationResult?.score ?? 0.0
                
                // Categorize score for distribution
                let category: String
                switch score {
                case 1.0:
                    category = "Perfect (1.0)"
                case 0.7..<1.0:
                    category = "High (0.7-0.99)"
                case 0.5..<0.7:
                    category = "Medium (0.5-0.69)"
                case 0.25..<0.5:
                    category = "Low (0.25-0.49)"
                case 0.1..<0.25:
                    category = "Very Low (0.1-0.24)"
                case 0.05..<0.1:
                    category = "Minimal (0.05-0.09)"
                default:
                    category = "None (0.0)"
                }
                
                scoreDistribution[category, default: 0] += 1
                return sum + score
            }
            averageScore = totalScore / Double(classifiedPhotos.count)
        }
        
        return ClassificationStats(
            totalPhotos: totalPhotos,
            classifiedPhotos: classifiedPhotos.count,
            unclassifiedPhotos: unclassifiedPhotos,
            averageScore: averageScore,
            scoreDistribution: scoreDistribution
        )
    }
}

// MARK: - Classification Statistics
struct ClassificationStats {
    let totalPhotos: Int
    let classifiedPhotos: Int
    let unclassifiedPhotos: Int
    let averageScore: Double
    let scoreDistribution: [String: Int]
    
    var averageScorePercentage: Int {
        return Int(averageScore * 100)
    }
    
    var classificationRate: Double {
        guard totalPhotos > 0 else { return 0.0 }
        return Double(classifiedPhotos) / Double(totalPhotos)
    }
    
    var classificationRatePercentage: Int {
        return Int(classificationRate * 100)
    }
}

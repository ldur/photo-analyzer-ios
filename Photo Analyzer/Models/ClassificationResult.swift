//
//  ClassificationResult.swift
//  Photo Analyzer
//
//  Classification result model for postal package scoring
//

import Foundation
import SwiftData

@Model
final class ClassificationResult {
    var photoAssetIdentifier: String
    var score: Double
    var detectedLabels: [String]
    var classificationDate: Date
    var reasoning: String
    
    // Relationship to Photo
    @Relationship(inverse: \Photo.classificationResult) var photo: Photo?
    
    init(photoAssetIdentifier: String, score: Double, detectedLabels: [String], reasoning: String) {
        self.photoAssetIdentifier = photoAssetIdentifier
        self.score = score
        self.detectedLabels = detectedLabels
        self.reasoning = reasoning
        self.classificationDate = Date()
    }
    
    // Computed properties
    var scorePercentage: Int {
        return Int(score * 100)
    }
    
    var confidenceLevel: String {
        switch score {
        case 1.0:
            return "Very High"
        case 0.7...0.99:
            return "High"
        case 0.5...0.69:
            return "Medium"
        case 0.25...0.49:
            return "Low"
        case 0.1...0.24:
            return "Very Low"
        case 0.05...0.09:
            return "Minimal"
        default:
            return "None"
        }
    }
    
    var riskLevel: String {
        switch score {
        case 1.0:
            return "Package Delivery Confirmed"
        case 0.7...0.99:
            return "High Probability"
        case 0.5...0.69:
            return "Moderate Probability"
        case 0.25...0.49:
            return "Low Probability"
        default:
            return "No Package Detected"
        }
    }
}

// MARK: - Classification Logic
extension ClassificationResult {
    
    /// Calculate classification score based on Norwegian postal package detection spec
    static func calculateScore(from labelCounts: [String: Int]) -> (score: Double, reasoning: String) {
        
        // Extract counts for each relevant label (Norwegian names)
        let ingenObjekter = labelCounts["ingen objekter"] ?? 0
        let pakke = labelCounts["pakke"] ?? 0
        let postkasse = labelCounts["postkasse"] ?? 0
        let etikett = labelCounts["etikett"] ?? 0
        let postkasseskilt = labelCounts["postkasseskilt"] ?? 0
        let pakkeIPostkasse = labelCounts["pakke i postkasse"] ?? 0
        let pakkeVedInngangsparti = labelCounts["pakke ved inngangsparti"] ?? 0
        let inngangsparti = labelCounts["inngangsparti"] ?? 0
        
        var reasoning = "Classification based on detected objects: "
        var reasoningParts: [String] = []
        
        // Add detected objects to reasoning
        for (label, count) in labelCounts where count > 0 {
            reasoningParts.append("\(label): \(count)")
        }
        reasoning += reasoningParts.joined(separator: ", ")
        
        // Apply the classification rules in order of priority
        if ingenObjekter > 0 {
            reasoning += " → Ingen relevante objekter oppdaget (No relevant objects detected)"
            return (0, reasoning)
        }
        
        if pakke > 0 && postkasse > 0 && etikett > 0 && postkasseskilt > 0 {
            reasoning += " → Komplett pakkeleveringsoppsett oppdaget (Complete package delivery setup detected)"
            return (1.0, reasoning)
        }
        
        if pakkeIPostkasse > 0 && etikett > 0 && postkasseskilt > 0 {
            reasoning += " → Pakke i postkasse med riktig identifikasjon (Package in mailbox with proper identification)"
            return (1.0, reasoning)
        }
        
        if pakkeVedInngangsparti > 0 {
            reasoning += " → Pakke ved inngangsparti oppdaget (Package at entrance detected)"
            return (1.0, reasoning)
        }
        
        if pakke > 0 && inngangsparti > 0 {
            reasoning += " → Pakke nær inngangsområde (Package near entrance area)"
            return (1.0, reasoning)
        }
        
        if etikett > 0 && postkasseskilt > 0 {
            reasoning += " → Etikett og postkasseskilt oppdaget (Label and mailbox nameplate detected)"
            return (0.8, reasoning)
        }
        
        if pakke > 0 && postkasse > 0 && postkasseskilt > 0 {
            reasoning += " → Pakke med postkasse og skilt (Package with mailbox and nameplate)"
            return (0.7, reasoning)
        }
        
        if pakke > 0 && postkasseskilt > 0 {
            reasoning += " → Pakke med postkasseskilt (Package with mailbox nameplate)"
            return (0.6, reasoning)
        }
        
        if pakke > 0 && postkasse > 0 && etikett > 0 {
            reasoning += " → Pakke med postkasse og etikett (Package with mailbox and label)"
            return (0.5, reasoning)
        }
        
        if inngangsparti > 0 {
            reasoning += " → Inngangsparti oppdaget (Entrance area detected)"
            return (0.5, reasoning)
        }
        
        if pakke > 0 && postkasse > 0 {
            reasoning += " → Pakke og postkasse oppdaget (Package and mailbox detected)"
            return (0.25, reasoning)
        }
        
        if postkasse > 0 && postkasseskilt > 0 {
            reasoning += " → Postkasse med skilt oppdaget (Mailbox with nameplate detected)"
            return (0.25, reasoning)
        }
        
        if postkasseskilt > 0 {
            reasoning += " → Postkasseskilt oppdaget (Mailbox nameplate detected)"
            return (0.2, reasoning)
        }
        
        if pakke > 0 {
            reasoning += " → Pakke oppdaget (Package detected)"
            return (0.1, reasoning)
        }
        
        if postkasse > 0 {
            reasoning += " → Postkasse oppdaget (Mailbox detected)"
            return (0.1, reasoning)
        }
        
        if etikett > 0 {
            reasoning += " → Etikett oppdaget (Label detected)"
            return (0.05, reasoning)
        }
        
        reasoning += " → Ingen relevante postobjekter oppdaget (No relevant postal objects detected)"
        return (0, reasoning)
    }
}

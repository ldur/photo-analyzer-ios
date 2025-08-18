//
//  Label.swift
//  Photo Analyzer
//
//  Label model for photo labeling and training data
//

import Foundation
import SwiftData

@Model
final class Label {
    var name: String
    var category: String?
    var color: String?
    var creationDate: Date
    var usageCount: Int
    
    // Many-to-many relationship with Photo
    @Relationship(inverse: \Photo.labels) var photos: [Photo] = []
    
    init(name: String, category: String? = nil, color: String? = nil) {
        self.name = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.category = category
        self.color = color
        self.creationDate = Date()
        self.usageCount = 0
    }
    
    // Computed properties
    var displayName: String {
        return name.capitalized
    }
    
    var isPopular: Bool {
        return usageCount >= 3
    }
    
    // Helper methods
    func incrementUsage() {
        usageCount += 1
    }
    
    func decrementUsage() {
        if usageCount > 0 {
            usageCount -= 1
        }
    }
    
    // Check if label is unused (no photos associated and usage count is 0)
    var isUnused: Bool {
        return photos.isEmpty && usageCount == 0
    }
}

// MARK: - Label Categories
extension Label {
    enum Category: String, CaseIterable {
        case object = "object"
        case person = "person"
        case animal = "animal"
        case food = "food"
        case vehicle = "vehicle"
        case building = "building"
        case nature = "nature"
        case technology = "technology"
        case postal = "postal"
        case other = "other"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var color: String {
            switch self {
            case .object: return "blue"
            case .person: return "green"
            case .animal: return "brown"
            case .food: return "orange"
            case .vehicle: return "red"
            case .building: return "gray"
            case .nature: return "green"
            case .technology: return "purple"
            case .postal: return "red"
            case .other: return "black"
            }
        }
    }
    
    static let commonLabels: [String: Category] = [
        // Norwegian Postal/Package Classification Labels
        "ingen objekter": .other,           // no_objects
        "pakke": .postal,                   // package
        "postkasse": .postal,               // mailbox
        "etikett": .postal,                 // label
        "postkasseskilt": .postal,          // mailbox nameplate
        "pakke i postkasse": .postal,       // package in mailbox
        "pakke ved inngangsparti": .postal, // package at entrance area
        "inngangsparti": .building,         // entrance area
    ]
}

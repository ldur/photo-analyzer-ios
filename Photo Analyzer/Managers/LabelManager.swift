//
//  LabelManager.swift
//  Photo Analyzer
//
//  Manager for label operations including cleanup and organization
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class LabelManager: ObservableObject {
    
    /// Delete all unused labels from the database
    /// Returns the number of labels deleted
    func deleteUnusedLabels(modelContext: ModelContext) -> Int {
        do {
            // Fetch all labels
            let fetchDescriptor = FetchDescriptor<Label>()
            let allLabels = try modelContext.fetch(fetchDescriptor)
            
            // Filter unused labels
            let unusedLabels = allLabels.filter { $0.isUnused }
            
            // Delete unused labels
            for label in unusedLabels {
                modelContext.delete(label)
            }
            
            // Save changes
            try modelContext.save()
            
            print("🗑️ Deleted \(unusedLabels.count) unused labels")
            return unusedLabels.count
        } catch {
            print("❌ Error deleting unused labels: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// Get statistics about label usage
    func getLabelStatistics(modelContext: ModelContext) -> LabelStatistics {
        do {
            let fetchDescriptor = FetchDescriptor<Label>()
            let allLabels = try modelContext.fetch(fetchDescriptor)
            
            let totalLabels = allLabels.count
            let usedLabels = allLabels.filter { !$0.isUnused }.count
            let unusedLabels = allLabels.filter { $0.isUnused }.count
            let popularLabels = allLabels.filter { $0.isPopular }.count
            
            return LabelStatistics(
                totalLabels: totalLabels,
                usedLabels: usedLabels,
                unusedLabels: unusedLabels,
                popularLabels: popularLabels
            )
        } catch {
            print("❌ Error fetching label statistics: \(error.localizedDescription)")
            return LabelStatistics(totalLabels: 0, usedLabels: 0, unusedLabels: 0, popularLabels: 0)
        }
    }
    
    /// Find duplicate labels (same name but different instances)
    func findDuplicateLabels(modelContext: ModelContext) -> [String: [Label]] {
        do {
            let fetchDescriptor = FetchDescriptor<Label>()
            let allLabels = try modelContext.fetch(fetchDescriptor)
            
            let groupedLabels = Dictionary(grouping: allLabels) { $0.name }
            let duplicates = groupedLabels.filter { $1.count > 1 }
            
            return duplicates
        } catch {
            print("❌ Error finding duplicate labels: \(error.localizedDescription)")
            return [:]
        }
    }
    
    /// Merge duplicate labels by consolidating their usage
    func mergeDuplicateLabels(modelContext: ModelContext) -> Int {
        do {
            let duplicates = findDuplicateLabels(modelContext: modelContext)
            var mergedCount = 0
            
            for (_, duplicateLabels) in duplicates {
                guard duplicateLabels.count > 1 else { continue }
                
                // Sort by creation date, keep the oldest
                let sortedLabels = duplicateLabels.sorted { $0.creationDate < $1.creationDate }
                let keepLabel = sortedLabels.first!
                let labelsToMerge = Array(sortedLabels.dropFirst())
                
                // Merge usage counts and photo relationships
                for labelToMerge in labelsToMerge {
                    keepLabel.usageCount += labelToMerge.usageCount
                    
                    // Transfer photo relationships
                    for photo in labelToMerge.photos {
                        if !keepLabel.photos.contains(where: { $0.assetIdentifier == photo.assetIdentifier }) {
                            photo.removeLabel(labelToMerge)
                            photo.addLabel(keepLabel)
                        }
                    }
                    
                    // Delete the duplicate
                    modelContext.delete(labelToMerge)
                    mergedCount += 1
                }
            }
            
            try modelContext.save()
            print("🔄 Merged \(mergedCount) duplicate labels")
            return mergedCount
        } catch {
            print("❌ Error merging duplicate labels: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// Comprehensive cleanup: merge duplicates and delete unused labels
    func performLabelCleanup(modelContext: ModelContext) -> LabelCleanupResult {
        let mergedCount = mergeDuplicateLabels(modelContext: modelContext)
        let deletedCount = deleteUnusedLabels(modelContext: modelContext)
        
        return LabelCleanupResult(mergedLabels: mergedCount, deletedLabels: deletedCount)
    }
}

// MARK: - Data Structures

struct LabelStatistics {
    let totalLabels: Int
    let usedLabels: Int
    let unusedLabels: Int
    let popularLabels: Int
    
    var unusedPercentage: Double {
        guard totalLabels > 0 else { return 0 }
        return Double(unusedLabels) / Double(totalLabels) * 100
    }
    
    var popularPercentage: Double {
        guard totalLabels > 0 else { return 0 }
        return Double(popularLabels) / Double(totalLabels) * 100
    }
}

struct LabelCleanupResult {
    let mergedLabels: Int
    let deletedLabels: Int
    
    var totalCleaned: Int {
        return mergedLabels + deletedLabels
    }
}

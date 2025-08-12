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
    
    init(assetIdentifier: String, creationDate: Date = Date(), thumbnailData: Data? = nil) {
        self.assetIdentifier = assetIdentifier
        self.creationDate = creationDate
        self.thumbnailData = thumbnailData
        self.isAnalyzed = false
        self.analysisResult = nil
        self.analysisDate = nil
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
}

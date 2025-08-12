//
//  Color+Extensions.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI

extension Color {
    static let appBackground = Color.black
    static let appSecondary = Color.gray.opacity(0.3)
    static let appAccent = Color.white
    static let appSuccess = Color.green
    static let appWarning = Color.orange
    static let appError = Color.red
    
    // Analysis confidence colors
    static func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .yellow
        case 0.4..<0.6:
            return .orange
        default:
            return .red
        }
    }
}

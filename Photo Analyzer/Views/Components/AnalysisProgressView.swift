//
//  AnalysisProgressView.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI

struct AnalysisProgressView: View {
    let progress: Double
    let isAnalyzing: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Analyzing photo...")
                .font(.caption)
                .foregroundColor(.gray)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AnalysisProgressView(progress: 0.6, isAnalyzing: true)
    }
}

//
//  AnalysisResultsView.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI

struct AnalysisResultsView: View {
    let analysisResult: AnalysisResult
    @Environment(\.dismiss) private var dismiss
    @StateObject private var simplifiedDetector = SimplifiedObjectDetector()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Detection Status
                        DetectionStatusView(simplifiedDetector: simplifiedDetector)
                        
                        // Header with confidence and processing time
                        headerSection
                        
                        // Image Labels
                        if !analysisResult.labels.isEmpty {
                            labelsSection
                        }
                        
                        // Detected Objects
                        if !analysisResult.objects.isEmpty {
                            objectsSection
                        }
                        
                        // Detected Faces
                        if !analysisResult.faces.isEmpty {
                            facesSection
                        }
                        
                        // Detected Text
                        if !analysisResult.text.isEmpty {
                            textSection
                        }
                        
                        // Analysis Metadata
                        metadataSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Confidence")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(analysisResult.confidence * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Processing Time")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.2fs", analysisResult.processingTime))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            // Confidence bar
            ProgressView(value: analysisResult.confidence)
                .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var labelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.blue)
                Text("Image Labels")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(analysisResult.labels.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(analysisResult.labels.prefix(5), id: \.identifier) { label in
                    HStack {
                        Text(label.localizedName)
                            .font(.body)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(label.confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var objectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.dashed")
                    .foregroundColor(.green)
                Text("Detected Objects")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(analysisResult.objects.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(analysisResult.objects.enumerated()), id: \.offset) { index, object in
                    HStack {
                        Text(object.localizedName)
                            .font(.body)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(object.confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var facesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundColor(.orange)
                Text("Detected Faces")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(analysisResult.faces.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(analysisResult.faces.enumerated()), id: \.offset) { index, face in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Face \(index + 1)")
                                .font(.body)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(face.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text("\(face.landmarks.count) landmarks detected")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "textformat")
                    .foregroundColor(.purple)
                Text("Detected Text")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(analysisResult.text.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(analysisResult.text.enumerated()), id: \.offset) { index, textItem in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(textItem.text)
                            .font(.body)
                            .foregroundColor(.white)
                            .lineLimit(3)
                        
                        HStack {
                            Text("Confidence: \(Int(textItem.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.cyan)
                Text("Analysis Metadata")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Analysis Date")
                        .font(.body)
                        .foregroundColor(.white)
                    Spacer()
                    Text(analysisResult.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Analysis Time")
                        .font(.body)
                        .foregroundColor(.white)
                    Spacer()
                    Text(analysisResult.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Total Detections")
                        .font(.body)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(analysisResult.labels.count + analysisResult.objects.count + analysisResult.faces.count + analysisResult.text.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var confidenceColor: Color {
        Color.confidenceColor(analysisResult.confidence)
    }
}

#Preview {
    let sampleResult = AnalysisResult(
        timestamp: Date(),
        labels: [
            ImageLabel(identifier: "person", confidence: 0.95, localizedName: "Person"),
            ImageLabel(identifier: "outdoor", confidence: 0.87, localizedName: "Outdoor")
        ],
        objects: [
            DetectedObject(identifier: "rectangle", confidence: 0.92, boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8), localizedName: "Rectangle")
        ],
        faces: [
            DetectedFace(confidence: 0.89, boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6), landmarks: [], age: nil, gender: nil)
        ],
        text: [
            DetectedText(text: "Sample Text", confidence: 0.85, boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.1))
        ],
        confidence: 0.90,
        processingTime: 1.25
    )
    
    return AnalysisResultsView(analysisResult: sampleResult)
}

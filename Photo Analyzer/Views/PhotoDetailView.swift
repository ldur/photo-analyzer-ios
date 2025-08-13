//
//  PhotoDetailView.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI
import Photos

struct PhotoDetailView: View {
    let photo: Photo
    @ObservedObject var photoManager: PhotoManager
    @StateObject private var aiAnalyzer = AIAnalyzer()
    @Environment(\.dismiss) private var dismiss
    @State private var fullImage: UIImage?
    @State private var isLoading = true
    @State private var showingAnalysisResults = false
    @State private var showingModelManagement = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if photo.isAnalyzed {
                        Button(action: {
                            showingAnalysisResults = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("View Analysis")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(15)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            Text("Pending")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(15)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Add share functionality
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Photo display
                ZStack {
                    if let fullImage = fullImage {
                        Image(uiImage: fullImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .transition(.opacity)
                    } else if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Failed to load image")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom info panel
                VStack(spacing: 16) {
                    // Date and time
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                        Text(photo.creationDate, style: .date)
                            .foregroundColor(.white)
                        Spacer()
                        Text(photo.creationDate, style: .time)
                            .foregroundColor(.gray)
                    }
                    .font(.subheadline)
                    
                    // Analysis button
                    if !photo.isAnalyzed {
                        VStack(spacing: 12) {
                            if aiAnalyzer.isAnalyzing {
                                AnalysisProgressView(
                                    progress: aiAnalyzer.analysisProgress,
                                    isAnalyzing: aiAnalyzer.isAnalyzing
                                )
                            } else {
                                                            VStack(spacing: 12) {
                                Button(action: {
                                    analyzePhoto()
                                }) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("Analyze Photo")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(25)
                                }
                                
                                Button(action: {
                                    showingModelManagement = true
                                }) {
                                    HStack {
                                        Image(systemName: "brain.head.profile")
                                        Text("Manage AI Models")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.cyan)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.cyan.opacity(0.2))
                                    .cornerRadius(15)
                                }
                            }
                            }
                        }
                    } else {
                        // Analysis results summary
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Analysis Complete")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if let result = photo.getAnalysisResult() {
                                HStack {
                                    Text("Confidence: \(Int(result.confidence * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(result.labels.count + result.objects.count + result.faces.count + result.text.count) detections")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {
                                showingAnalysisResults = true
                            }) {
                                Text("View Full Results")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(15)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            loadFullImage()
        }
                        .sheet(isPresented: $showingAnalysisResults) {
                    if let result = photo.getAnalysisResult() {
                        AnalysisResultsView(analysisResult: result)
                    }
                }
                .sheet(isPresented: $showingModelManagement) {
                    EnhancedModelManagementView()
                }
    }
    
    private func loadFullImage() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = photoManager.getThumbnail(for: photo.assetIdentifier, size: CGSize(width: 1000, height: 1000)) {
                DispatchQueue.main.async {
                    self.fullImage = image
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func analyzePhoto() {
        guard let image = fullImage else { return }
        
        aiAnalyzer.analyzePhoto(image) { result in
            if let result = result {
                photo.setAnalysisResult(result)
            }
        }
    }
}

#Preview {
    PhotoDetailView(
        photo: Photo(assetIdentifier: "test"),
        photoManager: PhotoManager()
    )
}

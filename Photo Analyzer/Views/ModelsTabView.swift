//
//  ModelsTabView.swift
//  Photo Analyzer
//
//  Models tab for managing AI models and detection settings
//

import SwiftUI

struct ModelsTabView: View {
    @StateObject private var simplifiedDetector = SimplifiedObjectDetector()
    @State private var showingModelManagement = false
    @State private var showingEnhancedModelManagement = false
    @State private var showingProfile = false
    @State private var showingLabelManagement = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    
                    // Current Model Status
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Current Detection Model")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("YOLOv8x")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Spacer()
                            Text("Active")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                        
                        Text("High-accuracy object detection model optimized for detailed analysis")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    availableModelsView
                    
                    detectionStatusView
                    
                    modelManagementActionsView
                    
                    customTrainingView
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // TODO: Add upload functionality similar to GalleryView
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingLabelManagement = true
                        }) {
                            Image(systemName: "tag.circle")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            showingProfile = true
                        }) {
                            Image(systemName: "person.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingModelManagement) {
                ModelManagementView()
            }
            .sheet(isPresented: $showingEnhancedModelManagement) {
                EnhancedModelManagementView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingLabelManagement) {
                LabelManagementView()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("AI Models")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Manage detection models and settings")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.top, 20)
    }
    
    private var availableModelsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Models")
                .font(.headline)
                .foregroundColor(.white)
            
            let availableModels = simplifiedDetector.getAvailableModels()
            
            ForEach(availableModels, id: \.self) { model in
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(.blue)
                    Text(model)
                        .font(.body)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Ready")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            
            if availableModels.isEmpty {
                Text("No additional models found")
                    .font(.body)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var detectionStatusView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detection Status")
                .font(.headline)
                .foregroundColor(.white)
            
            let statusMessage = simplifiedDetector.getDetectionStatus()
            let availableModels = simplifiedDetector.getAvailableModels()
            let hasModels = !availableModels.isEmpty
            
            HStack {
                Image(systemName: hasModels ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(hasModels ? .green : .red)
                Text("Object Detection")
                    .foregroundColor(.white)
                Spacer()
                Text(hasModels ? "Available" : "Unavailable")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(hasModels ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(hasModels ? .green : .red)
                    .cornerRadius(8)
            }
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Vision Framework")
                    .foregroundColor(.white)
                Spacer()
                Text("Available")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            
            Text(statusMessage)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var modelManagementActionsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingModelManagement = true
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Basic Model Management")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                showingEnhancedModelManagement = true
            }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Advanced Model Settings")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var customTrainingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Model Training")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Train a specialized model using your labeled photos for improved accuracy on specific objects.")
                .font(.body)
                .foregroundColor(.gray)
            
            NavigationLink(destination: PhotoLabelingView()) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Start Custom Training")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ModelsTabView()
}

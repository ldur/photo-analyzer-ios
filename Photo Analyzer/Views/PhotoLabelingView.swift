//
//  PhotoLabelingView.swift
//  Photo Analyzer
//
//  Interface for labeling photos to build training data
//

import SwiftUI
import SwiftData

enum LabelingFilter: String, CaseIterable {
    case all = "All"
    case labeled = "Labeled"
    case notLabeled = "Not Labeled"
    
    var icon: String {
        switch self {
        case .all: return "photo.on.rectangle"
        case .labeled: return "tag.fill"
        case .notLabeled: return "photo"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .labeled: return .orange
        case .notLabeled: return .gray
        }
    }
}

struct PhotoLabelingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Photo.creationDate, order: .reverse) private var allPhotos: [Photo]
    @Query(sort: \Label.usageCount, order: .reverse) private var allLabels: [Label]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var trainingManager = TrainingDataManager()
    @StateObject private var photoManager = PhotoManager()
    @StateObject private var classificationManager = PostalClassificationManager()
    @State private var selectedPhoto: Photo?
    @State private var selectedLabels: Set<Label> = []
    @State private var showingLabelPicker = false
    @State private var showingAddLabel = false
    @State private var newLabelName = ""
    @State private var selectedCategory: Label.Category = .object
    @State private var currentFilter: LabelingFilter = .all
    @State private var showingProfile = false
    @State private var showingUploadOptions = false
    @State private var showingPhotoPicker = false
    @State private var showingDocumentPicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var selectedURLs: [URL] = []
    @State private var isUploading = false
    @State private var showingLabelManagement = false
    @State private var viewMode: ViewMode = .grid
    
    // Computed property for filtered photos
    private var filteredPhotos: [Photo] {
        switch currentFilter {
        case .all:
            return allPhotos
        case .labeled:
            return allPhotos.filter { $0.hasLabels }
        case .notLabeled:
            return allPhotos.filter { !$0.hasLabels }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                if allPhotos.isEmpty {
                    // No photos available
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Photos Available")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Take some photos first to start labeling them for training")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if selectedPhoto == nil {
                    // Photo selection interface
                    VStack(spacing: 8) {
                        // Filter picker and view mode toggle
                        HStack {
                            labelingFilterPicker
                            
                            Spacer()
                            
                            ViewModeToggle(viewMode: $viewMode)
                        }
                        .padding(.horizontal)
                        
                        Text(filterTitle)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if filteredPhotos.isEmpty {
                            // Empty state for current filter
                            VStack(spacing: 16) {
                                Image(systemName: currentFilter.icon)
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text(emptyStateMessage)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                // Show filter stats
                                filterStatsView
                            }
                            .padding()
                        } else {
                            ScrollView {
                                if viewMode == .grid {
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 8),
                                        GridItem(.flexible(), spacing: 8),
                                        GridItem(.flexible(), spacing: 8)
                                    ], spacing: 12) {
                                        ForEach(filteredPhotos) { photo in
                                            Button(action: {
                                                selectedPhoto = photo
                                            }) {
                                                PhotoThumbnailView(photo: photo, photoManager: photoManager)
                                                    .aspectRatio(1, contentMode: .fill)
                                                    .clipped()
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(
                                                                photo.hasLabels ? Color.orange : Color.clear,
                                                                lineWidth: 3
                                                            )
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                } else {
                                    PhotoLabelingListView(
                                        photos: filteredPhotos,
                                        photoManager: photoManager,
                                        onPhotoTap: { photo in
                                            selectedPhoto = photo
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Symbol legend
                        symbolLegendView
                        
                        // Training status
                        trainingStatusView
                    }
                } else {
                    // Photo labeling interface
                    VStack(spacing: 0) {
                        // Photo display beneath header
                        if let photo = selectedPhoto {
                            PhotoThumbnailView(photo: photo, photoManager: photoManager)
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange, lineWidth: 2)
                                )
                                .padding(.horizontal)
                                .padding(.top, 30)
                                .padding(.bottom, 20)
                        }
                        
                        photoLabelingInterface
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Photo Labeling")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedPhoto != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Back") {
                            selectedPhoto = nil
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showingUploadOptions = true
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
            }
        }
        .sheet(isPresented: $showingLabelPicker) {
            LabelPickerView(
                selectedPhoto: selectedPhoto,
                allLabels: allLabels,
                onLabelSelected: { label in
                    if let photo = selectedPhoto {
                        addLabel(label, to: photo)
                    }
                },
                onCreateNewLabel: {
                    showingAddLabel = true
                }
            )
        }
        .sheet(isPresented: $showingAddLabel) {
            CreateLabelView(
                newLabelName: $newLabelName,
                selectedCategory: $selectedCategory,
                onSave: { name, category in
                    createNewLabel(name: name, category: category)
                },
                onCancel: {
                    newLabelName = ""
                    showingAddLabel = false
                }
            )
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingUploadOptions) {
            uploadOptionsView
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(selectedImages: $selectedImages)
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(selectedURLs: $selectedURLs)
        }
        .sheet(isPresented: $showingLabelManagement) {
            LabelManagementView()
        }
        .onAppear {
            if let photo = selectedPhoto {
                loadExistingLabel(for: photo)
            }
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            if let photo = newPhoto {
                loadExistingLabel(for: photo)
            }
        }
        .onChange(of: selectedImages) { _, newImages in
            if !newImages.isEmpty {
                uploadImages(newImages)
            }
        }
        .onChange(of: selectedURLs) { _, newURLs in
            if !newURLs.isEmpty {
                uploadFiles(newURLs)
            }
        }
    }
    
    private var photoLabelingInterface: some View {
        VStack(spacing: 20) {
            // Labeling Interface
            if selectedPhoto != nil {
                VStack(spacing: 20) {
                    Text("Label this photo")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Current labels display
                    if let photo = selectedPhoto, !photo.labels.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.orange)
                                Text("Current Labels:")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 120))
                            ], spacing: 12) {
                                ForEach(photo.labels, id: \.name) { label in
                                    HStack(spacing: 6) {
                                        Text(label.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Button(action: {
                                            removeLabel(label, from: photo)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.15))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(16)
                    }
                    
                    // Classification Score Display
                    if let photo = selectedPhoto, let classification = photo.classificationResult {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.blue)
                                Text("Classification Score:")
                                    .font(.headline)
                                Spacer()
                                Text("\(classification.scorePercentage)%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(scoreColor(for: classification.score))
                            }
                            
                            Text(classification.confidenceLevel)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(scoreColor(for: classification.score))
                            
                            Text(classification.reasoning)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(16)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(16)
                    }
                    
                    // Add label button
                    Button(action: {
                        showingLabelPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(selectedPhoto?.labels.isEmpty ?? true ? "Add Labels" : "Add More Labels")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
        }
    }
    
    private var trainingStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            let labeledPhotosCount = allPhotos.filter { $0.hasLabels }.count
            let uniqueLabelsCount = allLabels.count
            
            HStack {
                Image(systemName: "chart.bar.horizontal.3")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(labeledPhotosCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("\(uniqueLabelsCount)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            if labeledPhotosCount >= 5 && uniqueLabelsCount >= 2 {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    Spacer()
                }
                
                Button(action: {
                    exportTrainingData()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Training Data")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else {
                HStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var symbolLegendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo Status Symbols")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 16) {
                // Labeled symbol
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Labeled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Analyzed symbol
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Analyzed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // MARK: - Filter UI Components
    
    private var labelingFilterPicker: some View {
        HStack(spacing: 0) {
            ForEach(LabelingFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentFilter = filter
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: filter.icon)
                            .font(.caption)
                        Text(filter.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(currentFilter == filter ? filter.color : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        currentFilter == filter ? 
                        filter.color.opacity(0.2) : Color.clear
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var filterStatsView: some View {
        HStack(spacing: 16) {
            ForEach(LabelingFilter.allCases, id: \.self) { filter in
                VStack(spacing: 2) {
                    Text("\(getPhotoCount(for: filter))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(filter.color)
                    
                    Text(filter.rawValue)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    private var filterTitle: String {
        switch currentFilter {
        case .all:
            return "Select a photo to label"
        case .labeled:
            return "Labeled photos (\(filteredPhotos.count))"
        case .notLabeled:
            return "Photos to label (\(filteredPhotos.count))"
        }
    }
    
    private var emptyStateMessage: String {
        switch currentFilter {
        case .all:
            return "No photos available for labeling"
        case .labeled:
            return "No labeled photos yet. Start labeling some photos to build your training dataset."
        case .notLabeled:
            return "Great! All photos have been labeled. Your training dataset is complete."
        }
    }
    
    private func getPhotoCount(for filter: LabelingFilter) -> Int {
        switch filter {
        case .all:
            return allPhotos.count
        case .labeled:
            return allPhotos.filter { $0.hasLabels }.count
        case .notLabeled:
            return allPhotos.filter { !$0.hasLabels }.count
        }
    }
    
    // MARK: - Upload Functions
    
    private var uploadOptionsView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Upload Photos")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    Button(action: {
                        showingUploadOptions = false
                        showingPhotoPicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                            Text("Choose from Photo Library")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingUploadOptions = false
                        showingDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .font(.title2)
                            Text("Import from Files")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingUploadOptions = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func uploadImages(_ images: [UIImage]) {
        isUploading = true
        
        Task {
            for image in images {
                if let assetIdentifier = await photoManager.savePhotoToAlbum(image) {
                    // Create Photo model for SwiftData
                    await MainActor.run {
                        let photo = Photo(assetIdentifier: assetIdentifier, creationDate: Date())
                        modelContext.insert(photo)
                        try? modelContext.save()
                    }
                }
            }
            
            await MainActor.run {
                selectedImages = []
                isUploading = false
                print("✅ Successfully uploaded \(images.count) images to PhotoLabelingView")
            }
        }
    }
    
    private func uploadFiles(_ urls: [URL]) {
        isUploading = true
        
        Task {
            let assetIdentifiers = await photoManager.importPhotosFromFiles(urls)
            
            await MainActor.run {
                // Create Photo models for SwiftData
                for assetIdentifier in assetIdentifiers {
                    let photo = Photo(assetIdentifier: assetIdentifier, creationDate: Date())
                    modelContext.insert(photo)
                }
                try? modelContext.save()
                
                selectedURLs = []
                isUploading = false
                print("✅ Successfully uploaded \(assetIdentifiers.count) files to PhotoLabelingView")
            }
        }
    }
    
    // MARK: - Label Management Methods
    
    private func addLabel(_ label: Label, to photo: Photo) {
        photo.addLabel(label)
        try? modelContext.save()
        
        // Trigger classification after adding label
        classificationManager.classifyPhoto(photo, modelContext: modelContext)
    }
    
    private func removeLabel(_ label: Label, from photo: Photo) {
        photo.removeLabel(label)
        try? modelContext.save()
        
        // Trigger classification after removing label
        classificationManager.classifyPhoto(photo, modelContext: modelContext)
    }
    
    private func createNewLabel(name: String, category: Label.Category) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check if label already exists
        if let existingLabel = allLabels.first(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            // Use existing label
            if let photo = selectedPhoto {
                addLabel(existingLabel, to: photo)
            }
        } else {
            // Create new label
            let newLabel = Label(name: trimmedName, category: category.rawValue, color: category.color)
            modelContext.insert(newLabel)
            
            if let photo = selectedPhoto {
                addLabel(newLabel, to: photo)
            }
            
            try? modelContext.save()
        }
        
        // Reset form
        newLabelName = ""
        showingAddLabel = false
        showingLabelPicker = false
    }
    
    private func loadExistingLabel(for photo: Photo) {
        // Reset state for new photo
        selectedLabels = Set(photo.labels)
    }
    
    private func getOrCreateLabel(name: String, category: Label.Category? = nil) -> Label {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if let existingLabel = allLabels.first(where: { $0.name == trimmedName }) {
            return existingLabel
        } else {
            let labelCategory = category ?? Label.commonLabels[trimmedName] ?? .other
            let newLabel = Label(name: trimmedName, category: labelCategory.rawValue, color: labelCategory.color)
            modelContext.insert(newLabel)
            try? modelContext.save()
            return newLabel
        }
    }
    
    private func exportTrainingData() {
        if let exportURL = trainingManager.exportTrainingData() {
            // Show share sheet or save confirmation
            print("✅ Training data exported to: \(exportURL)")
        }
    }
    
    // MARK: - Helper Functions
    
    private func scoreColor(for score: Double) -> Color {
        switch score {
        case 1.0:
            return .green
        case 0.7..<1.0:
            return .blue
        case 0.5..<0.7:
            return .orange
        case 0.25..<0.5:
            return .yellow
        case 0.1..<0.25:
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    NavigationView {
        PhotoLabelingView()
            .modelContainer(for: [Photo.self, Label.self, ClassificationResult.self], inMemory: true)
    }
}
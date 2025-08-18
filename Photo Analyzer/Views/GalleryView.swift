//
//  GalleryView.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI
import SwiftData

enum PhotoFilter: String, CaseIterable {
    case all = "All"
    case analyzed = "Analyzed"
    case labeled = "Labeled"
    
    var icon: String {
        switch self {
        case .all: return "photo.on.rectangle"
        case .analyzed: return "brain.head.profile"
        case .labeled: return "tag.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .white
        case .analyzed: return .blue
        case .labeled: return .orange
        }
    }
}

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Photo.creationDate, order: .reverse) private var allPhotos: [Photo]
    @ObservedObject var photoManager: PhotoManager
    @State private var showingPhotoPicker = false
    @State private var showingDocumentPicker = false
    @State private var showingUploadOptions = false
    @State private var selectedImages: [UIImage] = []
    @State private var selectedURLs: [URL] = []
    @State private var isUploading = false
    @State private var selectionMode = false
    @State private var selectedPhotos: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var showingProfile = false
    @State private var currentFilter: PhotoFilter = .all
    @State private var viewMode: ViewMode = .grid
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    // Computed property for filtered photos
    private var filteredPhotos: [Photo] {
        switch currentFilter {
        case .all:
            return allPhotos
        case .analyzed:
            return allPhotos.filter { $0.isAnalyzed }
        case .labeled:
            return allPhotos.filter { $0.hasLabels }
        }
    }
    
    // Empty state computed properties
    private var emptyStateTitle: String {
        switch currentFilter {
        case .all:
            return "No Photos Yet"
        case .analyzed:
            return "No Analyzed Photos"
        case .labeled:
            return "No Labeled Photos"
        }
    }
    
    private var emptyStateMessage: String {
        switch currentFilter {
        case .all:
            return "Take your first photo to get started"
        case .analyzed:
            return "Take some photos and analyze them with AI to see them here"
        case .labeled:
            return "Add labels to your photos in the Labeling tab to see them here"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                mainContentSection
            }
            .navigationTitle("Photo Analyzer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectionMode {
                        Button("Cancel") {
                            selectionMode = false
                            selectedPhotos.removeAll()
                        }
                        .foregroundColor(.white)
                    } else {
                        Button(action: {
                            showingUploadOptions = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectionMode {
                        HStack {
                            if !selectedPhotos.isEmpty {
                                Button(action: {
                                    showingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    } else {
                        HStack {
                            Button(action: {
                                selectionMode = true
                            }) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                showingProfile = true
                            }) {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                

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
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .alert("Delete Photos", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteSelectedPhotos()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \(selectedPhotos.count) photo(s)? This action cannot be undone.")
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
    }
    
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
    
    private func toggleSelection(for assetIdentifier: String) {
        if selectedPhotos.contains(assetIdentifier) {
            selectedPhotos.remove(assetIdentifier)
        } else {
            selectedPhotos.insert(assetIdentifier)
        }
    }
    
    private func uploadImages(_ images: [UIImage]) {
        isUploading = true
        
        Task {
            for image in images {
                if let assetIdentifier = await photoManager.savePhotoToAlbum(image) {
                    // Create Photo model for SwiftData
                    await MainActor.run {
                        let photo = Photo(assetIdentifier: assetIdentifier)
                        modelContext.insert(photo)
                        try? modelContext.save()
                    }
                }
            }
            
            await MainActor.run {
                selectedImages = []
                isUploading = false
                print("✅ Successfully uploaded \(images.count) images")
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
                    let photo = Photo(assetIdentifier: assetIdentifier)
                    modelContext.insert(photo)
                }
                try? modelContext.save()
                
                selectedURLs = []
                isUploading = false
                print("✅ Successfully uploaded \(assetIdentifiers.count) files")
            }
        }
    }
    
    private func deleteSelectedPhotos() {
        Task {
            let identifiersToDelete = Array(selectedPhotos)
            let deletedCount = await photoManager.deletePhotos(with: identifiersToDelete)
            
            await MainActor.run {
                // Remove from SwiftData
                for identifier in identifiersToDelete {
                    if let photo = allPhotos.first(where: { $0.assetIdentifier == identifier }) {
                        modelContext.delete(photo)
                    }
                }
                try? modelContext.save()
                
                selectedPhotos.removeAll()
                selectionMode = false
                print("✅ Successfully deleted \(deletedCount) photos")
            }
        }
    }
    
    private func deletePhoto(_ photo: Photo) {
        // Delete from model context
        modelContext.delete(photo)
        
        // Save changes
        do {
            try modelContext.save()
            print("✅ Successfully deleted photo")
        } catch {
            print("❌ Error deleting photo: \(error.localizedDescription)")
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        Group {
            if !selectionMode {
                VStack(spacing: 12) {
                    HStack {
                        photoFilterPicker
                        
                        Spacer()
                        
                        ViewModeToggle(viewMode: $viewMode)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color.black)
            }
        }
    }
    
    private var mainContentSection: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if filteredPhotos.isEmpty {
                emptyStateView
            } else {
                photoContentView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: currentFilter == .all ? "camera.fill" : currentFilter.icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if !allPhotos.isEmpty && currentFilter != .all {
                filterStatsView
                    .padding(.top, 10)
            }
        }
    }
    
    private var photoContentView: some View {
        ScrollView {
            if viewMode == .grid {
                gridView
            } else {
                listView
            }
        }
    }
    
    private var gridView: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(filteredPhotos) { photo in
                if selectionMode {
                    selectionPhotoView(photo: photo)
                } else {
                    standardPhotoView(photo: photo)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var listView: some View {
        PhotoListView(
            photos: filteredPhotos,
            photoManager: photoManager,
            onPhotoTap: { photo in
                // Navigation handled automatically in list view
            },
            onDeletePhoto: selectionMode ? nil : { photo in
                deletePhoto(photo)
            }
        )
        .padding(.top, 8)
    }
    
    private func selectionPhotoView(photo: Photo) -> some View {
        PhotoThumbnailView(photo: photo, photoManager: photoManager)
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .cornerRadius(12)
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: selectedPhotos.contains(photo.assetIdentifier) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedPhotos.contains(photo.assetIdentifier) ? .blue : .white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                            .padding(8)
                    }
                    Spacer()
                }
            )
            .onTapGesture {
                toggleSelection(for: photo.assetIdentifier)
            }
    }
    
    private func standardPhotoView(photo: Photo) -> some View {
        NavigationLink(destination: PhotoDetailView(photo: photo, photoManager: photoManager)) {
            PhotoThumbnailView(photo: photo, photoManager: photoManager)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Filter UI Components
    
    private var photoFilterPicker: some View {
        HStack(spacing: 0) {
            ForEach(PhotoFilter.allCases, id: \.self) { filter in
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
            ForEach(PhotoFilter.allCases, id: \.self) { filter in
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
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
    
    private func getPhotoCount(for filter: PhotoFilter) -> Int {
        switch filter {
        case .all:
            return allPhotos.count
        case .analyzed:
            return allPhotos.filter { $0.isAnalyzed }.count
        case .labeled:
            return allPhotos.filter { $0.hasLabels }.count
        }
    }
}

#Preview {
    GalleryView(photoManager: PhotoManager())
        .modelContainer(for: [Photo.self, Profile.self], inMemory: true)
}



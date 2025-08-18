//
//  PhotoListView.swift
//  Photo Analyzer
//
//  List view component for displaying photos in a detailed list format
//

import SwiftUI

struct PhotoListView: View {
    let photos: [Photo]
    let photoManager: PhotoManager
    let onPhotoTap: (Photo) -> Void
    let onDeletePhoto: ((Photo) -> Void)?
    
    init(photos: [Photo], photoManager: PhotoManager, onPhotoTap: @escaping (Photo) -> Void, onDeletePhoto: ((Photo) -> Void)? = nil) {
        self.photos = photos
        self.photoManager = photoManager
        self.onPhotoTap = onPhotoTap
        self.onDeletePhoto = onDeletePhoto
    }
    
    var body: some View {
        LazyVStack(spacing: 1) {
            ForEach(photos) { photo in
                PhotoListRowView(
                    photo: photo,
                    photoManager: photoManager,
                    onTap: { onPhotoTap(photo) },
                    onDelete: onDeletePhoto != nil ? { onDeletePhoto?(photo) } : nil
                )
                .background(Color.black.opacity(0.1))
            }
        }
    }
}

struct PhotoListRowView: View {
    let photo: Photo
    let photoManager: PhotoManager
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationLink(destination: PhotoDetailView(photo: photo, photoManager: photoManager)) {
            HStack(spacing: 12) {
                // Thumbnail
                PhotoThumbnailView(photo: photo, photoManager: photoManager)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()
                
                // Photo information
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(formatDate(photo.creationDate))
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Status indicators
                        HStack(spacing: 8) {
                            if photo.hasLabels {
                                HStack(spacing: 4) {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("\(photo.labels.count)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            if photo.isAnalyzed {
                                HStack(spacing: 4) {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    if let analysis = photo.getAnalysisResult() {
                                        Text("\(analysis.objects.count)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            if let classification = photo.classificationResult {
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundColor(scoreColor(for: classification.score))
                                        .font(.caption)
                                    Text("\(classification.scorePercentage)%")
                                        .font(.caption)
                                        .foregroundColor(scoreColor(for: classification.score))
                                }
                            }
                        }
                    }
                    
                    // Labels
                    if !photo.labels.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(photo.labels, id: \.name) { label in
                                    Text(label.displayName)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.3))
                                        .foregroundColor(.orange)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                    
                    // Detection results preview
                    if photo.isAnalyzed, let analysis = photo.getAnalysisResult() {
                        Text(analysis.objects.prefix(3).map { $0.localizedName }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    // Classification reasoning
                    if let classification = photo.classificationResult {
                        Text(classification.reasoning)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Action indicators
                VStack(spacing: 8) {
                    if onDelete != nil {
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Photo", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            formatter.dateFormat = "HH:mm"
            return "Today \(formatter.string(from: date))"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
                  calendar.isDate(date, inSameDayAs: yesterday) {
            formatter.dateFormat = "HH:mm"
            return "Yesterday \(formatter.string(from: date))"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE HH:mm"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, HH:mm"
            return formatter.string(from: date)
        }
    }
    
    private func scoreColor(for score: Double) -> Color {
        switch score {
        case 1.0: return .green
        case 0.7..<1.0: return .blue
        case 0.5..<0.7: return .orange
        case 0.25..<0.5: return .yellow
        case 0.1..<0.25: return .red
        default: return .gray
        }
    }
}

#Preview {
    PhotoListView(
        photos: [],
        photoManager: PhotoManager(),
        onPhotoTap: { _ in },
        onDeletePhoto: { _ in }
    )
    .preferredColorScheme(.dark)
}

//
//  PhotoLabelingListView.swift
//  Photo Analyzer
//
//  List view component for displaying photos in the labeling screen
//

import SwiftUI

struct PhotoLabelingListView: View {
    let photos: [Photo]
    let photoManager: PhotoManager
    let onPhotoTap: (Photo) -> Void
    
    var body: some View {
        LazyVStack(spacing: 1) {
            ForEach(photos) { photo in
                PhotoLabelingListRowView(
                    photo: photo,
                    photoManager: photoManager,
                    onTap: { onPhotoTap(photo) }
                )
                .background(Color.black.opacity(0.1))
            }
        }
    }
}

struct PhotoLabelingListRowView: View {
    let photo: Photo
    let photoManager: PhotoManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail with labeling border
                PhotoThumbnailView(photo: photo, photoManager: photoManager)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                photo.hasLabels ? Color.orange : Color.clear,
                                lineWidth: 2
                            )
                    )
                
                // Photo information
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(formatDate(photo.creationDate))
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Labeling status indicators
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
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "tag")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                    Text("0")
                                        .font(.caption)
                                        .foregroundColor(.gray)
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
                    
                    // Current labels
                    if !photo.labels.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(photo.labels.prefix(5), id: \.name) { label in
                                    Text(label.displayName)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.3))
                                        .foregroundColor(.orange)
                                        .cornerRadius(4)
                                }
                                
                                if photo.labels.count > 5 {
                                    Text("+\(photo.labels.count - 5)")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.3))
                                        .foregroundColor(.gray)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                    
                    // AI detection preview (if available and no labels)
                    if !photo.hasLabels && photo.isAnalyzed, let analysis = photo.getAnalysisResult() {
                        Text("AI detected: \(analysis.objects.prefix(3).map { $0.localizedName }.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                    
                    // Classification reasoning (if available)
                    if let classification = photo.classificationResult {
                        Text(classification.reasoning)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    // Labeling prompt
                    if !photo.hasLabels {
                        Text("Tap to add labels for training")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .italic()
                    }
                }
                
                Spacer()
                
                // Action indicators
                VStack(spacing: 4) {
                    Image(systemName: "tag.circle")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
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
    PhotoLabelingListView(
        photos: [],
        photoManager: PhotoManager(),
        onPhotoTap: { _ in }
    )
    .preferredColorScheme(.dark)
}

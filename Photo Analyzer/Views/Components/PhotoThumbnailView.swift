//
//  PhotoThumbnailView.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI

struct PhotoThumbnailView: View {
    let photo: Photo
    @ObservedObject var photoManager: PhotoManager
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }
            
            // Status indicators
            VStack {
                HStack {
                    Spacer()
                    
                    // Show both labeled and analyzed indicators if both are present
                    HStack(spacing: 4) {
                        // Labeled indicator (priority symbol)
                        if photo.hasLabels {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.orange)
                                .background(Circle().fill(Color.white))
                                .font(.caption)
                                .padding(6)
                        }
                        
                        // Analyzed indicator
                        if photo.isAnalyzed {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                                .background(Circle().fill(Color.white))
                                .font(.caption)
                                .padding(6)
                        }
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        if let thumbnailData = photo.thumbnailData {
            thumbnail = UIImage(data: thumbnailData)
        } else {
            // Load thumbnail from photo library
            DispatchQueue.global(qos: .userInitiated).async {
                if let image = photoManager.getThumbnail(for: photo.assetIdentifier) {
                    DispatchQueue.main.async {
                        self.thumbnail = image
                        // Save thumbnail data for future use
                        if let data = image.jpegData(compressionQuality: 0.5) {
                            photo.thumbnailData = data
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PhotoThumbnailView(
        photo: Photo(assetIdentifier: "test"),
        photoManager: PhotoManager()
    )
    .frame(width: 100, height: 100)
}

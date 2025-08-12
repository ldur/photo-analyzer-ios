//
//  GalleryView.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Photo.creationDate, order: .reverse) private var photos: [Photo]
    @ObservedObject var photoManager: PhotoManager
    
    private let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if photos.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Photos Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Take your first photo to get started")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 1) {
                            ForEach(photos) { photo in
                                NavigationLink(destination: PhotoDetailView(photo: photo, photoManager: photoManager)) {
                                    PhotoThumbnailView(photo: photo, photoManager: photoManager)
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
            .navigationTitle("Photo Analyzer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add refresh functionality if needed
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    GalleryView(photoManager: PhotoManager())
        .modelContainer(for: Photo.self, inMemory: true)
}

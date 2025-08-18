//
//  MainTabView.swift
//  Photo Analyzer
//
//  Main tab view with bottom navigation
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var photoManager = PhotoManager()
    
    var body: some View {
        TabView {
            // Photos Tab
            PhotosTabView(photoManager: photoManager)
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("Photos")
                }
                .tag(0)
            
            // Labeling Tab
            PhotoLabelingView()
                .tabItem {
                    Image(systemName: "tag.fill")
                    Text("Labeling")
                }
                .tag(1)
            
            // Models Tab
            ModelsTabView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Models")
                }
                .tag(2)
        }
        .accentColor(.white)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Photo.self, inMemory: true)
}

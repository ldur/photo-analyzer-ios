//
//  ContentView.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var photoManager = PhotoManager()
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                if photoManager.isAuthorized && photoManager.cameraAuthorized {
                    GalleryView(photoManager: photoManager)
                } else {
                    permissionView
                }
                
                // Bottom camera button
                if photoManager.isAuthorized && photoManager.cameraAuthorized {
                    cameraButtonView
                }
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraView(
                capturedImage: $capturedImage,
                isShowingCamera: $isShowingCamera,
                photoManager: photoManager
            )
            .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                savePhoto(image)
                capturedImage = nil
            }
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(permissionAlertMessage)
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Photo Analyzer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                // Add settings or profile functionality
            }) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var permissionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.white)
            
            VStack(spacing: 15) {
                Text("Camera Access Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("To take photos and analyze them, please grant camera and photo library permissions.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 15) {
                                                Button(action: requestPermissions) {
                                    HStack {
                                        Image(systemName: "checkmark.shield.fill")
                                        Text("Grant Permissions")
                                    }
                                }
                                .primaryButtonStyle()
                .padding(.horizontal, 40)
                
                Button(action: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }) {
                    Text("Open Settings")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .underline()
                }
            }
            
            Spacer()
        }
    }
    
    private var cameraButtonView: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                CameraButton {
                    isShowingCamera = true
                }
                
                Spacer()
            }
            .padding(.bottom, 30)
        }
    }
    
    private func requestPermissions() {
        Task {
            let cameraPermission = await photoManager.requestCameraPermission()
            let photoPermission = await photoManager.requestPhotoLibraryPermission()
            
            if !cameraPermission || !photoPermission {
                DispatchQueue.main.async {
                    permissionAlertMessage = "Camera and Photo Library access is required to use this app. Please enable them in Settings."
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func savePhoto(_ image: UIImage) {
        Task {
            if let assetIdentifier = await photoManager.savePhotoToAlbum(image) {
                DispatchQueue.main.async {
                    let photo = Photo(assetIdentifier: assetIdentifier)
                    modelContext.insert(photo)
                    
                    // Save thumbnail
                    if let thumbnail = photoManager.getThumbnail(for: assetIdentifier) {
                        photo.thumbnailData = thumbnail.jpegData(compressionQuality: 0.5)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Photo.self, inMemory: true)
}

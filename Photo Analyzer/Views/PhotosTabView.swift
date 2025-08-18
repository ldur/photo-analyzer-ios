//
//  PhotosTabView.swift
//  Photo Analyzer
//
//  Photos tab containing gallery and camera functionality
//

import SwiftUI
import SwiftData

struct PhotosTabView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var photoManager: PhotoManager
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
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
    
    private var permissionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 16) {
                Text("Photo Analyzer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("AI-powered photo analysis")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 20) {
                if !photoManager.isAuthorized {
                    VStack(spacing: 12) {
                        Text("📸 Photo Library Access Required")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Allow access to save and analyze your photos")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("Grant Photo Access") {
                            requestPhotoPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                
                if !photoManager.cameraAuthorized {
                    VStack(spacing: 12) {
                        Text("📷 Camera Access Required")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Allow camera access to take photos")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("Grant Camera Access") {
                            requestCameraPermission()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 60)
    }
    
    private var cameraButtonView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                Spacer()
                
                CameraButton {
                    isShowingCamera = true
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
            .background(Color.black.opacity(0.8))
        }
    }
    
    private func requestPhotoPermission() {
        Task {
            let granted = await photoManager.requestPhotoLibraryPermission()
            if !granted {
                DispatchQueue.main.async {
                    permissionAlertMessage = "Photo library access is required to save and view your photos. Please enable it in Settings."
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func requestCameraPermission() {
        Task {
            let granted = await photoManager.requestCameraPermission()
            if !granted {
                DispatchQueue.main.async {
                    permissionAlertMessage = "Camera access is required to take photos. Please enable it in Settings."
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func savePhoto(_ image: UIImage) {
        Task {
            let assetIdentifier = await photoManager.savePhotoToAlbum(image)
            
            await MainActor.run {
                if let identifier = assetIdentifier {
                    // Create SwiftData Photo record
                    let photo = Photo(assetIdentifier: identifier, creationDate: Date())
                    modelContext.insert(photo)
                    
                    do {
                        try modelContext.save()
                        print("✅ Photo saved successfully to both album and database")
                    } catch {
                        print("❌ Failed to save photo to database: \(error)")
                    }
                } else {
                    print("❌ Failed to save photo to album")
                }
            }
        }
    }
}

#Preview {
    PhotosTabView(photoManager: PhotoManager())
        .modelContainer(for: Photo.self, inMemory: true)
}

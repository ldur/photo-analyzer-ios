//
//  PhotoManager.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import Foundation
import Photos
import UIKit
import AVFoundation

class PhotoManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var cameraAuthorized = false
    @Published var albumCreated = false
    
    private let albumName = "Photo Analyzer"
    private var albumAsset: PHAssetCollection?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        // Check photo library permission
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        DispatchQueue.main.async {
            self.isAuthorized = status == .authorized || status == .limited
        }
        
        // Check camera permission
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async {
            self.cameraAuthorized = cameraStatus == .authorized
        }
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        DispatchQueue.main.async {
            self.isAuthorized = status == .authorized || status == .limited
        }
        return self.isAuthorized
    }
    
    func requestCameraPermission() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        DispatchQueue.main.async {
            self.cameraAuthorized = status
        }
        return status
    }
    
    func createAlbumIfNeeded() async {
        guard !albumCreated else { return }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let existingAlbum = collections.firstObject {
            albumAsset = existingAlbum
            DispatchQueue.main.async {
                self.albumCreated = true
            }
            return
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumName)
            }
            
            let newCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            albumAsset = newCollections.firstObject
            DispatchQueue.main.async {
                self.albumCreated = true
            }
        } catch {
            print("Failed to create album: \(error)")
        }
    }
    
    func savePhotoToAlbum(_ image: UIImage) async -> String? {
        await createAlbumIfNeeded()
        
        var assetIdentifier: String?
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                assetIdentifier = request.placeholderForCreatedAsset?.localIdentifier
                
                if let albumAsset = self.albumAsset {
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: albumAsset)
                    albumChangeRequest?.addAssets([request.placeholderForCreatedAsset!] as NSFastEnumeration)
                }
            }
        } catch {
            print("Failed to save photo: \(error)")
        }
        
        return assetIdentifier
    }
    
    func getThumbnail(for assetIdentifier: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }
        
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .fastFormat
        options.resizeMode = .exact
        
        var thumbnail: UIImage?
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            thumbnail = image
        }
        
        return thumbnail
    }
}

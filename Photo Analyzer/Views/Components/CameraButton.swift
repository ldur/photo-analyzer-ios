//
//  CameraButton.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI

struct CameraButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.black)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CameraButton {
            print("Camera button tapped")
        }
    }
}

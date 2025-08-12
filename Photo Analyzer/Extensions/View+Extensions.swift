//
//  View+Extensions.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.appSecondary)
            .cornerRadius(15)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.appAccent)
            .cornerRadius(25)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(.appAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.appSecondary)
            .cornerRadius(15)
    }
    
    func appBackground() -> some View {
        self
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.3), Color.black]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
    }
}

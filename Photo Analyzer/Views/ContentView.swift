//
//  ContentView.swift
//  Photo Analyzer
//
//  Created by Lasse Durucz on 12/08/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Photo.self, inMemory: true)
}
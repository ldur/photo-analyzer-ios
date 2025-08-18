//
//  LabelManagementView.swift
//  Photo Analyzer
//
//  View for managing labels including cleanup operations
//

import SwiftUI
import SwiftData

struct LabelManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var labelManager = LabelManager()
    
    @Query private var allLabels: [Label]
    
    @State private var labelStats: LabelStatistics?
    @State private var showingCleanupAlert = false
    @State private var cleanupResult: LabelCleanupResult?
    @State private var showingDeleteConfirmation = false
    @State private var isPerformingCleanup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection
                
                statisticsSection
                
                actionButtonsSection
                
                if !allLabels.isEmpty {
                    labelListSection
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Label Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            loadStatistics()
        }
        .alert("Cleanup Complete", isPresented: .constant(cleanupResult != nil)) {
            Button("OK") {
                cleanupResult = nil
                loadStatistics()
            }
        } message: {
            if let result = cleanupResult {
                Text("Merged \(result.mergedLabels) duplicate labels and deleted \(result.deletedLabels) unused labels.")
            }
        }
        .alert("Delete Unused Labels", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteUnusedLabels()
            }
        } message: {
            if let stats = labelStats {
                Text("This will permanently delete \(stats.unusedLabels) unused labels. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "tag.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Label Management")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Organize and clean up your photo labels")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            if let stats = labelStats {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    StatCard(title: "Total Labels", value: "\(stats.totalLabels)", color: .blue)
                    StatCard(title: "Used Labels", value: "\(stats.usedLabels)", color: .green)
                    StatCard(title: "Unused Labels", value: "\(stats.unusedLabels)", color: .red)
                    StatCard(title: "Popular Labels", value: "\(stats.popularLabels)", color: .orange)
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Text("Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                Button(action: performFullCleanup) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Full Cleanup")
                        Spacer()
                        if let stats = labelStats, stats.unusedLabels > 0 {
                            Text("\(stats.unusedLabels + labelManager.findDuplicateLabels(modelContext: modelContext).values.map { $0.count - 1 }.reduce(0, +)) items")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isPerformingCleanup)
                
                Button(action: { showingDeleteConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Unused Labels")
                        Spacer()
                        if let stats = labelStats, stats.unusedLabels > 0 {
                            Text("\(stats.unusedLabels) items")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(labelStats?.unusedLabels == 0 || isPerformingCleanup)
                
                Button(action: loadStatistics) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Statistics")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isPerformingCleanup)
            }
        }
    }
    
    private var labelListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Labels (\(allLabels.count))")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(allLabels.sorted { $0.name < $1.name }, id: \.name) { label in
                        LabelRowView(label: label)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func loadStatistics() {
        labelStats = labelManager.getLabelStatistics(modelContext: modelContext)
    }
    
    private func performFullCleanup() {
        isPerformingCleanup = true
        
        Task {
            let result = labelManager.performLabelCleanup(modelContext: modelContext)
            
            await MainActor.run {
                cleanupResult = result
                isPerformingCleanup = false
            }
        }
    }
    
    private func deleteUnusedLabels() {
        isPerformingCleanup = true
        
        Task {
            let deletedCount = labelManager.deleteUnusedLabels(modelContext: modelContext)
            
            await MainActor.run {
                cleanupResult = LabelCleanupResult(mergedLabels: 0, deletedLabels: deletedCount)
                isPerformingCleanup = false
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

struct LabelRowView: View {
    let label: Label
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label.displayName)
                    .font(.body)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("Photos: \(label.photos.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("Usage: \(label.usageCount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let category = label.category {
                        Text(category.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(4)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            if label.isUnused {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            } else if label.isPopular {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    LabelManagementView()
        .modelContainer(for: [Label.self, Photo.self], inMemory: true)
}

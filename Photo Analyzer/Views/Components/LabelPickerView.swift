//
//  LabelPickerView.swift
//  Photo Analyzer
//
//  Label picker component for selecting existing labels
//

import SwiftUI
import SwiftData

struct LabelPickerView: View {
    let selectedPhoto: Photo?
    let allLabels: [Label]
    let onLabelSelected: (Label) -> Void
    let onCreateNewLabel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var labelToDelete: Label?
    
    var filteredLabels: [Label] {
        if searchText.isEmpty {
            return allLabels
        } else {
            return allLabels.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var availableLabels: [Label] {
        guard let photo = selectedPhoto else { return filteredLabels }
        return filteredLabels.filter { label in
            !photo.labels.contains(where: { $0.name == label.name })
        }
    }
    
    var popularLabels: [Label] {
        return availableLabels.filter { $0.isPopular }.prefix(6).map { $0 }
    }
    
    var categorizedLabels: [Label.Category: [Label]] {
        // Exclude popular labels from categorized labels to avoid duplicates
        let popularLabelNames = Set(popularLabels.map { $0.name })
        let nonPopularLabels = availableLabels.filter { !popularLabelNames.contains($0.name) }
        return Dictionary(grouping: nonPopularLabels) { label in
            Label.Category(rawValue: label.category ?? "other") ?? .other
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBarView
                mainContentView
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Select Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Delete Label", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                labelToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let label = labelToDelete {
                    deleteLabel(label)
                }
                labelToDelete = nil
            }
        } message: {
            if let label = labelToDelete {
                Text("Are you sure you want to delete '\(label.displayName)'? This will remove it from all photos and cannot be undone.")
            }
        }
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search labels...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !popularLabels.isEmpty {
                    popularLabelsSection
                }
                quickAddSection
                categorizedLabelsSection
                createNewLabelButton
            }
            .padding()
        }
    }
    
    private var popularLabelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Labels")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(Array(popularLabels.enumerated()), id: \.offset) { index, label in
                    LabelButton(label: label, onTap: {
                        onLabelSelected(label)
                        dismiss()
                    }, onDelete: { label in
                        confirmDeleteLabel(label)
                    })
                }
            }
        }
    }
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(Array(Array(Label.commonLabels.keys.prefix(12)).sorted().enumerated()), id: \.offset) { index, labelName in
                    if !(selectedPhoto?.hasLabel(labelName) ?? false) && 
                       !allLabels.contains(where: { $0.name == labelName }) {
                        quickAddButton(for: labelName)
                    }
                }
            }
        }
    }
    
    private func quickAddButton(for labelName: String) -> some View {
        Button(action: {
            let category = Label.commonLabels[labelName] ?? .other
            let label = Label(name: labelName, category: category.rawValue, color: category.color)
            onLabelSelected(label)
            dismiss()
        }) {
            Text(labelName.capitalized)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
    
    private var categorizedLabelsSection: some View {
        ForEach(Label.Category.allCases, id: \.rawValue) { category in
            if let labels = categorizedLabels[category], !labels.isEmpty {
                categorySection(for: category, labels: labels)
            }
        }
    }
    
    private func categorySection(for category: Label.Category, labels: [Label]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.displayName)
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                    LabelButton(label: label, onTap: {
                        onLabelSelected(label)
                        dismiss()
                    }, onDelete: { label in
                        confirmDeleteLabel(label)
                    })
                }
            }
        }
    }
    
    private var createNewLabelButton: some View {
        Button(action: {
            dismiss()
            onCreateNewLabel()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Create New Label")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.top)
    }
    
    // MARK: - Helper Functions
    
    private func deleteLabel(_ label: Label) {
        // Remove the label from all photos that have it
        for photo in label.photos {
            photo.removeLabel(label)
        }
        
        // Delete the label from the database
        modelContext.delete(label)
        
        do {
            try modelContext.save()
            print("✅ Deleted label: \(label.displayName)")
        } catch {
            print("❌ Error deleting label: \(error.localizedDescription)")
        }
    }
    
    private func confirmDeleteLabel(_ label: Label) {
        labelToDelete = label
        showingDeleteConfirmation = true
    }
}

struct LabelButton: View {
    let label: Label
    let onTap: () -> Void
    let onDelete: ((Label) -> Void)?
    
    init(label: Label, onTap: @escaping () -> Void, onDelete: ((Label) -> Void)? = nil) {
        self.label = label
        self.onTap = onTap
        self.onDelete = onDelete
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(label.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if label.usageCount > 0 {
                    Text("\(label.usageCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .contextMenu(menuItems: {
            if let onDelete = onDelete {
                Button(action: {
                    onDelete(label)
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Label")
                    }
                }
                .foregroundColor(.red)
            }
        })
    }
}

#Preview {
    LabelPickerView(
        selectedPhoto: nil,
        allLabels: [],
        onLabelSelected: { _ in },
        onCreateNewLabel: { }
    )
}

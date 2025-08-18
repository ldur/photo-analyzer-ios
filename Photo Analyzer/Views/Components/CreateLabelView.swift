//
//  CreateLabelView.swift
//  Photo Analyzer
//
//  Create new label component
//

import SwiftUI

struct CreateLabelView: View {
    @Binding var newLabelName: String
    @Binding var selectedCategory: Label.Category
    let onSave: (String, Label.Category) -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Create New Label")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Add a custom label for your photos")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Form
                VStack(alignment: .leading, spacing: 16) {
                    // Label name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Label Name")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter label name", text: $newLabelName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                    
                    // Category selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Label.Category.allCases, id: \.rawValue) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        onTap: {
                                            selectedCategory = category
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Preview
                    if !newLabelName.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text(newLabelName.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onSave(newLabelName, selectedCategory)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Create Label")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(newLabelName.isEmpty ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(newLabelName.isEmpty)
                    
                    Button(action: {
                        onCancel()
                        dismiss()
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

struct CategoryButton: View {
    let category: Label.Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if isSelected {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(.orange)
                } else {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(.clear)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.orange.opacity(0.3) : Color.clear)
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(8)
        }
    }
}

#Preview {
    CreateLabelView(
        newLabelName: .constant(""),
        selectedCategory: .constant(.object),
        onSave: { _, _ in },
        onCancel: { }
    )
}

//
//  ProfileView.swift
//  Photo Analyzer
//
//  User profile management view
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [Profile]
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var mobileNumber: String = ""
    @State private var isEditing: Bool = false
    @State private var showingSaveConfirmation: Bool = false
    @State private var showingValidationAlert: Bool = false
    @State private var validationMessage: String = ""
    
    private var currentProfile: Profile? {
        profiles.first
    }
    
    private var hasUnsavedChanges: Bool {
        guard let profile = currentProfile else {
            return !name.isEmpty || !email.isEmpty || !mobileNumber.isEmpty
        }
        return name != profile.name || email != profile.email || mobileNumber != profile.mobileNumber
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        profileHeaderView
                        profileFormView
                        if currentProfile != nil {
                            profileInfoView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        if hasUnsavedChanges {
                            showingSaveConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveProfile()
                        }
                        .foregroundColor(.blue)
                        .disabled(!isValidInput)
                    } else if currentProfile != nil {
                        Button("Edit") {
                            isEditing = true
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            loadProfile()
        }
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
        .alert("Unsaved Changes", isPresented: $showingSaveConfirmation) {
            Button("Save", role: .none) {
                saveProfile()
                if !showingValidationAlert {
                    dismiss()
                }
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Do you want to save them before closing?")
        }
    }
    
    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(getInitials())
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 4) {
                Text(currentProfile?.displayName ?? "New User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let profile = currentProfile {
                    Text("Member since \(profile.creationDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var profileFormView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter your full name", text: $name)
                    .textFieldStyle(CustomTextFieldStyle())
                    .disabled(!isEditing && currentProfile != nil)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter your email address", text: $email)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disabled(!isEditing && currentProfile != nil)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Mobile Number")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter your mobile number", text: $mobileNumber)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.phonePad)
                    .disabled(!isEditing && currentProfile != nil)
            }
            
            if currentProfile == nil || isEditing {
                Button(action: {
                    saveProfile()
                }) {
                    HStack {
                        Image(systemName: currentProfile == nil ? "person.badge.plus" : "checkmark.circle.fill")
                        Text(currentProfile == nil ? "Create Profile" : "Save Changes")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidInput ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isValidInput)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var profileInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile Information")
                .font(.headline)
                .foregroundColor(.white)
            
            if let profile = currentProfile {
                VStack(spacing: 12) {
                    InfoRow(title: "Name", value: profile.name, icon: "person.fill")
                    InfoRow(title: "Email", value: profile.email, icon: "envelope.fill")
                    InfoRow(title: "Mobile", value: profile.formattedMobileNumber, icon: "phone.fill")
                    
                    Divider()
                        .background(Color.gray)
                    
                    InfoRow(
                        title: "Last Updated",
                        value: profile.lastModified.formatted(date: .abbreviated, time: .shortened),
                        icon: "clock.fill"
                    )
                    
                    HStack {
                        Image(systemName: profile.isComplete ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(profile.isComplete ? .green : .orange)
                        Text(profile.isComplete ? "Profile Complete" : "Profile Incomplete")
                            .font(.caption)
                            .foregroundColor(profile.isComplete ? .green : .orange)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var isValidInput: Bool {
        let tempProfile = Profile(name: name, email: email, mobileNumber: mobileNumber)
        return !name.isEmpty && !email.isEmpty && !mobileNumber.isEmpty && 
               tempProfile.isValidEmail && tempProfile.isValidMobileNumber
    }
    
    private func loadProfile() {
        if let profile = currentProfile {
            name = profile.name
            email = profile.email
            mobileNumber = profile.mobileNumber
        } else {
            isEditing = true // Auto-enable editing for new profiles
        }
    }
    
    private func saveProfile() {
        guard isValidInput else {
            validationMessage = getValidationMessage()
            showingValidationAlert = true
            return
        }
        
        if let existingProfile = currentProfile {
            existingProfile.updateProfile(name: name, email: email, mobileNumber: mobileNumber)
        } else {
            let newProfile = Profile(name: name, email: email, mobileNumber: mobileNumber)
            modelContext.insert(newProfile)
        }
        
        do {
            try modelContext.save()
            isEditing = false
            print("✅ Profile saved successfully")
        } catch {
            validationMessage = "Failed to save profile: \(error.localizedDescription)"
            showingValidationAlert = true
        }
    }
    
    private func getValidationMessage() -> String {
        if name.isEmpty {
            return "Please enter your name"
        }
        if email.isEmpty {
            return "Please enter your email address"
        }
        if mobileNumber.isEmpty {
            return "Please enter your mobile number"
        }
        
        let tempProfile = Profile(name: name, email: email, mobileNumber: mobileNumber)
        if !tempProfile.isValidEmail {
            return "Please enter a valid email address"
        }
        if !tempProfile.isValidMobileNumber {
            return "Please enter a valid mobile number (10-15 digits)"
        }
        
        return "Please check your input"
    }
    
    private func getInitials() -> String {
        let displayName = currentProfile?.displayName ?? (name.isEmpty ? "User" : name)
        let components = displayName.split(separator: " ")
        if components.count >= 2 {
            let firstInitial = String(components[0].first ?? Character("U"))
            let secondInitial = String(components[1].first ?? Character("U"))
            return firstInitial + secondInitial
        } else if let first = components.first?.first {
            return String(first)
        }
        return "U"
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Profile.self], inMemory: true)
}

//
//  Profile.swift
//  Photo Analyzer
//
//  User profile model for storing personal information
//

import Foundation
import SwiftData

@Model
final class Profile {
    var name: String
    var email: String
    var mobileNumber: String
    var creationDate: Date
    var lastModified: Date
    
    init(name: String, email: String, mobileNumber: String) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.mobileNumber = mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        self.creationDate = Date()
        self.lastModified = Date()
    }
    
    // Update profile information
    func updateProfile(name: String? = nil, email: String? = nil, mobileNumber: String? = nil) {
        if let name = name {
            self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let email = email {
            self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        if let mobileNumber = mobileNumber {
            self.mobileNumber = mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.lastModified = Date()
    }
    
    // Validation helpers
    var isValidEmail: Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    var isValidMobileNumber: Bool {
        let cleanedNumber = mobileNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        return cleanedNumber.count >= 10 && cleanedNumber.count <= 15
    }
    
    var isComplete: Bool {
        return !name.isEmpty && !email.isEmpty && !mobileNumber.isEmpty && isValidEmail && isValidMobileNumber
    }
    
    var displayName: String {
        return name.isEmpty ? "User" : name
    }
    
    var formattedMobileNumber: String {
        let cleanedNumber = mobileNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        // Format US numbers as (XXX) XXX-XXXX
        if cleanedNumber.count == 10 && !cleanedNumber.hasPrefix("+") {
            let areaCode = String(cleanedNumber.prefix(3))
            let firstThree = String(cleanedNumber.dropFirst(3).prefix(3))
            let lastFour = String(cleanedNumber.suffix(4))
            return "(\(areaCode)) \(firstThree)-\(lastFour)"
        }
        
        // Return as-is for international numbers or other formats
        return mobileNumber
    }
}

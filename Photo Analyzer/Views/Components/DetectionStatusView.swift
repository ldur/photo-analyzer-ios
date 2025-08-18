import SwiftUI

// MARK: - Detection Status View
struct DetectionStatusView: View {
    @ObservedObject var simplifiedDetector: SimplifiedObjectDetector
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("AI Detection Status")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Available Models
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Models:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    let models = simplifiedDetector.getAvailableModels()
                    if models.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("No ML models downloaded")
                                .foregroundColor(.orange)
                        }
                        .font(.caption)
                    } else {
                        ForEach(models, id: \.self) { model in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(model)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Detection Method
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detection Method:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(simplifiedDetector.getDetectionStatus())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Recommendations
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if simplifiedDetector.getAvailableModels().isEmpty {
                        Text("• Download ML models for better detection")
                        Text("• Current detection uses basic Vision framework")
                        Text("• Results may be limited")
                    } else {
                        Text("• ML models are available and active")
                        Text("• Detection should be accurate")
                        Text("• Try different objects to test")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DetectionStatusView(simplifiedDetector: SimplifiedObjectDetector())
}


//
//  ViewModeToggle.swift
//  Photo Analyzer
//
//  View mode toggle component for switching between grid and list views
//

import SwiftUI

enum ViewMode: String, CaseIterable {
    case grid = "Grid"
    case list = "List"
    
    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

struct ViewModeToggle: View {
    @Binding var viewMode: ViewMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.rawValue) { mode in
                Button(action: {
                    viewMode = mode
                }) {
                    Image(systemName: mode.icon)
                        .font(.system(size: 16))
                        .foregroundColor(viewMode == mode ? .white : .gray)
                        .frame(width: 32, height: 32)
                        .background(viewMode == mode ? Color.blue : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ViewModeToggle(viewMode: .constant(.grid))
        .preferredColorScheme(.dark)
}

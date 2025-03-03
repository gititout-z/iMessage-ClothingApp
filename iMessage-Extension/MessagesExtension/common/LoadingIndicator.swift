// MARK: - LoadingIndicator.swift
import SwiftUI

struct LoadingIndicator: View {
    let isLoading: Bool
    var text: String?
    var size: CGFloat = 40
    
    var body: some View {
        if isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(size / 40)
                
                if let text = text {
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            EmptyView()
        }
    }
}
// MARK: - ImagePlaceholderView.swift
import SwiftUI

struct ImagePlaceholderView: View {
    let width: CGFloat
    let height: CGFloat
    var icon: String = "photo"
    var backgroundColor: Color = Color.gray.opacity(0.3)
    
    var body: some View {
        Rectangle()
            .fill(backgroundColor)
            .frame(width: width, height: height)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: min(width, height) * 0.3))
                    .foregroundColor(.gray)
            )
    }
}

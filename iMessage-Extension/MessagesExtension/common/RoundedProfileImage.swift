// MARK: - RoundedProfileImage.swift
import SwiftUI

struct RoundedProfileImage: View {
    let url: URL?
    let size: CGFloat
    let placeholder: String
    
    init(url: URL?, size: CGFloat = 50, placeholder: String = "person.circle.fill") {
        self.url = url
        self.size = size
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let url = url {
                // In a real app, use URLImage or AsyncImage
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: placeholder)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(size * 0.25)
                            .foregroundColor(.gray)
                    )
            } else {
                Image(systemName: placeholder)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundColor(.gray)
            }
        }
    }
}
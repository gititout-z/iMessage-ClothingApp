// MARK: - TagView.swift
import SwiftUI

struct TagView: View {
    let text: String
    var backgroundColor: Color = Color.secondary.opacity(0.1)
    var textColor: Color = .primary
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(4)
    }
}

struct TagsView: View {
    let tags: [String]
    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    
    var body: some View {
        if tags.isEmpty {
            EmptyView()
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagView(text: tag)
                }
            }
        }
    }
}
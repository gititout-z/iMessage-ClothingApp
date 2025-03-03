// MARK: - ClothingGridView.swift
import SwiftUI

struct ClothingGridView: View {
    let items: [ClothingItem]
    let onItemSelected: (ClothingItem) -> Void
    
    @State private var selectedItems = Set<String>()
    @State private var isSelectionMode = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(items) { item in
                ClothingItemCell(item: item, isSelected: selectedItems.contains(item.id)) {
                    if isSelectionMode {
                        toggleItemSelection(item)
                    } else {
                        onItemSelected(item)
                    }
                }
                .id(item.id)
            }
        }
        .animation(.default, value: items)
    }
    
    private func toggleItemSelection(_ item: ClothingItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }
}

struct ClothingItemCell: View {
    let item: ClothingItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                // Image with placeholder
                if let imageURL = item.imageURL {
                    // In a real app, use an image loading library
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Text("Image")
                                .foregroundColor(.primary)
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "tshirt")
                                .foregroundColor(.primary)
                        )
                }
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .background(Circle().fill(Color.white))
                        .padding(6)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(radius: 2)
    }
}

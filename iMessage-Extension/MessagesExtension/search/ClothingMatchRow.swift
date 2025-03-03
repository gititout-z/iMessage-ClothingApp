// MARK: - ClothingMatchRow.swift
import SwiftUI

struct ClothingMatchRow: View {
    let match: ClothingMatch
    var isHorizontal: Bool = false
    
    var body: some View {
        if isHorizontal {
            horizontalLayout
        } else {
            verticalLayout
        }
    }
    
    private var horizontalLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            if let imageURL = match.item.imageURL {
                // In a real app, load from URL
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "tshirt")
                            .foregroundColor(.primary)
                    )
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "tshirt")
                            .foregroundColor(.primary)
                    )
                    .cornerRadius(8)
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(match.item.metadata.description)
                    .lineLimit(2)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("\(Int(match.similarityScore * 100))% match")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Text(match.item.metadata.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // User info
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                    
                    Text(match.ownerUsername)
                        .font(.caption)
                    
                    Spacer()
                    
                    Button(action: {
                        // Share action
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var verticalLayout: some View {
        HStack(spacing: 12) {
            // Image
            if let imageURL = match.item.imageURL {
                // In a real app, load from URL
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "tshirt")
                            .foregroundColor(.primary)
                    )
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "tshirt")
                            .foregroundColor(.primary)
                    )
                    .cornerRadius(8)
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(match.item.metadata.description)
                    .lineLimit(2)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("\(Int(match.similarityScore * 100))% match")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    
                    Text(match.item.metadata.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // User info
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                    
                    Text(match.ownerUsername)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button(action: {
                // Share action
            }) {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - UserRow.swift
import SwiftUI

struct UserRow: View {
    let user: User
    @State var isFollowing: Bool
    
    @State private var isLoading = false
    @ObservedObject private var socialManager = SocialManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarURL = user.avatarURL {
                // In a real app, load from URL
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(user.displayName.prefix(1))
                            .font(.headline)
                            .foregroundColor(.primary)
                    )
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Label("\(user.followerCount)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(user.clothingItems?.count ?? 0) items", systemImage: "tshirt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Follow button
            FollowButton(isFollowing: $isFollowing, userId: user.id)
                .disabled(isLoading)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}
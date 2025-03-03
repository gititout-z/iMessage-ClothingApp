// MARK: - ProfileHeader.swift
import SwiftUI

struct ProfileHeader: View {
    let user: User
    let isCurrentUser: Bool
    
    @State private var isFollowing = false
    @ObservedObject private var socialManager = SocialManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar and basic info
            HStack(spacing: 20) {
                // Avatar
                if let avatarURL = user.avatarURL {
                    // In a real app, use an image loading library
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("Avatar")
                                .foregroundColor(.primary)
                        )
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                }
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                    
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let joinDate = formatDate(user.joinDate) {
                        Text("Joined \(joinDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Follow button for other users
                if !isCurrentUser {
                    FollowButton(isFollowing: $isFollowing, userId: user.id)
                }
            }
            .padding(.horizontal)
            
            // Stats
            HStack(spacing: 0) {
                ProfileStat(value: user.clothingItems?.count ?? 0, label: "Items")
                
                Divider()
                    .frame(height: 40)
                
                ProfileStat(value: user.followerCount, label: "Followers")
                
                Divider()
                    .frame(height: 40)
                
                ProfileStat(value: user.followingCount, label: "Following")
            }
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .onAppear {
            if !isCurrentUser {
                checkFollowStatus()
            }
        }
    }
    
    private func checkFollowStatus() {
        socialManager.isFollowing(userId: user.id) { following in
            DispatchQueue.main.async {
                isFollowing = following
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct ProfileStat: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
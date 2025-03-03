// MARK: - FollowButton.swift
import SwiftUI

struct FollowButton: View {
    @Binding var isFollowing: Bool
    let userId: String
    
    @State private var isLoading = false
    @ObservedObject private var socialManager = SocialManager.shared
    
    var body: some View {
        Button(action: toggleFollow) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(width: 80, height: 30)
            } else {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isFollowing ? .secondary : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isFollowing ? Color.secondary.opacity(0.2) : Color.accentColor)
                    .cornerRadius(8)
                    .frame(width: 80, height: 30)
                    .animation(.easeInOut(duration: 0.2), value: isFollowing)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toggleFollow() {
        isLoading = true
        
        if isFollowing {
            // Unfollow
            socialManager.unfollowUser(userId: userId) { success in
                DispatchQueue.main.async {
                    isLoading = false
                    if success {
                        isFollowing = false
                    }
                }
            }
        } else {
            // Follow
            socialManager.followUser(userId: userId) { success in
                DispatchQueue.main.async {
                    isLoading = false
                    if success {
                        isFollowing = true
                    }
                }
            }
        }
    }
}
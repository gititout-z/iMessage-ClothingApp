// MARK: - FollowButton.swift
import SwiftUI

struct FollowButton: View {
    @Binding var isFollowing: Bool
    let userId: String
    
    @State private var isLoading = false
    @ObservedObject private var socialManager = SocialManager.shared
    @State private var showErrorAlert: Bool = false
    @State private var alertErrorMessage: String = ""
    
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
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertErrorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func toggleFollow() {
        isLoading = true
        errorMessage = "" // Clear previous error

        if isFollowing {
            // Unfollow
            socialManager.unfollowUser(userId: userId) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success:
                        isFollowing = false
                    case .failure(let error):
                        alertErrorMessage = error.localizedDescription
                        showErrorAlert = true
                        // isFollowing remains true as the operation failed
                    }
                }
            }
        } else {
            // Follow
            socialManager.followUser(userId: userId) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success:
                        isFollowing = true
                    case .failure(let error):
                        alertErrorMessage = error.localizedDescription
                        showErrorAlert = true
                        // isFollowing remains false as the operation failed
                    }
                }
            }
        }
    }
}
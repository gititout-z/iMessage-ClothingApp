// MARK: - EditProfileView.swift
import SwiftUI
import UIKit

struct EditProfileView: View {
    let user: User
    var onProfileUpdated: (User) -> Void
    
    @State private var username: String
    @State private var displayName: String
    @State private var avatarImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isUsernameValid = true
    @State private var isCheckingUsername = false
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.messageSafeArea) var messageSafeArea
    
    init(user: User, onProfileUpdated: @escaping (User) -> Void) {
        self.user = user
        self.onProfileUpdated = onProfileUpdated
        
        // Initialize state with user properties
        _username = State(initialValue: user.username)
        _displayName = State(initialValue: user.displayName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                ProfilePhotoSection(
                    avatarImage: $avatarImage,
                    showImagePicker: $showImagePicker,
                    existingAvatarURL: user.avatarURL
                )
                
                ProfileInformationSection(
                    username: $username,
                    displayName: $displayName,
                    isCheckingUsername: $isCheckingUsername,
                    isUsernameValid: $isUsernameValid,
                    validateUsername: validateUsername
                )
                
                if let error = errorMessage {
                    Section {
                        ErrorView(errorMessage: error, retryAction: saveProfile)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                }
                .disabled(isLoading || !isUsernameValid || username.isEmpty || displayName.isEmpty)
            )
            .overlay(
                Group {
                    if isLoading {
                        LoadingIndicator(isLoading: true, text: "Saving...")
                            .background(Color.black.opacity(0.4))
                            .edgesIgnoringSafeArea(.all)
                    }
                }
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: sourceType, selectedImage: $avatarImage)
            }
        }
        .padding(EdgeInsets(
            top: messageSafeArea.top,
            leading: messageSafeArea.left,
            bottom: messageSafeArea.bottom,
            trailing: messageSafeArea.right
        ))
    }
    
    private func validateUsername(_ username: String) {
        guard username != user.username else {
            isUsernameValid = true
            return
        }
        
        guard username.count >= 3, username.count <= 30 else {
            isUsernameValid = false
            return
        }
        
        isCheckingUsername = true
        
        // In a real app, check with backend if username is available
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCheckingUsername = false
            isUsernameValid = true // Assume it's valid for this demo
        }
    }
    
    private func saveProfile() {
        guard isUsernameValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Create updated user
        var updatedUser = user
        updatedUser.username = username
        updatedUser.displayName = displayName
        
        // In a real app, you would upload the avatar image if changed
        // and get a URL back to store in the user object
        
        let cloudKitManager = CloudKitManager.shared
        
        cloudKitManager.saveUser(updatedUser) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let savedUser):
                    // Update the auth service with the new user
                    AuthenticationService.shared.currentUser = savedUser
                    
                    // Call the completion handler
                    onProfileUpdated(savedUser)
                    
                    // Dismiss the view
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    Logger.shared.error("Failed to save profile: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Subviews for EditProfileView
private struct ProfilePhotoSection: View {
    @Binding var avatarImage: UIImage?
    @Binding var showImagePicker: Bool
    let existingAvatarURL: URL?

    var body: some View {
        Section(header: Text("Profile Photo")) {
            HStack {
                Spacer()
                Button(action: { showImagePicker = true }) {
                    if let image = avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                    } else if let avatarURL = existingAvatarURL {
                        // Placeholder for network image
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(Text("Avatar").foregroundColor(.primary))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            .padding(.vertical)
        }
    }
}

private struct ProfileInformationSection: View {
    @Binding var username: String
    @Binding var displayName: String
    @Binding var isCheckingUsername: Bool
    @Binding var isUsernameValid: Bool
    let validateUsername: (String) -> Void

    var body: some View {
        Section(header: Text("Profile Information")) {
            TextField("Username", text: $username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: username) { newValue in // SwiftLint might flag `newValue` as unused if not directly used.
                    validateUsername(username) // Pass current binding value
                }

            if isCheckingUsername {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if !isUsernameValid {
                Text("Username is already taken or invalid")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            TextField("Display Name", text: $displayName)
        }
    }
}
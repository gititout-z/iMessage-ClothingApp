// MARK: - AuthenticationView.swift
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    var onAuthenticationSuccess: () -> Void
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Environment value for safe area in iMessage
    @Environment(\.messageSafeArea) var messageSafeArea
    
    var body: some View {
        VStack(spacing: 20) {
            // App Logo/Branding
            Image(systemName: "tshirt.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            
            Text("Clothing App")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Find, share, and discover clothing directly in iMessage")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer().frame(height: 20)
            
            // Sign in button
            SignInWithAppleButton(onCompletion: signInTapped)
                .frame(height: 50)
                .padding(.horizontal)
            
            // Error message
            if let errorMsg = errorMessage ?? authService.authenticationError {
                ErrorView(errorMessage: errorMsg, retryAction: signInTapped)
                    .padding(.top, 8)
            }
            
            // Loading indicator
            if isLoading {
                ProgressView()
                    .padding(.top, 10)
            }
            
            Spacer()
            
            // Privacy info
            Text("By signing in, you agree to our Privacy Policy and Terms of Use.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(EdgeInsets(
            top: messageSafeArea.top,
            leading: messageSafeArea.left,
            bottom: messageSafeArea.bottom,
            trailing: messageSafeArea.right
        ))
        .background(Color(UIColor.systemBackground))
    }
    
    private func signInTapped() {
        isLoading = true
        errorMessage = nil
        
        authService.signInWithApple { success in
            isLoading = false
            
            if success {
                onAuthenticationSuccess()
            } else {
                // Prioritize specific error from authService if available
                if let specificError = authService.authenticationError, !specificError.isEmpty {
                    errorMessage = specificError
                } else {
                    errorMessage = "Sign in failed. Please try again."
                }
            }
        }
    }
}
// MARK: - AuthenticationService.swift
import Foundation
import AuthenticationServices
import CloudKit

class AuthenticationService: NSObject, ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authenticationError: String?
    
    private var authenticationCompletionHandler: ((Bool) -> Void)?
    private let userDefaults = UserDefaults.standard
    private let cloudKitManager = CloudKitManager.shared
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    func checkAuthenticationStatus(completion: @escaping (Bool) -> Void) {
        // Check if we have a user stored in UserDefaults
        if let userData = userDefaults.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
            completion(true)
        } else {
            // Try to restore from Keychain if needed
            restoreAuthentication { success in
                self.isAuthenticated = success
                completion(success)
            }
        }
    }
    
    func signInWithApple(completion: @escaping (Bool) -> Void) {
        self.authenticationCompletionHandler = completion
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func signOut() {
        // Clear user data
        currentUser = nil
        isAuthenticated = false
        
        // Clear from UserDefaults
        userDefaults.removeObject(forKey: "currentUser")
        
        // Clear from Keychain if needed
        // ... keychain cleanup code here ...
        
        // Notify observers
        NotificationCenter.default.post(name: .authenticationChanged, object: false)
    }
    
    // MARK: - Private Methods
    private func restoreAuthentication(completion: @escaping (Bool) -> Void) {
        // Check Keychain or other secure storage for tokens
        // This is a placeholder for actual implementation
        completion(false)
    }
    
    private func saveUserToDefaults(_ user: User) {
        if let encodedData = try? JSONEncoder().encode(user) {
            userDefaults.set(encodedData, forKey: "currentUser")
        }
    }
    
    private func fetchUserFromCloudKit(userIdentifier: String, name: PersonNameComponents?, email: String?, completion: @escaping (User?) -> Void) {
        // First check if user exists
        cloudKitManager.fetchUser(with: userIdentifier) { [weak self] existingUser in
            if let user = existingUser {
                // User exists, return it
                completion(user)
            } else {
                // Create new user
                let newUser = User(
                    id: userIdentifier,
                    username: email?.components(separatedBy: "@").first ?? "user_\(UUID().uuidString.prefix(8))",
                    displayName: [name?.givenName, name?.familyName].compactMap { $0 }.joined(separator: " "),
                    email: email,
                    avatarURL: nil,
                    joinDate: Date()
                )
                
                // Save to CloudKit
                self?.cloudKitManager.saveUser(newUser) { success, savedUser in
                    completion(success ? savedUser : nil)
                }
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            // Fetch or create user in CloudKit
            fetchUserFromCloudKit(userIdentifier: userIdentifier, name: fullName, email: email) { [weak self] user in
                guard let self = self, let user = user else {
                    self?.authenticationCompletionHandler?(false)
                    return
                }
                
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.saveUserToDefaults(user)
                    
                    // Notify observers
                    NotificationCenter.default.post(name: .authenticationChanged, object: true)
                    
                    // Call completion handler
                    self.authenticationCompletionHandler?(true)
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Authentication error: \(error.localizedDescription)")
        self.authenticationError = "Authentication failed. Please try again."
        self.authenticationCompletionHandler?(false)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // This is a placeholder and would need to be implemented properly
        // In a real app, you would need to provide the actual window
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first ?? UIWindow()
    }
}

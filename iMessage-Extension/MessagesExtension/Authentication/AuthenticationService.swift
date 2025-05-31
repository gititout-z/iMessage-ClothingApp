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
    // Removed userDefaults for currentUser storage
    private let cloudKitManager = CloudKitManager.shared

    // Keychain constants
    private let keychainServiceName = "com.example.ClothingApp.AuthService" // Replace with your app's bundle ID or unique service name
    private let keychainAccountName = "currentUserIdentifier"
    
    private override init() {
        super.init()
    }

    // MARK: - Public Methods
    func checkAuthenticationStatus(completion: @escaping (Bool) -> Void) {
        if let userIdentifier = loadIdentifierFromKeychain() {
            // Identifier found, fetch user profile from CloudKit
            fetchUserFromCloudKit(userIdentifier: userIdentifier, name: nil, email: nil) { [weak self] user in
                guard let self = self else {
                    completion(false)
                    return
                }
                if let user = user {
                    DispatchQueue.main.async {
                        self.currentUser = user
                        self.isAuthenticated = true
                        completion(true)
                    }
                } else {
                    // User identifier was in Keychain, but user not found in CloudKit.
                    // This could mean data inconsistency. Clear Keychain for safety.
                    Logger.shared.warning("User identifier found in Keychain, but user data not found in CloudKit. Clearing Keychain.")
                    self.deleteIdentifierFromKeychain()
                    DispatchQueue.main.async {
                        self.isAuthenticated = false
                        completion(false)
                    }
                }
            }
        } else {
            // No identifier in Keychain
            DispatchQueue.main.async {
                self.isAuthenticated = false
                completion(false)
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
        
        // Clear from UserDefaults - No longer needed for currentUser
        // userDefaults.removeObject(forKey: "currentUser")
        
        // Clear from Keychain
        deleteIdentifierFromKeychain()
        
        // Notify observers
        NotificationCenter.default.post(name: .authenticationChanged, object: false)
    }
    
    // MARK: - Private Methods

    // Removed restoreAuthentication as its logic is now in checkAuthenticationStatus with Keychain
    // Removed saveUserToDefaults as we now save identifier to Keychain
    private func saveIdentifierToKeychain(identifier: String) {
        guard let data = identifier.data(using: .utf8) else {
            Logger.shared.error("Keychain: Failed to convert identifier to data.")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: keychainAccountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // Good default
        ]

        // Delete existing item before saving, to simplify (update or add)
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            Logger.shared.info("Keychain: Identifier saved successfully.")
        } else {
            Logger.shared.error("Keychain: Error saving identifier - \(status)")
        }
    }

    private func loadIdentifierFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: keychainAccountName,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data,
               let identifier = String(data: retrievedData, encoding: .utf8) {
                Logger.shared.info("Keychain: Identifier loaded successfully.")
                return identifier
            }
        }
        Logger.shared.info("Keychain: No identifier found or error loading - \(status)")
        return nil
    }

    private func deleteIdentifierFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: keychainAccountName
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            Logger.shared.info("Keychain: Identifier deleted successfully or was not found.")
        } else {
            Logger.shared.error("Keychain: Error deleting identifier - \(status)")
        }
    }
    
    private func fetchUserFromCloudKit(userIdentifier: String, name: PersonNameComponents?, email: String?, completion: @escaping (User?) -> Void) {
        // First check if user exists
        cloudKitManager.fetchUser(with: userIdentifier) { [weak self] result in
            guard let self = self else { completion(nil); return }
            switch result {
            case .success(let user):
                completion(user)
            case .failure(let error):
                // If user not found, and we have name/email, it's a new user sign-up flow.
                // Otherwise, it's an actual error or user genuinely not found during checkAuthenticationStatus.
                if let name = name, let email = email, (error as? CloudKitError) == .recordNotFound || (error as? NSError)?.code == CKError.unknownItem.rawValue {
                    let newUser = User(
                        id: userIdentifier,
                        username: email.components(separatedBy: "@").first ?? "user_\(UUID().uuidString.prefix(8))",
                        displayName: [name.givenName, name.familyName].compactMap { $0 }.joined(separator: " "),
                        email: email,
                        avatarURL: nil,
                        joinDate: Date()
                    )
                    // Save to CloudKit
                    self.cloudKitManager.saveUser(newUser) { saveResult in
                        switch saveResult {
                        case .success(let savedUser):
                            completion(savedUser)
                        case .failure(let saveError):
                            Logger.shared.error("Failed to save new user after initial fetch failed: \(saveError.localizedDescription)")
                            DispatchQueue.main.async {
                                self.authenticationError = saveError.localizedDescription
                            }
                            completion(nil)
                        }
                    }
                } else {
                    // User not found during a check, or other fetch error
                    Logger.shared.error("Failed to fetch user: \(error.localizedDescription)")
                    // Don't set authenticationError here if it's just a checkAuthenticationStatus "not found"
                    // as that's an expected path if user is not in keychain.
                    // Only set if name/email were present (implying sign-up context) or if error is not recordNotFound.
                    if name != nil || email != nil || !((error as? CloudKitError) == .recordNotFound || (error as? NSError)?.code == CKError.unknownItem.rawValue) {
                         DispatchQueue.main.async {
                            self.authenticationError = error.localizedDescription
                         }
                    }
                    completion(nil)
                }
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user // This is the stable user ID from Apple
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            // Save the user identifier to Keychain
            saveIdentifierToKeychain(identifier: userIdentifier)

            // Fetch or create user in CloudKit
            fetchUserFromCloudKit(userIdentifier: userIdentifier, name: fullName, email: email) { [weak self] user in
                guard let self = self, let user = user else {
                    // If user couldn't be fetched/created, consider the sign-in incomplete.
                    // Potentially delete identifier from keychain if CloudKit step is essential for a valid session.
                    self?.deleteIdentifierFromKeychain()
                    self?.authenticationCompletionHandler?(false)
                    return
                }
                
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.isAuthenticated = true
                    // Removed self.saveUserToDefaults(user)
                    
                    // Notify observers
                    NotificationCenter.default.post(name: .Notification.authenticationChanged, object: true)
                    
                    // Call completion handler
                    self.authenticationCompletionHandler?(true)
                }
            }
        } else {
            // Handle other credential types if necessary (e.g., ASPasswordCredential)
            Logger.shared.warning("Received non-Apple ID credential.")
            authenticationCompletionHandler?(false)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Logger.shared.error("Authentication error: \(error.localizedDescription)")
        self.authenticationError = "Authentication failed. Please try again."
        self.authenticationCompletionHandler?(false)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // This is a placeholder and would need to be implemented properly
        // In a real app, you would need to provide the actual window that is currently active.
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // Fallback, though not ideal. Consider logging this scenario.
            return UIWindow()
        }
        return window
    }
}

// Add Notification Name extension if not already present elsewhere
extension Notification.Name {
    static let authenticationChanged = Notification.Name("authenticationChanged")
}

// MARK: - Backend.swift
import Foundation

class Backend {
    static let shared = Backend()
    
    // Services
    let clothingService: ClothingService
    let socialService: SocialService
    let searchService: SearchService
    
    // Network monitoring
    private let networkMonitor = NetworkMonitor.shared
    
    private init() {
        // Initialize services
        clothingService = ClothingService.shared
        socialService = SocialService.shared
        searchService = SearchService.shared
        
        // Start network monitoring
        networkMonitor.startMonitoring()
    }
    
    // Centralized error handling
    func handleNetworkError(_ error: Error) -> Error {
        if !networkMonitor.isConnected {
            return NSError(domain: "Backend", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "No internet connection. Please check your network settings and try again."
            ])
        }
        
        // Handle different error types
        if let cloudKitError = error as? CKError {
            switch cloudKitError.code {
            case .networkUnavailable, .networkFailure:
                return NSError(domain: "Backend", code: 1002, userInfo: [
                    NSLocalizedDescriptionKey: "Network unavailable. Please check your connection and try again."
                ])
            case .serverRejectedRequest:
                return NSError(domain: "Backend", code: 1003, userInfo: [
                    NSLocalizedDescriptionKey: "Server error. Please try again later."
                ])
            case .notAuthenticated:
                // Trigger reauthentication
                AuthenticationService.shared.signOut()
                return NSError(domain: "Backend", code: 1004, userInfo: [
                    NSLocalizedDescriptionKey: "Authentication expired. Please sign in again."
                ])
            default:
                break
            }
        }
        
        // Default error message
        return NSError(domain: "Backend", code: 1000, userInfo: [
            NSLocalizedDescriptionKey: "An unexpected error occurred. Please try again later."
        ])
    }
    
    // Centralized retry logic
    func retry<T>(maxAttempts: Int = 3, delay: TimeInterval = 1.0, task: @escaping (@escaping (Result<T, Error>) -> Void) -> Void, completion: @escaping (Result<T, Error>) -> Void) {
        var attempts = 0
        
        func attempt() {
            attempts += 1
            
            task { result in
                switch result {
                case .success:
                    completion(result)
                case .failure(let error):
                    if attempts < maxAttempts {
                        // Exponential backoff
                        let backoffDelay = delay * pow(2, Double(attempts - 1))
                        DispatchQueue.global().asyncAfter(deadline: .now() + backoffDelay) {
                            attempt()
                        }
                    } else {
                        completion(.failure(self.handleNetworkError(error)))
                    }
                }
            }
        }
        
        attempt()
    }
}
// MARK: - SocialService.swift
import Foundation

class SocialService {
    static let shared = SocialService()
    
    private let cloudKitManager = CloudKitManager.shared
    private let backend = Backend.shared
    
    private init() {}
    
    // Get followers for the current user
    func getFollowers(completion: @escaping (Result<[User], Error>) -> Void) {
        guard let currentUser = AuthenticationService.shared.currentUser else {
            completion(.failure(NSError(domain: "SocialService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        backend.retry { [weak self] retryCompletion in
            guard let self = self else { return }
            
            self.cloudKitManager.fetchFollowers(userId: currentUser.id) { result in
                retryCompletion(result)
            }
        } completion: { result in
            completion(result)
        }
    }
    
    // Get users that the current user is following
    func getFollowing(completion: @escaping (Result<[User], Error>) -> Void) {
        guard let currentUser = AuthenticationService.shared.currentUser else {
            completion(.failure(NSError(domain: "SocialService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        backend.retry { [weak self] retryCompletion in
            guard let self = self else { return }
            
            self.cloudKitManager.fetchFollowing(userId: currentUser.id) { result in
                retryCompletion(result)
            }
        } completion: { result in
            completion(result)
        }
    }
    
    // Get user suggestions
    func getSuggestedUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        guard let currentUser = AuthenticationService.shared.currentUser else {
            completion(.failure(NSError(domain: "SocialService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        backend.retry { [weak self] retryCompletion in
            guard let self = self else { return }
            
            self.cloudKitManager.fetchSuggestedUsers(userId: currentUser.id) { result in
                retryCompletion(result)
            }
        } completion: { result in
            completion(result)
        }
    }
    
    // Follow a user
    func followUser(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = AuthenticationService.shared.currentUser else {
            completion(.failure(NSError(domain: "SocialService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        cloudKitManager.followUser(followerId: currentUser.id, followeeId: userId) { result in
            completion(result)
        }
    }
    
    // Unfollow a user
    func unfollowUser(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = AuthenticationService.shared.currentUser else {
            completion(.failure(NSError(domain: "SocialService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        cloudKitManager.unfollowUser(followerId: currentUser.id, followeeId: userId) { result in
            completion(result)
        }
    }
    
    // Check if the current user is following a specific user
    func isFollowing(userId: String, completion: @escaping (Bool) -> Void) {
        getFollowing { result in
            switch result {
            case .success(let following):
                let isFollowing = following.contains { $0.id == userId }
                completion(isFollowing)
            case .failure:
                completion(false)
            }
        }
    }
}

// MARK: - SocialManager.swift
import Foundation
import CloudKit

class SocialManager: ObservableObject {
    static let shared = SocialManager()
    
    private let cloudKitManager = CloudKitManager.shared
    private let userDefaults = UserDefaults.standard
    private let cacheExpirationTime: TimeInterval = 3600 // 1 hour
    
    private init() {}
    
    // MARK: - Public Methods
    func getFollowers(completion: @escaping (Result<[User], Error>) -> Void) {
        guard let userId = AuthenticationService.shared.currentUser?.id else {
            completion(.failure(NSError(domain: "SocialManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // Check if we have cached followers
        if let cachedFollowers = getCachedFollowers(), !isCacheExpired(key: "followers_timestamp") {
            completion(.success(cachedFollowers))
            return
        }
        
        // Fetch from CloudKit
        cloudKitManager.fetchFollowers(userId: userId) { result in
            switch result {
            case .success(let followers):
                // Cache the followers
                self.cacheFollowers(followers)
                completion(.success(followers))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getFollowing(completion: @escaping (Result<[User], Error>) -> Void) {
        guard let userId = AuthenticationService.shared.currentUser?.id else {
            completion(.failure(NSError(domain: "SocialManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // Check if we have cached following
        if let cachedFollowing = getCachedFollowing(), !isCacheExpired(key: "following_timestamp") {
            completion(.success(cachedFollowing))
            return
        }
        
        // Fetch from CloudKit
        cloudKitManager.fetchFollowing(userId: userId) { result in
            switch result {
            case .success(let following):
                // Cache the following
                self.cacheFollowing(following)
                completion(.success(following))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getSuggestedUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        guard let userId = AuthenticationService.shared.currentUser?.id else {
            completion(.failure(NSError(domain: "SocialManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // Check if we have cached suggestions
        if let cachedSuggestions = getCachedSuggestions(), !isCacheExpired(key: "suggestions_timestamp") {
            completion(.success(cachedSuggestions))
            return
        }
        
        // Fetch from CloudKit
        cloudKitManager.fetchSuggestedUsers(userId: userId) { result in
            switch result {
            case .success(let suggestions):
                // Cache the suggestions
                self.cacheSuggestions(suggestions)
                completion(.success(suggestions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func followUser(userId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = AuthenticationService.shared.currentUser?.id else {
            completion(false)
            return
        }
        
        cloudKitManager.followUser(followerId: currentUserId, followeeId: userId) { success in
            if success {
                // Update local caches
                self.refreshFollowing()
            }
            completion(success)
        }
    }
    
    func unfollowUser(userId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = AuthenticationService.shared.currentUser?.id else {
            completion(false)
            return
        }
        
        cloudKitManager.unfollowUser(followerId: currentUserId, followeeId: userId) { success in
            if success {
                // Update local caches
                self.refreshFollowing()
            }
            completion(success)
        }
    }
    
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
    
    // MARK: - Private Methods
    private func refreshFollowing() {
        // Clear cache and fetch fresh data
        clearCache(key: "following")
        clearCache(key: "following_timestamp")
        
        getFollowing { _ in }
    }
    
    // MARK: - Cache Methods
    private func cacheFollowers(_ followers: [User]) {
        if let data = try? JSONEncoder().encode(followers) {
            userDefaults.set(data, forKey: "followers")
            userDefaults.set(Date().timeIntervalSince1970, forKey: "followers_timestamp")
        }
    }
    
    private func cacheFollowing(_ following: [User]) {
        if let data = try? JSONEncoder().encode(following) {
            userDefaults.set(data, forKey: "following")
            userDefaults.set(Date().timeIntervalSince1970, forKey: "following_timestamp")
        }
    }
    
    private func cacheSuggestions(_ suggestions: [User]) {
        if let data = try? JSONEncoder().encode(suggestions) {
            userDefaults.set(data, forKey: "suggestions")
            userDefaults.set(Date().timeIntervalSince1970, forKey: "suggestions_timestamp")
        }
    }
    
    private func getCachedFollowers() -> [User]? {
        guard let data = userDefaults.data(forKey: "followers") else { return nil }
        return try? JSONDecoder().decode([User].self, from: data)
    }
    
    private func getCachedFollowing() -> [User]? {
        guard let data = userDefaults.data(forKey: "following") else { return nil }
        return try? JSONDecoder().decode([User].self, from: data)
    }
    
    private func getCachedSuggestions() -> [User]? {
        guard let data = userDefaults.data(forKey: "suggestions") else { return nil }
        return try? JSONDecoder().decode([User].self, from: data)
    }
    
    private func isCacheExpired(key: String) -> Bool {
        guard let timestamp = userDefaults.object(forKey: key) as? TimeInterval else {
            return true
        }
        
        let now = Date().timeIntervalSince1970
        return (now - timestamp) > cacheExpirationTime
    }
    
    private func clearCache(key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
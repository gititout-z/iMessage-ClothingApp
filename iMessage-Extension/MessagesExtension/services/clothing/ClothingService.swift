// MARK: - ClothingService.swift
import Foundation
import UIKit

enum ClothingServiceError: Error {
    case uploadFailed
    case invalidImage
    case fetchFailed
    case invalidMetadata
    case userNotAuthenticated
}

class ClothingService {
    static let shared = ClothingService()
    
    private let cloudKitManager = CloudKitManager.shared
    private let imageUploader = ImageUploader.shared
    private let backend = Backend.shared
    
    private init() {}
    
    // Upload a new clothing item
    func uploadItem(image: UIImage, metadata: ClothingMetadata, completion: @escaping (Result<ClothingItem, Error>) -> Void) {
        guard let currentUser = AuthenticationService.shared.currentUser else {
            completion(.failure(ClothingServiceError.userNotAuthenticated))
            return
        }
        
        // First upload the image
        imageUploader.uploadImage(image) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let imageURL):
                // Create clothing item
                let id = UUID().uuidString
                let item = ClothingItem(
                    id: id,
                    ownerId: currentUser.id,
                    ownerUsername: currentUser.username,
                    imageURL: imageURL,
                    thumbnailURL: imageURL, // In a real app, create a thumbnail
                    metadata: metadata,
                    creationDate: Date()
                )
                
                // Save to CloudKit
                self.cloudKitManager.saveClothingItem(item) { success, savedItem in
                    if success, let savedItem = savedItem {
                        completion(.success(savedItem))
                    } else {
                        completion(.failure(ClothingServiceError.uploadFailed))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Get clothing items for a user
    func getItemsForUser(userId: String, completion: @escaping (Result<[ClothingItem], Error>) -> Void) {
        backend.retry { [weak self] retryCompletion in
            guard let self = self else { return }
            
            self.cloudKitManager.fetchClothingItems(for: userId) { result in
                switch result {
                case .success(let items):
                    retryCompletion(.success(items))
                case .failure(let error):
                    retryCompletion(.failure(error))
                }
            }
        } completion: { result in
            completion(result)
        }
    }
    
    // Get a specific clothing item
    func getItem(id: String, completion: @escaping (Result<ClothingItem, Error>) -> Void) {
        backend.retry { [weak self] retryCompletion in
            guard let self = self else { return }
            
            self.cloudKitManager.fetchClothingItem(with: id) { result in
                retryCompletion(result)
            }
        } completion: { result in
            completion(result)
        }
    }
    
    // Delete a clothing item
    func deleteItem(id: String, completion: @escaping (Bool) -> Void) {
        cloudKitManager.deleteClothingItem(with: id) { success in
            completion(success)
        }
    }
}
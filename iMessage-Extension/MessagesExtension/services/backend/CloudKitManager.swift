// MARK: - CloudKitManager.swift
import Foundation
import CloudKit

enum CloudKitError: Error {
    case recordNotFound
    case invalidRecord
    case operationFailed
    case networkError
    case authenticationError
    case unknown
}

class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let publicDB: CKDatabase
    private let privateDB: CKDatabase
    
    private init() {
        // Initialize CloudKit container
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }

    // MARK: - User Operations
    func fetchUser(with id: String, completion: @escaping (Result<User, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: id)
        
        Backend.shared.retry { operationCompletion in
            self.publicDB.fetch(withRecordID: recordID) { record, error in
                if let error = error {
                    // Log original error before it's potentially transformed by Backend.handleNetworkError
                    Logger.shared.error("CloudKitManager: Error fetching user record: \(error.localizedDescription)")
                    operationCompletion(.failure(error))
                } else if let record = record, let user = User.fromRecord(record) {
                    operationCompletion(.success(user))
                } else if record == nil && error == nil {
                    // No record found, and no error - this is a specific case for fetch.
                    // Backend.handleNetworkError might not convert this to a user-friendly "not found"
                    // as it typically expects an actual error object.
                    Logger.shared.info("CloudKitManager: User record not found for ID: \(id)")
                    operationCompletion(.failure(CloudKitError.recordNotFound))
                } else {
                    Logger.shared.error("CloudKitManager: Failed to fetch user or convert record, record: \(String(describing: record)), error: \(String(describing: error))")
                    operationCompletion(.failure(CloudKitError.invalidRecord)) // Or a more generic error
                }
            }
        } completion: { result in
            completion(result) // This result will have gone through Backend.handleNetworkError if it was a failure
        }
    }
    
    func saveUser(_ user: User, completion: @escaping (Result<User, Error>) -> Void) {
        let recordToSave = user.toRecord()
        
        Backend.shared.retry { operationCompletion in
            self.publicDB.save(recordToSave) { savedRecord, error in
                if let error = error {
                    Logger.shared.error("CloudKitManager: Error saving user record: \(error.localizedDescription)")
                    operationCompletion(.failure(error))
                } else if let savedRecord = savedRecord, let savedUser = User.fromRecord(savedRecord) {
                    operationCompletion(.success(savedUser))
                } else {
                    Logger.shared.error("CloudKitManager: Failed to save user or convert saved record. Record: \(String(describing: savedRecord)), Error: \(String(describing: error))")
                    operationCompletion(.failure(CloudKitError.operationFailed)) // Or a more generic error
                }
            }
        } completion: { result in
            completion(result)
        }
    }

    // MARK: - Clothing Operations
    func saveClothingItem(_ item: ClothingItem, completion: @escaping (Bool, ClothingItem?) -> Void) {
        let record = item.toRecord()
        
        publicDB.save(record) { savedRecord, error in
            if let error = error {
                Logger.shared.error("Error saving clothing item: \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            guard let savedRecord = savedRecord,
                  let savedItem = ClothingItem.fromRecord(savedRecord) else {
                completion(false, nil)
                return
            }
            
            completion(true, savedItem)
        }
    }
    
    func fetchClothingItems(for userId: String, completion: @escaping (Result<[ClothingItem], Error>) -> Void) {
        let predicate = NSPredicate(format: "ownerId == %@", userId)
        let query = CKQuery(recordType: "ClothingItem", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        publicDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let items = records.compactMap { ClothingItem.fromRecord($0) }
            completion(.success(items))
        }
    }
    
    func fetchClothingItem(with id: String, completion: @escaping (Result<ClothingItem, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: id)
        
        publicDB.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record, let item = ClothingItem.fromRecord(record) else {
                completion(.failure(CloudKitError.invalidRecord))
                return
            }
            
            completion(.success(item))
        }
    }
    
    func deleteClothingItem(with id: String, completion: @escaping (Bool) -> Void) {
        let recordID = CKRecord.ID(recordName: id)
        
        publicDB.delete(withRecordID: recordID) { _, error in
            completion(error == nil)
        }
    }

    // MARK: - Social Operations
    func fetchFollowers(userId: String, completion: @escaping (Result<[User], Error>) -> Void) {
        let predicate = NSPredicate(format: "followeeId == %@", userId)
        let query = CKQuery(recordType: "Follow", predicate: predicate)
        
        publicDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let followerIds = records.compactMap { $0["followerId"] as? String }
            
            if followerIds.isEmpty {
                completion(.success([]))
                return
            }
            
            // Fetch actual user records
            self.fetchUsers(withIds: followerIds, completion: completion)
        }
    }
    
    func fetchFollowing(userId: String, completion: @escaping (Result<[User], Error>) -> Void) {
        let predicate = NSPredicate(format: "followerId == %@", userId)
        let query = CKQuery(recordType: "Follow", predicate: predicate)
        
        publicDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let followingIds = records.compactMap { $0["followeeId"] as? String }
            
            if followingIds.isEmpty {
                completion(.success([]))
                return
            }
            
            // Fetch actual user records
            self.fetchUsers(withIds: followingIds, completion: completion)
        }
    }
    
    func fetchSuggestedUsers(userId: String, completion: @escaping (Result<[User], Error>) -> Void) {
        // In a real app, this would implement a recommendation algorithm
        // For now, just fetch some random users
        
        let predicate = NSPredicate(format: "recordID != %@", CKRecord.ID(recordName: userId))
        let query = CKQuery(recordType: "User", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "joinDate", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 10
        
        var users: [User] = []
        
        operation.recordFetchedBlock = { record in
            if let user = User.fromRecord(record) {
                users.append(user)
            }
        }
        
        operation.queryCompletionBlock = { cursor, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(users))
        }
        
        publicDB.add(operation)
    }
    
    func followUser(followerId: String, followeeId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: "\(followerId)-\(followeeId)")
        let record = CKRecord(recordType: "Follow", recordID: recordID)
        record["followerId"] = followerId
        record["followeeId"] = followeeId
        record["creationDate"] = Date()
        
        Backend.shared.retry { operationCompletion in
            self.publicDB.save(record) { _, error in
                if let error = error {
                    Logger.shared.error("CloudKitManager: Error saving follow record: \(error.localizedDescription)")
                    operationCompletion(.failure(error))
                } else {
                    operationCompletion(.success(()))
                }
            }
        } completion: { result in
            completion(result)
        }
    }
    
    func unfollowUser(followerId: String, followeeId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: "\(followerId)-\(followeeId)")
        
        Backend.shared.retry { operationCompletion in
            self.publicDB.delete(withRecordID: recordID) { _, error in
                if let error = error {
                    Logger.shared.error("CloudKitManager: Error deleting follow record: \(error.localizedDescription)")
                    operationCompletion(.failure(error))
                } else {
                    operationCompletion(.success(()))
                }
            }
        } completion: { result in
            completion(result)
        }
    }

    // MARK: - Helper Methods
    private func fetchUsers(withIds ids: [String], completion: @escaping (Result<[User], Error>) -> Void) {
        let recordIDs = ids.map { CKRecord.ID(recordName: $0) }
        
        let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
        
        operation.fetchRecordsCompletionBlock = { recordsDict, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let recordsDict = recordsDict else {
                completion(.success([]))
                return
            }
            
            let users = recordsDict.values.compactMap { User.fromRecord($0) }
            completion(.success(users))
        }
        
        publicDB.add(operation)
    }
}

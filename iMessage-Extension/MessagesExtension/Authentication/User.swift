// MARK: - User.swift
import Foundation
import CloudKit

struct User: Identifiable, Codable, Equatable {
    let id: String
    var username: String
    var displayName: String
    var email: String?
    var avatarURL: URL?
    let joinDate: Date
    
    // Optional fields that might be populated from CloudKit
    var clothingItems: [ClothingItem]?
    var followerCount: Int = 0
    var followingCount: Int = 0
    
    // CloudKit record conversion
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "User", recordID: CKRecord.ID(recordName: id))
        record["username"] = username
        record["displayName"] = displayName
        if let email = email {
            record["email"] = email
        }
        if let avatarURLString = avatarURL?.absoluteString {
            record["avatarURL"] = avatarURLString
        }
        record["joinDate"] = joinDate
        record["followerCount"] = followerCount
        record["followingCount"] = followingCount
        
        return record
    }
    
    // Create from CloudKit record
    static func fromRecord(_ record: CKRecord) -> User? {
        guard let id = record.recordID.recordName as String?,
              let username = record["username"] as? String,
              let joinDate = record["joinDate"] as? Date else {
            return nil
        }
        
        let displayName = record["displayName"] as? String ?? username
        let email = record["email"] as? String
        let avatarURLString = record["avatarURL"] as? String
        let avatarURL = avatarURLString != nil ? URL(string: avatarURLString!) : nil
        let followerCount = record["followerCount"] as? Int ?? 0
        let followingCount = record["followingCount"] as? Int ?? 0
        
        return User(
            id: id,
            username: username,
            displayName: displayName,
            email: email,
            avatarURL: avatarURL,
            joinDate: joinDate,
            clothingItems: nil,
            followerCount: followerCount,
            followingCount: followingCount
        )
    }
    
    // Statistics
    func totalClothingItems() -> Int {
        return clothingItems?.count ?? 0
    }
    
    // Equality
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}
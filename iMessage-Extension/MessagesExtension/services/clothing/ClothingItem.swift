// MARK: - ClothingItem.swift
import Foundation
import CloudKit

struct ClothingItem: Identifiable, Codable, Equatable {
    let id: String
    let ownerId: String
    let ownerUsername: String
    let imageURL: URL?
    let thumbnailURL: URL?
    let metadata: ClothingMetadata
    let creationDate: Date
    
    // CloudKit record conversion
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "ClothingItem", recordID: CKRecord.ID(recordName: id))
        record["ownerId"] = ownerId
        record["ownerUsername"] = ownerUsername
        
        if let imageURLString = imageURL?.absoluteString {
            record["imageURL"] = imageURLString
        }
        
        if let thumbnailURLString = thumbnailURL?.absoluteString {
            record["thumbnailURL"] = thumbnailURLString
        }
        
        // Encode metadata
        if let metadataData = try? JSONEncoder().encode(metadata),
           let metadataString = String(data: metadataData, encoding: .utf8) {
            record["metadata"] = metadataString
        }
        
        record["creationDate"] = creationDate
        
        return record
    }
    
    // Create from CloudKit record
    static func fromRecord(_ record: CKRecord) -> ClothingItem? {
        guard let id = record.recordID.recordName as String?,
              let ownerId = record["ownerId"] as? String,
              let ownerUsername = record["ownerUsername"] as? String,
              let creationDate = record["creationDate"] as? Date else {
            return nil
        }
        
        let imageURLString = record["imageURL"] as? String
        let thumbnailURLString = record["thumbnailURL"] as? String
        
        let imageURL = imageURLString != nil ? URL(string: imageURLString!) : nil
        let thumbnailURL = thumbnailURLString != nil ? URL(string: thumbnailURLString!) : nil
        
        // Decode metadata
        var metadata = ClothingMetadata(description: "Unknown", category: "Other")
        if let metadataString = record["metadata"] as? String,
           let metadataData = metadataString.data(using: .utf8),
           let decodedMetadata = try? JSONDecoder().decode(ClothingMetadata.self, from: metadataData) {
            metadata = decodedMetadata
        }
        
        return ClothingItem(
            id: id,
            ownerId: ownerId,
            ownerUsername: ownerUsername,
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            metadata: metadata,
            creationDate: creationDate
        )
    }
    
    // Equality
    static func == (lhs: ClothingItem, rhs: ClothingItem) -> Bool {
        return lhs.id == rhs.id
    }
}
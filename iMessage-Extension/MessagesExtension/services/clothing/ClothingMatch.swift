// MARK: - ClothingMatch.swift
import Foundation

struct ClothingMatch: Identifiable, Codable {
    let id: String
    let item: ClothingItem
    let ownerUsername: String
    let similarityScore: Double
    let matchType: MatchType
    
    enum MatchType: String, Codable {
        case exact
        case similar
        case related
    }
    
    // Convenience initializer
    init(item: ClothingItem, score: Double, type: MatchType = .similar) {
        self.id = UUID().uuidString
        self.item = item
        self.ownerUsername = item.ownerUsername
        self.similarityScore = score
        self.matchType = type
    }
}
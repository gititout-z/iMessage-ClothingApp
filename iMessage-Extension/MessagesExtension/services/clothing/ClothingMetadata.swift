// MARK: - ClothingMetadata.swift
import Foundation

struct ClothingMetadata: Codable, Equatable {
    let description: String
    let category: String
    let subcategory: String?
    let brand: String?
    let tags: [String]?
    let color: String?
    let pattern: String?
    let season: String?
    
    // Convenience initializer with defaults
    init(description: String, category: String, subcategory: String? = nil, brand: String? = nil, tags: [String]? = nil, color: String? = nil, pattern: String? = nil, season: String? = nil) {
        self.description = description
        self.category = category
        self.subcategory = subcategory
        self.brand = brand
        self.tags = tags
        self.color = color
        self.pattern = pattern
        self.season = season
    }
    
    // Equality
    static func == (lhs: ClothingMetadata, rhs: ClothingMetadata) -> Bool {
        return lhs.description == rhs.description &&
               lhs.category == rhs.category &&
               lhs.subcategory == rhs.subcategory &&
               lhs.brand == rhs.brand &&
               lhs.tags == rhs.tags &&
               lhs.color == rhs.color &&
               lhs.pattern == rhs.pattern &&
               lhs.season == rhs.season
    }
}
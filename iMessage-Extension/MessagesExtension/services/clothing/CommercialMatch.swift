// MARK: - CommercialMatch.swift
import Foundation

struct CommercialMatch: Identifiable, Codable {
    let id: String
    let description: String
    let brand: String?
    let price: Double
    let currency: String
    let retailer: String
    let imageURL: URL?
    let purchaseURL: URL?
    let similarityScore: Double
    
    // Convenience initializer
    init(id: String = UUID().uuidString,
         description: String,
         brand: String? = nil,
         price: Double,
         currency: String = "USD",
         retailer: String,
         imageURL: URL? = nil,
         purchaseURL: URL? = nil,
         similarityScore: Double) {
        
        self.id = id
        self.description = description
        self.brand = brand
        self.price = price
        self.currency = currency
        self.retailer = retailer
        self.imageURL = imageURL
        self.purchaseURL = purchaseURL
        self.similarityScore = similarityScore
    }
}
// MARK: - ImageEmbedding.swift
import Foundation

struct ImageEmbedding: Codable {
    let vector: [Float]
    let version: String
    let timestamp: Date
    
    init(vector: [Float], version: String = "1.0") {
        self.vector = vector
        self.version = version
        self.timestamp = Date()
    }
}
// MARK: - ImageAnalysis.swift
import Foundation
import UIKit
import Vision

class ImageAnalysis {
    static let shared = ImageAnalysis()
    
    private let coreML = CoreMLProcessing.shared
    
    private init() {}
    
    // Analyze clothing image to extract metadata
    func analyzeClothing(image: UIImage, completion: @escaping (Result<ClothingMetadata, Error>) -> Void) {
        // We'll run multiple analyses in parallel and combine the results
        let group = DispatchGroup()
        
        var classificationResult: [String: Double]?
        var colorResult: [String: Double]?
        var patternResult: String?
        var extractionError: Error?
        
        // Classify clothing type
        group.enter()
        coreML.classifyClothing(image: image) { result in
            switch result {
            case .success(let classifications):
                classificationResult = classifications
            case .failure(let error):
                extractionError = error
            }
            group.leave()
        }
        
        // Extract color information
        group.enter()
        coreML.extractColorInfo(from: image) { result in
            switch result {
            case .success(let colors):
                colorResult = colors
            case .failure(let error):
                extractionError = error
            }
            group.leave()
        }
        
        // Detect pattern
        group.enter()
        coreML.detectPattern(in: image) { result in
            switch result {
            case .success(let pattern):
                patternResult = pattern
            case .failure(let error):
                extractionError = error
            }
            group.leave()
        }
        
        // Combine all results
        group.notify(queue: .main) {
            if let error = extractionError {
                completion(.failure(error))
                return
            }
            
            // Determine the most likely category
            var category = "Other"
            var subcategory: String? = nil
            
            if let classifications = classificationResult {
                let topCategory = classifications.max(by: { $0.value < $1.value })
                category = topCategory?.key ?? "Other"
                
                // Determine subcategory based on top category
                // In a real app, this would be more sophisticated
                if category == "Tops" {
                    subcategory = "T-Shirt"
                } else if category == "Bottoms" {
                    subcategory = "Jeans"
                }
            }
            
            // Determine the dominant color
            var dominantColor: String? = nil
            
            if let colors = colorResult {
                dominantColor = colors.max(by: { $0.value < $1.value })?.key
            }
            
            // Create metadata
            let metadata = ClothingMetadata(
                description: "\(dominantColor ?? "") \(category.lowercased())",
                category: category,
                subcategory: subcategory,
                brand: nil, // User would enter this
                tags: nil, // User would enter these
                color: dominantColor,
                pattern: patternResult,
                season: nil // User would enter this
            )
            
            completion(.success(metadata))
        }
    }
    
    // Generate a similarity embedding for visual search
    func generateSimilarityEmbedding(for image: UIImage, completion: @escaping (Result<ImageEmbedding, Error>) -> Void) {
        coreML.extractFeatures(from: image) { result in
            switch result {
            case .success(let features):
                let embedding = ImageEmbedding(vector: features)
                completion(.success(embedding))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
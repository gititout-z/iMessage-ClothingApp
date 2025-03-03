// MARK: - ImageCompression.swift
import Foundation
import UIKit

enum ImageCompressionQuality {
    case low
    case medium
    case high
    case custom(CGFloat)
    
    var value: CGFloat {
        switch self {
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.7
        case .custom(let value): return min(max(value, 0.0), 1.0)
        }
    }
}

class ImageCompression {
    static let shared = ImageCompression()
    
    private init() {}
    
    // Compress image with specified quality
    func compressImage(_ image: UIImage, quality: ImageCompressionQuality = .medium) -> Data? {
        return image.jpegData(compressionQuality: quality.value)
    }
    
    // Compress image to target size in KB
    func compressToTargetSize(_ image: UIImage, targetSizeKB: Int) -> Data? {
        var quality: CGFloat = 0.8
        var data = image.jpegData(compressionQuality: quality)
        
        // If already under target size, return
        if let data = data, data.count <= targetSizeKB * 1024 {
            return data
        }
        
        // Binary search for optimal quality
        var minQuality: CGFloat = 0.0
        var maxQuality: CGFloat = 1.0
        
        for _ in 0..<6 { // Usually converges within 6 iterations
            quality = (minQuality + maxQuality) / 2.0
            data = image.jpegData(compressionQuality: quality)
            
            if let data = data {
                if data.count > targetSizeKB * 1024 {
                    maxQuality = quality
                } else {
                    minQuality = quality
                }
            }
        }
        
        return image.jpegData(compressionQuality: minQuality)
    }
    
    // Resize image to maximum dimension while maintaining aspect ratio
    func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        var newSize: CGSize
        
        if originalSize.width > originalSize.height {
            let aspectRatio = originalSize.height / originalSize.width
            newSize = CGSize(width: maxDimension, height: maxDimension * aspectRatio)
        } else {
            let aspectRatio = originalSize.width / originalSize.height
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    // Optimize image for upload
    func optimizeForUpload(_ image: UIImage) -> Data? {
        // Resize to reasonable dimensions
        let resized = resizeImage(image, maxDimension: 1200)
        
        // Compress to target size (500KB is usually good for clothing images)
        return compressToTargetSize(resized, targetSizeKB: 500)
    }
}
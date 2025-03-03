// MARK: - ImageUploader.swift
import Foundation
import UIKit

enum ImageUploaderError: Error {
    case compressionFailed
    case uploadFailed
    case invalidImage
}

class ImageUploader {
    static let shared = ImageUploader()
    
    private init() {}
    
    // Upload an image and get a URL
    func uploadImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        // Compress the image first
        guard let compressedData = compressImage(image) else {
            completion(.failure(ImageUploaderError.compressionFailed))
            return
        }
        
        // In a real app, this would upload to a cloud storage
        // For this implementation, we'll simulate with a delay and fake URL
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            // Generate a fake URL for the image
            let imageId = UUID().uuidString
            guard let fakeURL = URL(string: "https://example.com/images/\(imageId).jpg") else {
                completion(.failure(ImageUploaderError.uploadFailed))
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(fakeURL))
            }
        }
    }
    
    // Compress image for upload
    private func compressImage(_ image: UIImage, quality: CGFloat = 0.7) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
}

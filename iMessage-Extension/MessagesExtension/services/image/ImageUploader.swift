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
        
        Backend.shared.retry { operationCompletion in
            // Simulate actual network request for upload
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { // Shorter delay for individual attempt
                // --- Start of simulated network operation ---
                // Simulate a potential network error randomly (e.g. 25% chance)
                // if Int.random(in: 1...4) == 1 {
                //     Logger.shared.debug("ImageUploader: Simulating network error during upload.")
                //     operationCompletion(.failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)))
                //     return
                // }

                let imageId = UUID().uuidString
                guard let fakeURL = URL(string: "https://example.com/images/\(imageId).jpg") else {
                    Logger.shared.error("ImageUploader: Failed to create fake URL.")
                    operationCompletion(.failure(ImageUploaderError.uploadFailed))
                    return
                }
                Logger.shared.info("ImageUploader: Simulated image upload successful, URL: \(fakeURL.absoluteString)")
                operationCompletion(.success(fakeURL))
                // --- End of simulated network operation ---
            }
        } completion: { result in
            // The result here has been processed by Backend.shared.retry (including error transformation)
            DispatchQueue.main.async { // Ensure final completion is on main thread
                completion(result)
            }
        }
    }
    
    // Compress image for upload
    private func compressImage(_ image: UIImage, quality: CGFloat = 0.7) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
}

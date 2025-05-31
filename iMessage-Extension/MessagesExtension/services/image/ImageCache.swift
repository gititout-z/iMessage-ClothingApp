// MARK: - ImageCache.swift
import Foundation
import UIKit

class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Set up disk cache directory
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("ImageCache")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                Logger.shared.error("Error creating cache directory: \(error.localizedDescription)")
            }
        }
        
        // Configure cache
        cache.name = "com.clothingapp.imagecache"
        cache.countLimit = 100 // Max number of images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    // Get image from cache or fetch it
    func getImage(for url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString as NSString
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: key) {
            completion(cachedImage)
            return
        }
        
        // Check disk cache
        let diskCachePath = cacheDirectory.appendingPathComponent(key.hash.description)
        if fileManager.fileExists(atPath: diskCachePath.path),
           let data = try? Data(contentsOf: diskCachePath),
           let image = UIImage(data: data) {
            // Store in memory cache
            cache.setObject(image, forKey: key)
            completion(image)
            return
        }
        
        // Download the image
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Save to memory cache
            self.cache.setObject(image, forKey: key)
            
            // Save to disk cache
            try? data.write(to: diskCachePath)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    // Store image in cache
    func setImage(_ image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString
        
        // Store in memory cache
        cache.setObject(image, forKey: key)
        
        // Store in disk cache
        let diskCachePath = cacheDirectory.appendingPathComponent(key.hash.description)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: diskCachePath)
        }
    }
    
    // Clear cache
    func clearCache() {
        // Clear memory cache
        cache.removeAllObjects()
        
        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
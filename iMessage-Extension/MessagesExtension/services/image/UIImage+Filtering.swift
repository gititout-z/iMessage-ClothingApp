// MARK: - UIImage+Filtering.swift
import Foundation
import UIKit
import CoreImage

extension UIImage {
    // Apply basic filters to enhance clothing images
    
    // Enhance brightness and contrast
    func enhanceClothing() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.1, forKey: kCIInputContrastKey) // Slightly increase contrast
        filter?.setValue(0.05, forKey: kCIInputBrightnessKey) // Slightly increase brightness
        filter?.setValue(1.1, forKey: kCIInputSaturationKey) // Slightly increase saturation
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    // Remove background (simplified simulation)
    func removeBackground() -> UIImage? {
        // In a real app, this would use Vision/CoreML for segmentation
        // Here, we'll just simulate by creating a circular mask
        
        let size = self.size
        let diameter = min(size.width, size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        // Create circular mask
        let rect = CGRect(
            x: (size.width - diameter) / 2,
            y: (size.height - diameter) / 2,
            width: diameter,
            height: diameter
        )
        context?.addEllipse(in: rect)
        context?.clip()
        
        // Draw the image
        self.draw(in: CGRect(origin: .zero, size: size))
        
        context?.restoreGState()
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // Adjust shadows and highlights
    func adjustShadowsAndHighlights(shadows: CGFloat = 0.3, highlights: CGFloat = -0.3) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        
        let filter = CIFilter(name: "CIHighlightShadowAdjust")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(shadows, forKey: "inputShadowAmount")
        filter?.setValue(highlights, forKey: "inputHighlightAmount")
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    // Sharpen image
    func sharpen(amount: CGFloat = 0.5) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        
        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(amount, forKey: kCIInputSharpnessKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    // Convert to grayscale
    func grayscale() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}
// MARK: - UIImage+Extensions.swift
import UIKit

extension UIImage {
    // Resize image maintaining aspect ratio
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // Resize image to fill while maintaining aspect ratio
    func resizedToFill(size: CGSize) -> UIImage {
        let aspectWidth = size.width / self.size.width
        let aspectHeight = size.height / self.size.height
        let aspectRatio = max(aspectWidth, aspectHeight)
        
        let newSize = CGSize(width: self.size.width * aspectRatio, height: self.size.height * aspectRatio)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let origin = CGPoint(
                x: (size.width - newSize.width) / 2,
                y: (size.height - newSize.height) / 2
            )
            self.draw(in: CGRect(origin: origin, size: newSize))
        }
    }
    
    // Create a thumbnail image
    func thumbnail(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        return resized(to: size)
    }
    
    // Round corners of an image
    func withRoundedCorners(radius: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
            ctx.cgContext.addPath(path.cgPath)
            ctx.cgContext.clip()
            self.draw(in: rect)
        }
    }
    
    // Create a circular image (like for avatars)
    func circular() -> UIImage {
        let diameter = min(size.width, size.height)
        let size = CGSize(width: diameter, height: diameter)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            ctx.cgContext.addEllipse(in: rect)
            ctx.cgContext.clip()
            
            // Center the image in the circular frame
            let origin = CGPoint(
                x: (diameter - self.size.width) / 2,
                y: (diameter - self.size.height) / 2
            )
            self.draw(in: CGRect(origin: origin, size: self.size))
        }
    }
    
    // Get the dominant color of an image
    func dominantColor() -> UIColor? {
        // Resize image for faster processing
        let thumbnail = self.resized(to: CGSize(width: 50, height: 50))
        
        guard let cgImage = thumbnail.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let pixelCount = width * height
        
        var pixelData = [UInt8](repeating: 0, count: pixelCount * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var totalRed = 0
        var totalGreen = 0
        var totalBlue = 0
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            totalRed += Int(pixelData[i])
            totalGreen += Int(pixelData[i + 1])
            totalBlue += Int(pixelData[i + 2])
        }
        
        let averageRed = CGFloat(totalRed) / CGFloat(pixelCount) / 255.0
        let averageGreen = CGFloat(totalGreen) / CGFloat(pixelCount) / 255.0
        let averageBlue = CGFloat(totalBlue) / CGFloat(pixelCount) / 255.0
        
        return UIColor(red: averageRed, green: averageGreen, blue: averageBlue, alpha: 1.0)
    }
}
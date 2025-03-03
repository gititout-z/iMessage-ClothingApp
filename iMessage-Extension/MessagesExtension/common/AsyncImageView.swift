// MARK: - AsyncImageView.swift
import SwiftUI

struct AsyncImageView: View {
    let url: URL?
    var placeholder: String = "photo"
    var contentMode: ContentMode = .fill
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError: Error?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else if isLoading {
                    ProgressView()
                } else {
                    ImagePlaceholderView(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        icon: placeholder
                    )
                }
            }
            .onAppear {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        guard let url = url, image == nil, !isLoading else { return }
        
        isLoading = true
        loadError = nil
        
        ImageCache.shared.getImage(for: url) { image in
            DispatchQueue.main.async {
                isLoading = false
                self.image = image
                
                if image == nil {
                    loadError = NSError(domain: "AsyncImageView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                }
            }
        }
    }
}

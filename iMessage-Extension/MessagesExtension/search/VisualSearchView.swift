// MARK: - VisualSearchView.swift
import SwiftUI

struct VisualSearchView: View {
    var onImageSelected: (UIImage) -> Void
    
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    
    @Environment(\.messageSafeArea) var messageSafeArea
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                // Show selected image with confirm button
                VStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                    
                    if isProcessing {
                        ProgressView("Analyzing image...")
                            .padding()
                    } else {
                        Button(action: {
                            processImage(image)
                        }) {
                            Text("Search with this image")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            selectedImage = nil
                        }) {
                            Text("Choose another image")
                                .foregroundColor(.accentColor)
                                .padding(.vertical, 8)
                        }
                    }
                }
            } else {
                // Show camera and library options
                Spacer()
                
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("Visual Search")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                Text("Take a picture or select an image to find similar clothing items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 30) {
                    Button(action: {
                        sourceType = .camera
                        showImagePicker = true
                    }) {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                            
                            Text("Camera")
                                .font(.caption)
                                .padding(.top, 5)
                        }
                    }
                    
                    Button(action: {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    }) {
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                            
                            Text("Library")
                                .font(.caption)
                                .padding(.top, 5)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(EdgeInsets(
            top: messageSafeArea.top,
            leading: messageSafeArea.left,
            bottom: messageSafeArea.bottom,
            trailing: messageSafeArea.right
        ))
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage)
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        // Simulate image processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isProcessing = false
            onImageSelected(image)
        }
    }
}
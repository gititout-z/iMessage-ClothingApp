// MARK: - ClothingUploadForm.swift
import SwiftUI

struct ClothingUploadForm: View {
    let image: UIImage
    var onCompletion: () -> Void
    
    @State private var description = ""
    @State private var category = "Tops"
    @State private var tags = ""
    @State private var brand = ""
    @State private var isUploading = false
    @State private var uploadProgress: Float = 0.0
    @State private var showShareOptions = false
    @State private var uploadComplete = false
    @State private var errorMessage: String?
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.messageSafeArea) var messageSafeArea
    
    private let categories = ["Tops", "Bottoms", "Outerwear", "Dresses", "Shoes", "Accessories"]
    
    var body: some View {
        NavigationView {
            Form {
                ImageDisplaySection(image: image)
                
                DetailsInputSection(
                    description: $description,
                    category: $category,
                    categories: categories,
                    brand: $brand,
                    tags: $tags
                )
                
                if let error = errorMessage {
                    Section {
                        ErrorView(errorMessage: error, retryAction: uploadClothing)
                    }
                }
                
                ActionButtonsSection(
                    uploadComplete: $uploadComplete,
                    showShareOptions: $showShareOptions,
                    uploadClothingAction: uploadClothing,
                    isUploading: $isUploading,
                    uploadProgress: $uploadProgress,
                    description: $description
                )
            }
            .navigationTitle("Add Clothing Item")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(isUploading),
                trailing: uploadComplete ? Button("Done") {
                    onCompletion()
                    presentationMode.wrappedValue.dismiss()
                } : nil
            )
            .onChange(of: uploadComplete) { complete in
                if complete {
                    // Reset upload progress when complete
                    uploadProgress = 0.0
                }
            }
            .sheet(isPresented: $showShareOptions) {
                Text("Sharing options would appear here")
                    .padding()
            }
        }
        .padding(EdgeInsets(
            top: messageSafeArea.top,
            leading: messageSafeArea.left,
            bottom: messageSafeArea.bottom,
            trailing: messageSafeArea.right
        ))
    }
    
    private func uploadClothing() {
        guard !description.isEmpty else { return }
        
        isUploading = true
        errorMessage = nil
        
        // Parse tags
        let tagList = tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        
        // Create metadata
        let metadata = ClothingMetadata(
            description: description,
            category: category,
            subcategory: nil,
            brand: brand.isEmpty ? nil : brand,
            tags: tagList.isEmpty ? nil : tagList,
            color: nil, // Would be extracted from image in a real app
            pattern: nil, // Would be extracted from image in a real app
            season: nil // Optional
        )
        
        ClothingService.shared.uploadItem(image: image, metadata: metadata) { result in
            DispatchQueue.main.async {
                isUploading = false
                switch result {
                case .success(let uploadedItem):
                    Logger.shared.info("Successfully uploaded item: \(uploadedItem.id)")
                    uploadComplete = true
                    // onCompletion() // Consider if onCompletion should be called here or by the Done button
                case .failure(let error):
                    Logger.shared.error("Failed to upload item: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    uploadComplete = false // Ensure this is reset
                }
            }
        }
    }
}

// MARK: - Subviews for ClothingUploadForm
private struct ImageDisplaySection: View {
    let image: UIImage

    var body: some View {
        Section(header: Text("Image")) {
            HStack {
                Spacer()
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                Spacer()
            }
        }
    }
}

private struct DetailsInputSection: View {
    @Binding var description: String
    @Binding var category: String
    let categories: [String]
    @Binding var brand: String
    @Binding var tags: String

    var body: some View {
        Section(header: Text("Details")) {
            TextField("Description", text: $description)
            
            Picker("Category", selection: $category) {
                ForEach(categories, id: \.self) { categoryName in // Renamed to avoid conflict
                    Text(categoryName).tag(categoryName)
                }
            }

            TextField("Brand (optional)", text: $brand)

            TextField("Tags (comma separated)", text: $tags)
        }
    }
}

private struct ActionButtonsSection: View {
    @Binding var uploadComplete: Bool
    @Binding var showShareOptions: Bool
    let uploadClothingAction: () -> Void
    @Binding var isUploading: Bool
    @Binding var uploadProgress: Float
    @Binding var description: String // For disabling button

    var body: some View {
        Section {
            if uploadComplete {
                Button(action: {
                    showShareOptions = true
                }) {
                    Label("Share in Conversation", systemImage: "square.and.arrow.up")
                }
            } else {
                Button(action: uploadClothingAction) {
                    if isUploading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Uploading... \(Int(uploadProgress * 100))%")
                        }
                    } else {
                        Text("Upload")
                    }
                }
                .disabled(description.isEmpty || isUploading)
            }
        }
    }
}

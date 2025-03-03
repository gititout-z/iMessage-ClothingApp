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
                
                Section(header: Text("Details")) {
                    TextField("Description", text: $description)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    TextField("Brand (optional)", text: $brand)
                    
                    TextField("Tags (comma separated)", text: $tags)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                if uploadComplete {
                    Section {
                        Button(action: {
                            showShareOptions = true
                        }) {
                            Label("Share in Conversation", systemImage: "square.and.arrow.up")
                        }
                    }
                } else {
                    Section {
                        Button(action: uploadClothing) {
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
        
        // Simulate upload progress
        var progress: Float = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.05
            
            if progress >= 1.0 {
                timer.invalidate()
                completeUpload()
            } else {
                uploadProgress = progress
            }
        }
        
        // Simulating image upload and processing
        // In a real app, you would use ImageUploader and ClothingService
        func completeUpload() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isUploading = false
                uploadComplete = true
            }
        }
    }
}

// MARK: - CameraView.swift
import SwiftUI
import UIKit

struct CameraView: View {
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var capturedImage: UIImage?
    @State private var showUploadForm = false
    @State private var isCheckingPermissions = true
    @State private var cameraPermissionGranted = false
    @State private var photoLibraryPermissionGranted = false
    
    @Environment(\.messageSafeArea) var messageSafeArea
    
    var body: some View {
        VStack {
            if isCheckingPermissions {
                ProgressView("Checking permissions...")
            } else {
                if !cameraPermissionGranted && !photoLibraryPermissionGranted {
                    permissionRequestView
                } else {
                    captureOptionsView
                }
            }
        }
        .padding(EdgeInsets(
            top: messageSafeArea.top,
            leading: messageSafeArea.left,
            bottom: messageSafeArea.bottom,
            trailing: messageSafeArea.right
        ))
        .onAppear {
            checkPermissions()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $capturedImage, onImagePicked: { image in
                if let image = image {
                    self.capturedImage = image
                    self.showUploadForm = true
                }
            })
        }
        .sheet(isPresented: $showUploadForm) {
            if let image = capturedImage {
                ClothingUploadForm(image: image) {
                    // Reset state after upload completes
                    self.capturedImage = nil
                }
            }
        }
    }
    
    private var permissionRequestView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This app needs access to your camera and photo library to capture and select clothing items.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                openSettings()
            }) {
                Text("Open Settings")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private var captureOptionsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "tshirt.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Add Clothing Item")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            HStack(spacing: 30) {
                if cameraPermissionGranted {
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
                }
                
                if photoLibraryPermissionGranted {
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
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func checkPermissions() {
        isCheckingPermissions = true
        
        let permissionsHandler = ImagePermissionsHandler()
        
        // Check camera permission
        permissionsHandler.checkCameraPermission { granted in
            // Check photo library permission
            permissionsHandler.checkPhotoLibraryPermission { photoGranted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                    self.photoLibraryPermissionGranted = photoGranted
                    self.isCheckingPermissions = false
                }
            }
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

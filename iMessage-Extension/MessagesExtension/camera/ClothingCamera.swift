// MARK: - ClothingCamera.swift
import SwiftUI
import UIKit
import AVFoundation
import Photos

class ClothingCamera: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isCameraAvailable = false
    @Published var isPhotoLibraryAvailable = false
    
    private var captureSession: AVCaptureSession?
    private var stillImageOutput: AVCapturePhotoOutput?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isCameraAvailable = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isCameraAvailable = granted
                }
            }
        default:
            self.isCameraAvailable = false
        }
        
        // Check photo library permission
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited:
            self.isPhotoLibraryAvailable = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.isPhotoLibraryAvailable = (status == .authorized || status == .limited)
                }
            }
        default:
            self.isPhotoLibraryAvailable = false
        }
    }
    
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            return
        }
        
        if captureSession?.canAddInput(input) == true {
            captureSession?.addInput(input)
        }
        
        stillImageOutput = AVCapturePhotoOutput()
        
        if captureSession?.canAddOutput(stillImageOutput!) == true {
            captureSession?.addOutput(stillImageOutput!)
        }
    }
    
    func startCaptureSession() {
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    func stopCaptureSession() {
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let stillImageOutput = stillImageOutput else {
            completion(nil)
            return
        }
        
        let settings = AVCapturePhotoSettings()
        stillImageOutput.capturePhoto(with: settings, delegate: PhotoCaptureProcessor { image in
            DispatchQueue.main.async {
                self.capturedImage = image
                completion(image)
            }
        })
    }
}

// Photo capture delegate
class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(nil)
            return
        }
        
        completion(image)
    }
}
//
//  CameraController.swift
//  AV Foundation
//
//  Created by Pranjal Satija on 29/5/2017.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import AVFoundation
import UIKit
import Photos

class CameraController: NSObject {
    
    var captureSession: AVCaptureSession?
    
    var currentCameraPosition: CameraPosition?
    
    var frontCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureDeviceInput?
    
    var photoOutput: AVCapturePhotoOutput?
    
    var rearCamera: AVCaptureDevice?
    var rearCameraInput: AVCaptureDeviceInput?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var flashMode = AVCaptureDevice.FlashMode.off
    var photoCaptureCompletionBlock: ((AVCapturePhoto?, Error?) -> Void)?
}

extension CameraController {
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        DispatchQueue(label: "prepare").async {
            do {
                self.createCaptureSession()
                try self.configureCaptureDevices()
                try self.configureDeviceInputs()
                try self.configurePhotoOutput()
            } catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning
            else {
                throw CameraControllerError.captureSessionIsMissing
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
    
    func switchCameras() throws {
        guard let currentCameraPosition = currentCameraPosition,
            let captureSession = self.captureSession,
            captureSession.isRunning else {
                throw CameraControllerError.captureSessionIsMissing
        }
        captureSession.beginConfiguration()
        
        switch currentCameraPosition {
        case .front:
            try switchToRearCamera(captureSession)
        case .rear:
            try switchToFrontCamera(captureSession)
        }
        
        captureSession.commitConfiguration()
    }
    
    func captureImage(completion: @escaping (AVCapturePhoto?, Error?) -> Void) {
        guard let captureSession = captureSession,
            captureSession.isRunning else {
                completion(nil, CameraControllerError.captureSessionIsMissing)
                return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
        self.photoCaptureCompletionBlock = completion
    }
    
    
//MARK: - Private Utils
    
    func createCaptureSession() {
        self.captureSession = AVCaptureSession()
    }
    
    func configureCaptureDevices() throws {
        let cameras: [AVCaptureDevice]
        
        if #available(iOS 13.0, *) {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone, .builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInTripleCamera, .builtInTrueDepthCamera], mediaType: AVMediaType.video, position: .unspecified)
            cameras = session.devices.compactMap { $0 }
        } else {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone, .builtInWideAngleCamera, .builtInTelephotoCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: AVMediaType.video, position: .unspecified)
            cameras = session.devices.compactMap { $0 }
        }

        guard !cameras.isEmpty else { throw CameraControllerError.noCamerasAvailable }
        for camera in cameras {
            if camera.position == .front {
                self.frontCamera = camera
            }
            if camera.position == .back {
                self.rearCamera = camera
                try camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
//                camera.unlockForConfiguration()
                try camera.lockForConfiguration()
            }
        }
    }
    
    func configureDeviceInputs() throws {
        guard let captureSession = self.captureSession
            else {
                throw CameraControllerError.captureSessionIsMissing
        }
        
        if let rearCamera = self.rearCamera {
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
            }
            self.currentCameraPosition = .rear
        } else if let frontCamera = self.frontCamera {
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
            } else {
                throw CameraControllerError.inputsAreInvalid
            }
            self.currentCameraPosition = .front
        } else {
            throw CameraControllerError.noCamerasAvailable
        }
    }
    
    func configurePhotoOutput() throws {
        guard let captureSession = self.captureSession
            else {
                throw CameraControllerError.captureSessionIsMissing
        }
        self.photoOutput = AVCapturePhotoOutput()
        let capturePhotoSettings = [AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])]
        self.photoOutput!.setPreparedPhotoSettingsArray(capturePhotoSettings, completionHandler: nil)
        
        if captureSession.canAddOutput(self.photoOutput!) {
            captureSession.addOutput(self.photoOutput!)
        }
        captureSession.startRunning()
    }
    
    func switchToFrontCamera(_ captureSession: AVCaptureSession) throws {
        guard let rearCameraInput = self.rearCameraInput, captureSession.inputs.contains(rearCameraInput),
            let frontCamera = self.frontCamera
            else {
                throw CameraControllerError.invalidOperation
        }
        
        self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
        captureSession.removeInput(rearCameraInput)
        if captureSession.canAddInput(self.frontCameraInput!) {
            captureSession.addInput(self.frontCameraInput!)
            self.currentCameraPosition = .front
        } else {
            throw CameraControllerError.invalidOperation
        }
    }
    
    func switchToRearCamera(_ captureSession: AVCaptureSession) throws {
        guard let frontCameraInput = self.frontCameraInput, captureSession.inputs.contains(frontCameraInput),
            let rearCamera = self.rearCamera
            else {
                throw CameraControllerError.invalidOperation
        }
        
        self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
        captureSession.removeInput(frontCameraInput)
        
        if captureSession.canAddInput(self.rearCameraInput!) {
            captureSession.addInput(self.rearCameraInput!)
            self.currentCameraPosition = .rear
        } else {
            throw CameraControllerError.invalidOperation
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            self.photoCaptureCompletionBlock?(nil, error)
        } else if photo.fileDataRepresentation() != nil {
            self.photoCaptureCompletionBlock?(photo, nil)
        } else {
            self.photoCaptureCompletionBlock?(nil, CameraControllerError.unknown)
        }
    }
}

extension CameraController {
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    public enum CameraPosition {
        case front
        case rear
    }
}

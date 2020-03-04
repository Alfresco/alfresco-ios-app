//
//  GalleryPhotosModel.swift
//  AlfrescoApp
//
//  Created by Florin Baincescu on 24/02/2020.
//  Copyright © 2020 Alfresco. All rights reserved.
//

import Foundation
import Photos
import UIKit

protocol GalleryPhotosDelegate: class {
    func finishUploadPhotos()
}

@objc class GalleryPhotosModel: NSObject {

    var numberOfPhotosTaken = 100
    var warningText = "To many photos!"
    
    var documentServices: AlfrescoDocumentFolderService
    var uploadToFolder: AlfrescoFolder
    var imagesName: String
    var indexUploadingPhotos: Int
    
    var cameraPhotos: [CameraPhoto]
    weak var delegate: GalleryPhotosDelegate?
  
    @objc init(session: AlfrescoSession, folder: AlfrescoFolder) {
        self.cameraPhotos = []
        self.imagesName = folder.name
        self.indexUploadingPhotos = -1
        self.documentServices = AlfrescoPlaceholderDocumentFolderService.init(session: session)
        self.uploadToFolder = folder
    }

    func uploadPhotosWithContentStream() {
        for idx in 0..<cameraPhotos.count {
            if cameraPhotos[idx].selected == true {
                upload(cameraPhotos[idx].capturePhoto)
            }
        }
    }
    
    func upload(_ photo: AVCapturePhoto) {
        let uploadGroup = DispatchGroup()
    
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        guard let image = UIImage.init(data: imageData) else {
            return
        }
        
        indexUploadingPhotos = indexUploadingPhotos + 1
        let documentName = imagesName + "-" + String(indexUploadingPhotos) + ".jpg"
        let mimetype = "image/jpeg"
        let metadata = Utility.metadataByAddingGPS(toMetadata: photo.metadata)
        
        let contentData = Utility.data(from: image, metadata: metadata, mimetype: mimetype)
        
        let contentFile = AlfrescoContentFile.init(data: contentData, mimeType: mimetype)
        let pathToTempFile = contentFile?.fileUrl.path
        
        let readStream = AlfrescoFileManager.shared()?.inputStream(withFilePath: pathToTempFile)
        let contentStream = AlfrescoContentStream.init(stream: readStream, mimeType: mimetype, length: contentFile?.length ?? 0)
        
        uploadGroup.enter()
        self.documentServices.createDocument(withName: documentName, inParentFolder: self.uploadToFolder, contentStream: contentStream, properties: nil, aspects: nil, completionBlock: { [weak self] (document, error) in
            
            guard let sSelf = self else { return } 
            
            if let document = document {
                RealmSyncManager.shared()?.didUploadNode(document, fromPath: pathToTempFile, to: sSelf.uploadToFolder)
            }
            uploadGroup.leave()
        }) { (bytesTransferred, bytesTotal) in
            
        }
        uploadGroup.notify(queue: .main)  {  [weak self] in
            guard let sSelf = self else { return }
            sSelf.delegate?.finishUploadPhotos()
        }
    }
    
    func shouldTakeAnyPhotos(_ photos: [CameraPhoto]) -> Bool {
        if (photos.count + self.cameraPhotos.count) > 100 {
            return false
        }
        return true
    }
    
    func getImage(from photo: AVCapturePhoto) -> UIImage? {
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error while generating image from photo capture data.")
            return nil
        }
        
        guard let uiImage = UIImage(data: imageData) else {
            print("Unable to generate UIImage from image data.");
            return nil
        }
        
        guard let cgImage = uiImage.cgImage else {
            print("Error generating CGImage")
            return nil
        }
        
        if let deviceOrientationOnCapture = UIInterfaceOrientation.init(rawValue: photo.metadata["UIInterfaceOrientation"] as! Int) {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: deviceOrientationOnCapture.getUIImageOrientationFromDevice())
        }
        
        return nil
    }
    
    func selectAllPhotos() {
        for idx in 0..<cameraPhotos.count {
            cameraPhotos[idx].selected = true
        }
    }
    
    func isAllPhoto(selected: Bool) -> Bool {
        for photo in cameraPhotos {
            if photo.selected != selected {
                return false
            }
        }
        return true
    }
}

extension UIDeviceOrientation {
    func getUIImageOrientationFromDevice() -> UIImage.Orientation {
        
        if UIDevice.current.orientation == .landscapeLeft {
            print("landscapeLeft")
        }
        if UIDevice.current.orientation == .portrait {
            print("portrait")
        }
        
        if UIDevice.current.orientation.isLandscape {
                   print("isLandscape")
               }
        
        switch UIDevice.current.orientation {
        case .portrait:
            return UIImage.Orientation.right
        case .portraitUpsideDown:
            return UIImage.Orientation.left
        case .landscapeLeft:
            return UIImage.Orientation.down
        case .landscapeRight:
            return UIImage.Orientation.up
         default:
            return UIImage.Orientation.right
        }
    }
}

extension UIInterfaceOrientation {
    func getUIImageOrientationFromDevice() -> UIImage.Orientation {
        switch self {
        case .portrait:
            return UIImage.Orientation.right
        case .portraitUpsideDown:
            return UIImage.Orientation.left
        case .landscapeLeft:
            return UIImage.Orientation.down
        case .landscapeRight:
            return UIImage.Orientation.up
         default:
            return UIImage.Orientation.up
        }
    }
    
    func cameraOrientation() -> AVCaptureVideoOrientation {
        switch self {
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
}


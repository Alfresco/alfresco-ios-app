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

protocol GalleryPhotosDelegate {
    func finishUploadPhotos()
}

@objc class GalleryPhotosModel: NSObject {

    var numberOfPhotosTaken = 100
    var warningText = "To many photos!"
    
    var documentServices: AlfrescoDocumentFolderService
    var uploadToFolder: AlfrescoFolder
    var imagesName: String
    var indexUploadingPhotos: Int
    
    var photos: [AVCapturePhoto]
    var selectedPhotos: [Bool]
    var delegate: GalleryPhotosDelegate!
  
    @objc init(session: AlfrescoSession, folder: AlfrescoFolder) {
        self.photos = []
        self.selectedPhotos = []
        self.imagesName = folder.name
        self.indexUploadingPhotos = -1
        self.documentServices = AlfrescoPlaceholderDocumentFolderService.init(session: session)
        self.uploadToFolder = folder
    }
    
    func uploadPhotosWithContentStream() {
        for idx in 0..<photos.count {
            if selectedPhotos[idx] == true {
                upload(photos[idx])
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
            sSelf.delegate.finishUploadPhotos()
        }
    }
    
    func shouldTakeAnyPhotos(_ photos: [AVCapturePhoto]) -> Bool {
        if (photos.count + self.photos.count) > 100 {
            return false
        }
        
        return true
    }
    
    func getImage(from photo: AVCapturePhoto) -> UIImage? {
        if let imageData = photo.fileDataRepresentation() {
            return UIImage.init(data: imageData)
        }
        return nil
    }
    
    func selectAllPhotos() {
        for idx in 0..<selectedPhotos.count {
            selectedPhotos[idx] = true
        }
    }
    
    func isAllPhoto(selected: Bool) -> Bool {
        for ok in selectedPhotos {
            if ok != selected {
                return false
            }
        }
        return true
    }
}

/*******************************************************************************
* Copyright (C) 2005-2014 Alfresco Software Limited.
*
* This file is part of the Alfresco Mobile iOS App.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*  http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
******************************************************************************/

import Foundation
import Photos
import UIKit

protocol GalleryPhotosDelegate: class {
    func finishUploadPhotos()
    func uploading(photo: CameraPhoto, with progress: Float)
    func successUploading(photo: CameraPhoto)
    func errorUploading(photo: CameraPhoto, error: NSError?)
}

@objc class GalleryPhotosModel: NSObject {

    var maxiumNumberOfPhotosTaken = 100
    var tooManyPhotosText = NSLocalizedString("error.camera.to.many.photos", comment: "Too many photos!")
    var okText = NSLocalizedString("OK", comment: "OK")
    var kkAlfrescoErrorCodeDocumentFolder = 600
    var kkAlfrescoErrorCodeDocumentFolderNodeAlreadyExists = 601
    
    var documentServices: AlfrescoDocumentFolderService
    var uploadToFolder: AlfrescoFolder
    var imagesName: String
    var indexUploadingPhotos: Int
    
    var cameraPhotos: [CameraPhoto]
    weak var delegate: GalleryPhotosDelegate?
    
    //MARK: Init
  
    @objc init(session: AlfrescoSession, folder: AlfrescoFolder) {
        self.cameraPhotos = []
        self.imagesName = folder.name
        self.indexUploadingPhotos = 0
        self.documentServices = AlfrescoPlaceholderDocumentFolderService.init(session: session)
        self.uploadToFolder = folder
    }
    
    //MARK: Upload

    func uploadPhotosWithContentStream() {
        indexUploadingPhotos = indexUploadingPhotos + 1
    
        if indexUploadingPhotos == self.cameraPhotos.count {
            delegate?.finishUploadPhotos()
            return
        }
        
        let photo = cameraPhotos[indexUploadingPhotos - 1]
        photo.name = imagesName + "-" + String(indexUploadingPhotos)
        
        upload(photo) { [weak self] (completed) in
            guard let sSelf = self else { return }
            if !completed {
                photo.retryUploading = true
            }
            sSelf.uploadPhotosWithContentStream()
        }
    }
    
    func upload(_ photo: CameraPhoto, finish: @escaping((Bool) -> Void)) {
        
        guard let image = photo.getImage() else {
            return
        }
        
        let documentName = photo.name + ".jpg"
        let mimetype = "image/jpeg"
        var metadata = Utility.metadataByAddingGPS(toMetadata: photo.capturePhoto.metadata)
        metadata = Utility.metadata(byAddingOrientation: photo.orientationMetadata, toMetadata: metadata)
        
        let contentData = Utility.data(from: image, metadata: metadata, mimetype: mimetype)
        
        let contentFile = AlfrescoContentFile.init(data: contentData, mimeType: mimetype)
        let pathToTempFile = contentFile?.fileUrl.path
        
        let readStream = AlfrescoFileManager.shared()?.inputStream(withFilePath: pathToTempFile)
        let contentStream = AlfrescoContentStream.init(stream: readStream, mimeType: mimetype, length: contentFile?.length ?? 0)
        
        self.documentServices.createDocument(withName: documentName, inParentFolder: self.uploadToFolder, contentStream: contentStream, properties: nil, aspects: nil, completionBlock: { [weak self] (document, error) in
            
            guard let sSelf = self else { return }
            if let document = document {
                
                RealmSyncManager.shared()?.didUploadNode(document, fromPath: pathToTempFile, to: sSelf.uploadToFolder)
                photo.uploaded = true
                photo.alfrescoDocument = document
                
                sSelf.delegate?.successUploading(photo: photo)
                
                finish(true)
            } else if let error = error {
                AlfrescoLog.logError(error.localizedDescription)
                
                if sSelf.filenameExistsInParentFolder(error as NSError) {
                    photo.name = photo.name + "_" + String(photo.capturePhoto.timestamp.value)
                    
                    sSelf.upload(photo) { (completed) in
                        if !completed {
                            photo.retryUploading = true
                        }
                        finish(true)
                    }
                } else {
                    sSelf.delegate?.errorUploading(photo: photo, error: error as NSError)
                    finish(false)
                }
            } else {
                sSelf.delegate?.errorUploading(photo: photo, error: nil)
                finish(false)
            }
        }) { [weak self] (bytesTransferred, bytesTotal)  in
            guard let sSelf = self else { return }
            let progress = (bytesTotal == 0) ? Float(1.0) : Float(bytesTransferred) / Float(bytesTotal)
            sSelf.delegate?.uploading(photo: photo, with: progress)
        }
    }
    
    //MARK: Utils
    
    func filenameExistsInParentFolder(_ error: NSError) -> Bool {
        if error.code == self.kkAlfrescoErrorCodeDocumentFolder
            || error.code == self.kkAlfrescoErrorCodeDocumentFolderNodeAlreadyExists {
            return true
        }
        return false
    }
    
    func shouldTakeAnyPhotos(_ photos: [CameraPhoto]) -> Bool {
        if (photos.count + self.cameraPhotos.count) >= maxiumNumberOfPhotosTaken {
            return false
        }
        return true
    }
    
    func selectAllPhotos() {
        for idx in 0..<cameraPhotos.count {
            cameraPhotos[idx].selected = true
        }
    }
    
    func photosRemainingToUploadText() -> String {
        var photos = 0
        for photo in cameraPhotos {
            if photo.selected == true {
                photos = photos + 1
            }
        }
        return String(format: "%d photos from %d remaining.", photos - numberOfUploadedPhoto(), photos)
    }
    
    func numberOfUploadedPhoto() -> Int {
        var photos = 0
        for photo in cameraPhotos {
            if photo.uploaded {
                photos = photos + 1
            }
        }
        return photos
    }
    
    func alfrescoDocuments() -> [AlfrescoDocument] {
        var documents: [AlfrescoDocument] = []
        for photo in cameraPhotos {
            if let document = photo.alfrescoDocument {
                documents.append(document)
            }
        }
        return documents
    }
    
    func retryUploadingPhotos() -> [CameraPhoto] {
        var photos: [CameraPhoto] = []
        for photo in cameraPhotos {
            if photo.retryUploading {
                photos.append(photo)
            }
        }
        return photos
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

/*******************************************************************************
* Copyright (C) 2005-2020 Alfresco Software Limited.
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
    func retryMode()
    func uploading(photo: CameraPhoto, with progress: Float)
    func successUploading(photo: CameraPhoto)
    func errorUploading(photo: CameraPhoto, error: NSError?)
}

@objc class GalleryPhotosModel: NSObject {

    var okText = NSLocalizedString("OK", comment: "OK")
    var yesText = NSLocalizedString("Yes", comment: "YES")
    var noText = NSLocalizedString("No", comment: "NO")
    var uploadButtonText = NSLocalizedString("Upload", comment: "Upload")
    var retryButtonText = NSLocalizedString("Retry", comment: "Retry")
    var cancelButtonText = NSLocalizedString("Cancel", comment: "Cancel")
    var doneButtonText = NSLocalizedString("Done", comment: "Done")
    var selectAllButtonText = NSLocalizedString("gallery.photos.selectAll", comment: "SelectAll")
    var dontUploadButtonText = NSLocalizedString("upload.confirm.dismissal.cancel", comment: "Don't Upload")
    var takeMoreButtonText = NSLocalizedString("gallery.photos.takeMore", comment: "Take more")
    
    var tooManyPhotosText = NSLocalizedString("gallery.camera.tomanyphotos", comment: "Too many photos!")
    var cancelCameraText = NSLocalizedString("gallery.camera.cancelCamera", comment: "Cancel Camera")
    var remainingPhotosText = NSLocalizedString("gallery.photos.remainingPhotos", comment: "remainingPhotos")
    var uploadingPhotosCompleteText = NSLocalizedString("gallery.photos.uploadingPhotosComplete", comment: "uploadingPhotosComplete")
    var unsavedContentTitleText = NSLocalizedString("upload.confirm.dismissal.title", comment: "Unsaved Content")
    var unsavedContentText = NSLocalizedString("upload.confirm.dismissal.message", comment: "Unsaved Content")
    var defaultFilesNameText = NSLocalizedString("gallery.photos.defaultName", comment: "Default Name")
    var defaultFilesPlaceholderNameText = NSLocalizedString("gallery.photos.defaultPlaceholderName", comment: "Default Name")
    var infoNamingPhotosText = NSLocalizedString("gallery.photos.infoNaming", comment: "Info Naming")
    var retryModeText = NSLocalizedString("gallery.photos.retryMode", comment: "Retry Mode")
    var uploadCellularTitleText = NSLocalizedString("gallery.photos.upload.cellular.title", comment: "Cellular Title")
    var uploadCellularDescriptionText = NSLocalizedString("gallery.photos.upload.cellular.description", comment: "Cellular Description")
    var maxiumNumberOfPhotosTaken = 100
   
    var kkAlfrescoErrorCodeDocumentFolder = 600
    var kkAlfrescoErrorCodeDocumentFolderNodeAlreadyExists = 601
    var kkCellularMBSizePermit = 25.0
    
    var retryMode: Bool = false
    var documentServices: AlfrescoDocumentFolderService
    var uploadToFolder: AlfrescoFolder
    var imagesName: String
    var indexUploadingPhotos: Int = -1
    
    @objc var cameraPhotos: [CameraPhoto] = []
    var documents: [AlfrescoDocument] = []
    weak var delegate: GalleryPhotosDelegate?
    var errorUpload: NSError?
    
    //MARK: Init
  
    @objc init(session: AlfrescoSession, folder: AlfrescoFolder) {
        self.imagesName = folder.name
        self.documentServices = AlfrescoPlaceholderDocumentFolderService.init(session: session)
        self.uploadToFolder = folder
    }
    
    func refresh(session: AlfrescoSession) {
        self.documentServices = AlfrescoPlaceholderDocumentFolderService.init(session: session)
    }
    
    //MARK: Upload

    func uploadPhotosWithContentStream() {
        indexUploadingPhotos = indexUploadingPhotos + 1
    
        if indexUploadingPhotos == self.cameraPhotos.count {
            documents.append(contentsOf: alfrescoDocuments())
            if retryUploadingPhotos().count == 0 {
                delegate?.finishUploadPhotos()
            } else {
                resetForRetryModeUpload()
                delegate?.retryMode()
            }
            return
        }
        
        let photo = cameraPhotos[indexUploadingPhotos]
        
        if photo.selected {
            let index = indexOf(cameraPhotoSelected: photo)
            photo.name = defaultNameWithDate(photo: photo, index: index)
            
            upload(photo) { [weak self] (completed) in
                guard let sSelf = self else { return }
                if !completed {
                    photo.retryUploading = true
                }
                sSelf.uploadPhotosWithContentStream()
            }
        } else {
            self.uploadPhotosWithContentStream()
        }
    }
    
    func upload(_ photo: CameraPhoto, finishUpload: @escaping((Bool) -> Void)) {
        
        guard let image = photo.getImage() else {
            return
        }
        
        let documentName = photo.name + ".jpg"
        let mimetype = "image/jpeg"
        
        var metadata = Utility.metadata(byAddingOrientation: photo.orientationMetadata, toMetadata: photo.capturePhoto.metadata)
        if LocationManager.shared()?.usersLocationAuthorisation() == true {
            metadata = Utility.metadataByAddingGPS(toMetadata: metadata)
        }
        
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
                
                finishUpload(true)
                
            } else if let error = error {
                AlfrescoLog.logError(error.localizedDescription)
                sSelf.delegate?.errorUploading(photo: photo, error: error as NSError)
                sSelf.errorUpload = error as NSError
                finishUpload(false)
            } else {
                sSelf.delegate?.errorUploading(photo: photo, error: nil)
                finishUpload(false)
            }
        }) { [weak self] (bytesTransferred, bytesTotal)  in
            guard let sSelf = self else { return }
            let progress = (bytesTotal == 0) ? Float(1.0) : Float(bytesTransferred) / Float(bytesTotal)
            sSelf.delegate?.uploading(photo: photo, with: progress)
        }
    }
    
    func resetForRetryModeUpload() {
        retryMode = true
        indexUploadingPhotos = -1
        cameraPhotos = retryUploadingPhotos()
        for camera in cameraPhotos {
            camera.retryUploading = false
        }
    }
    
    //MARK: Utils
    
    func defaultNameWithDate(photo: CameraPhoto, index: Int) -> String {
        let stringIndex = String(index + 1)
        return imagesName + "_" + Utility.dateFormatter().string(from: Date()) + "_" + stringIndex
    }
    
    func shouldShowAlertCellularUpload() -> Bool {
        if let connectivityManager = ConnectivityManager.shared() {
            if connectivityManager.isOnCellular && photosSelectedSizeMB() >= kkCellularMBSizePermit {
                return true
            }
        }
        return false
    }
    
    func photosSelectedSizeMB() -> Double {
        var size = 0.0
        for photo in cameraPhotos {
            if photo.selected {
                size = size + photo.getSizeMB()
            }
        }
        return size
    }
    
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
        let remainingPhotos = photos - numberOfUploadedOrRetryPhoto()
        if remainingPhotos == 0 {
            return uploadingPhotosCompleteText
        } else {
            return String(format: remainingPhotosText, remainingPhotos, photos)
        }
    }
    
    func indexOf(cameraPhotoSelected: CameraPhoto) -> Int {
        var index = -1
        for camera in cameraPhotos {
            if camera.selected {
                index = index + 1
            }
            if camera == cameraPhotoSelected {
                return index
            }
            
        }
        return index
    }
    
    func numberOfUploadedOrRetryPhoto() -> Int {
        var photos = 0
        for photo in cameraPhotos {
            if photo.uploaded || photo.retryUploading {
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
    
    func selectedPhotos() -> Int {
        var photos = 0
        for photo in cameraPhotos {
            if photo.selected {
                photos = photos + 1
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

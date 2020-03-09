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
        for photo in cameraPhotos {
            if photo.selected == true {
                indexUploadingPhotos = indexUploadingPhotos + 1
                photo.name = imagesName + "-" + String(indexUploadingPhotos)
                upload(photo)
            }
        }
    }
    
    func upload(_ photo: CameraPhoto) {
        let uploadGroup = DispatchGroup()
        
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
        
        uploadGroup.enter()
        self.documentServices.createDocument(withName: documentName, inParentFolder: self.uploadToFolder, contentStream: contentStream, properties: nil, aspects: nil, completionBlock: { [weak self] (document, error) in
            guard let sSelf = self else { return }
            if let document = document {
                RealmSyncManager.shared()?.didUploadNode(document, fromPath: pathToTempFile, to: sSelf.uploadToFolder)
            } else if let error = error {
                AlfrescoLog.logError(error.localizedDescription)
                if sSelf.filenameExistsInParentFolder(error as NSError) {
                    photo.name = photo.name + "_" + String(photo.capturePhoto.timestamp.value)
                    sSelf.upload(photo)
                }
            }
            uploadGroup.leave()
        }) { (bytesTransferred, bytesTotal) in
            
        }
        uploadGroup.notify(queue: .main)  {  [weak self] in
            guard let sSelf = self else { return }
            sSelf.delegate?.finishUploadPhotos()
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
    
    func isAllPhoto(selected: Bool) -> Bool {
        for photo in cameraPhotos {
            if photo.selected != selected {
                return false
            }
        }
        return true
    }
}

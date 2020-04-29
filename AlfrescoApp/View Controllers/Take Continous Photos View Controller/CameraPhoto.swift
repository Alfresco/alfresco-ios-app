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

class CameraPhoto: NSObject {
    var capturePhoto: AVCapturePhoto
    var selected: Bool = true
    var orientationImage: UIImage.Orientation?
    var name: String
    var orientationMetadata: Int
    var alfrescoDocument: AlfrescoDocument?
    var retryUploading: Bool
    var uploaded: Bool
    
    init(capture: AVCapturePhoto, and orientation: UIInterfaceOrientation) {
        self.capturePhoto = capture
        self.selected = true
        self.orientationImage = orientation.imageOrientation()
        self.name = String(capture.timestamp.value)
        self.orientationMetadata = orientation.imagePropertyOrientation()
        retryUploading = false
        uploaded = false
    }
    
    func getSizeMB() -> Double {
        guard let imageData = capturePhoto.fileDataRepresentation() else {
            AlfrescoLog.logError("Error while generating image from photo capture data.")
            return 0.0
        }
        return Double(imageData.count / 1048576)
    }
    
    func getImage() -> UIImage? {
        guard let imageData = capturePhoto.fileDataRepresentation() else {
            AlfrescoLog.logError("Error while generating image from photo capture data.")
            return nil
        }
        guard let uiImage = UIImage(data: imageData) else {
            AlfrescoLog.logError("Unable to generate UIImage from image data.");
            return nil
        }
        guard let cgImage = uiImage.cgImage else {
            AlfrescoLog.logError("Error generating CGImage")
            return nil
        }
        if let orientation = self.orientationImage {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        }
        return nil
    }
}

//
//  CameraPhoto.swift
//  AlfrescoApp
//
//  Created by Florin Baincescu on 03/03/2020.
//  Copyright © 2020 Alfresco. All rights reserved.
//

import Foundation
import Photos
import UIKit

class CameraPhoto: NSObject {
    var capturePhoto: AVCapturePhoto
    var selected: Bool = true
    var orientationImage: UIImage.Orientation?
    
    init(capture: AVCapturePhoto, and orientation: UIInterfaceOrientation) {
        self.capturePhoto = capture
        self.selected = true
        self.orientationImage = orientation.getUIImageOrientationFromDevice()
    }
    
    func getImage() -> UIImage? {
        guard let imageData = capturePhoto.fileDataRepresentation() else {
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
        
        if let orientation = self.orientationImage {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        }
        
        return nil
    }
}

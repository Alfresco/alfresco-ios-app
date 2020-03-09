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

import UIKit
import Photos
import CoreMotion

protocol CameraDelegate: class {
    func closeCamera(savePhotos: Bool, photos: [CameraPhoto])
}

class CameraViewController: UIViewController, ModalRotation {
    
    @IBOutlet fileprivate var captureButton: UIButton!
    @IBOutlet fileprivate var capturePreviewView: UIView!
    @IBOutlet fileprivate var toggleCameraButton: UIButton!
    @IBOutlet fileprivate var toggleFlashButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var orientationLast = UIApplication.shared.statusBarOrientation
    var motionManager: CMMotionManager?
    
    let cameraController = CameraController()
    weak var delegate: CameraDelegate?
    var cameraPhotos: [CameraPhoto] = []
    var model: GalleryPhotosModel!
    
    //MARK: - Cycle Life View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 2
        captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
        
        prepareCamera()
        initializeMotionManager()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] (context) -> Void in
            guard let sSelf = self else { return }
            sSelf.cameraController.changeOrientation(on: sSelf.capturePreviewView)
        }, completion: { (context) -> Void in
            
        })
        super.viewWillTransition(to: size, with: coordinator)
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }
    
    //MARK: - IBActions
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        delegate?.closeCamera(savePhotos: true, photos: cameraPhotos)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        delegate?.closeCamera(savePhotos: false, photos: cameraPhotos)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleFlashButtonPressed(_ sender: UIButton) {
        if cameraController.flashMode == .on {
            cameraController.flashMode = .off
            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash Off Icon"), for: .normal)
        } else {
            cameraController.flashMode = .on
            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash On Icon"), for: .normal)
        }
    }
    
    @IBAction func switchCamerasButtonPressed(_ sender: UIButton) {
        do {
            try cameraController.switchCameras()
        } catch {
            print(error)
        }
        switch cameraController.currentCameraPosition {
        case .some(.front):
            toggleCameraButton.setImage(#imageLiteral(resourceName: "Front Camera Icon"), for: .normal)
        case .some(.rear):
            toggleCameraButton.setImage(#imageLiteral(resourceName: "Rear Camera Icon"), for: .normal)
        case .none:
            return
        }
    }
    
    @IBAction func captureImageButtonPressed(_ sender: UIButton) {
        if model.shouldTakeAnyPhotos(cameraPhotos) == false {
            self.showAlertView()
            return
        }
        captureImage()
    }
    
    //MARK: - Utils
    
    func showAlertView() {
        let alert = UIAlertController(title: "", message: model.tooManyPhotosText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: model.okText, style: .default, handler: { action in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func captureImage() {
        self.capturePreviewView.alpha = 0.4
        cameraController.captureImage { [weak self] (photo, error) in
            guard let sSelf = self else { return }
            guard let photo = photo else {
                print(error ?? "Image capture error")
                return
            }
            sSelf.capturePreviewView.alpha = 1.0
            
            if sSelf.cameraController.currentCameraPosition == .front {
                if sSelf.orientationLast == .landscapeRight {
                    sSelf.cameraPhotos.append(CameraPhoto(capture: photo, and: .landscapeLeft))
                } else if sSelf.orientationLast == .landscapeLeft {
                    sSelf.cameraPhotos.append(CameraPhoto(capture: photo, and: .landscapeRight))
                } else {
                    sSelf.cameraPhotos.append(CameraPhoto(capture: photo, and: sSelf.orientationLast))
                }
            } else {
                sSelf.cameraPhotos.append(CameraPhoto(capture: photo, and: sSelf.orientationLast))
            }
        }
    }
    
    func prepareCamera() {
        cameraController.prepare { [weak self] (error) in
            guard let sSelf = self else { return }
            sSelf.toggleFlashButton.isHidden = !sSelf.cameraController.flashModeDisplay()
            if let error = error {
                print(error)
            }
            do {
                try sSelf.cameraController.displayPreview(on: sSelf.capturePreviewView)
            } catch {
                print(error)
            }
        }
    }
    
    func initializeMotionManager() {
        motionManager = CMMotionManager()
        motionManager?.accelerometerUpdateInterval = 0.2
        motionManager?.gyroUpdateInterval = 0.2
        motionManager?.startAccelerometerUpdates(to: (OperationQueue.current)!, withHandler: { [weak self]
            (accelerometerData, error) -> Void in
            guard let sSelf = self else { return }
            if error == nil {
                sSelf.outputAccelertionData((accelerometerData?.acceleration)!)
            }
            else {
                print("\(error!)")
            }
        })
    }
    
    func outputAccelertionData(_ acceleration: CMAcceleration) {
        var orientationNew: UIInterfaceOrientation
        if acceleration.x >= 0.75 {
            orientationNew = .landscapeLeft
        } else if acceleration.x <= -0.75 {
            orientationNew = .landscapeRight
        } else if acceleration.y <= -0.75 {
            orientationNew = .portrait
        } else if acceleration.y >= 0.75 {
            orientationNew = .portraitUpsideDown
        } else {
            return
        }
        if orientationNew == orientationLast {
            return
        }
        orientationLast = orientationNew
    }
}

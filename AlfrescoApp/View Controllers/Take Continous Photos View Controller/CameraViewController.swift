//
//  CameraViewController.swift
//  TestCamera
//
//  Created by Florin Baincescu on 18/02/2020.
//  Copyright © 2020 Florin Baincescu. All rights reserved.
//

import UIKit
import Photos

protocol CameraDelegate {
    func closeCamera(savePhotos: Bool, photos: [AVCapturePhoto], selectedPhotos: [Bool])
}

class CameraViewController: UIViewController {
    
    @IBOutlet fileprivate var captureButton: UIButton!
    @IBOutlet fileprivate var capturePreviewView: UIView!
    @IBOutlet fileprivate var toggleCameraButton: UIButton!
    @IBOutlet fileprivate var toggleFlashButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    
    let cameraController = CameraController()
    var delegate: CameraDelegate!
    var photos: [AVCapturePhoto] = []
    var selectedPhotos: [Bool] = []
    var model: GalleryPhotosModel!
    
    //MARK: - Cycle Life View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 2
        captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
        
        cameraController.prepare {(error) in
            if let error = error {
                print(error)
            }
            try? self.cameraController.displayPreview(on: self.capturePreviewView)
        }
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) -> Void in
            self.cameraController.changeOrientation(on: self.capturePreviewView)
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
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    //MARK: - IBActions
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        delegate.closeCamera(savePhotos: true, photos: photos, selectedPhotos: selectedPhotos)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        delegate.closeCamera(savePhotos: false, photos: photos, selectedPhotos: selectedPhotos)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleFlash(_ sender: UIButton) {
        if cameraController.flashMode == .on {
            cameraController.flashMode = .off
            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash Off Icon"), for: .normal)
        } else {
            cameraController.flashMode = .on
            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash On Icon"), for: .normal)
        }
    }
    
    @IBAction func switchCameras(_ sender: UIButton) {
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
    
    @IBAction func captureImage(_ sender: UIButton) {
        if model.shouldTakeAnyPhotos(photos) == false {
            self.showAlertView()
            return
        }
        self.capturePreviewView.alpha = 0.4
        cameraController.captureImage { [weak self] (photo, error) in
            guard let sSelf = self else { return }
            guard let photo = photo else {
                print(error ?? "Image capture error")
                return
            }
            sSelf.capturePreviewView.alpha = 1.0
            if sSelf.model.getImage(from: photo) != nil {
                sSelf.photos.append(photo)
                sSelf.selectedPhotos.append(true)
            }
        }
    }
    
    //MARK: - Utils
    
    func showAlertView() {
        let alert = UIAlertController(title: "", message: model.warningText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: true, completion: nil)
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

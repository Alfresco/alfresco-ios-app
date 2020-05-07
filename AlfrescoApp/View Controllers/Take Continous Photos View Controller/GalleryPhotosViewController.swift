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

import UIKit
import AVFoundation

@objc protocol MultiplePhotosUploadDelegate: class {
    func finishUploadGallery(documents: [AlfrescoDocument])
}

@objc class GalleryPhotosViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var nameDefaultFilesLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    
    @IBOutlet weak var selectAllButton: UIButton!
    @IBOutlet weak var takeMorePhotosButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    @IBOutlet weak var collectionViewTraillingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewLeadingConstraint: NSLayoutConstraint!
    
    @objc weak var delegate: MultiplePhotosUploadDelegate?
    @objc var model: GalleryPhotosModel!
    
    var distanceBetweenCells: CGFloat = 20.0
    var cellPerRow: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 4.0 : 3.0
    
    var mbprogressHUD: MBProgressHUD!
    
    //MARK: - Cycle Life View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        model.delegate = self
        
        nameTextField.text = model.imagesName
        nameTextField.placeholder = model.defaultFilesPlaceholderNameText
        nameDefaultFilesLabel.text = model.defaultFilesNameText
  
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        self.title = NSLocalizedString("gallery.photos.uploadTitleScreen", comment: "Upload photos")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: model.uploadButtonText , style: .done, target: self, action: #selector(uploadButtonTapped))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: model.cancelButtonText , style: .plain, target: self, action: #selector(cancelButtonTapped))
        
        selectAllButton.setTitle(model.selectAllButtonText, for: .normal)
        takeMorePhotosButton.setTitle(model.takeMoreButtonText, for: .normal)
        
        make(button: selectAllButton, enable: !model.isAllPhoto(selected: true))
        make(button: navigationItem.rightBarButtonItem, enable: !model.isAllPhoto(selected: false))
        make(button: navigationItem.leftBarButtonItem, enable: true)

        NotificationCenter.default.addObserver(self, selector: #selector(sessionReceived(notification:)),
                                               name: NSNotification.Name.alfrescoSessionReceived, object: nil)
    }
    
    @objc private func sessionReceived(notification: NSNotification) {
        if let session = notification.object as? AlfrescoSession {
            self.model.refresh(session: session)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - IBActions
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        showAlertInfoNaming()
    }
    
    @objc func cancelButtonTapped() {
        if model.cameraPhotos.count == 0 {
            self.dismiss(animated: true, completion: nil)
        } else{
            showAlertCancelUpload()
        }
    }
    
     @objc func uploadButtonTapped() {
        if model.shouldShowAlertCellularUpload() {
            showAlertCellularUpload()
        } else {
            uploadPhotos()
        }
    }
    
    @IBAction func selectButtonTapped(_ sender: Any) {
        model.selectAllPhotos()
        collectionView.reloadData()
        make(button: selectAllButton, enable: false)
        make(button: navigationItem.rightBarButtonItem, enable: !model.isAllPhoto(selected: false))
    }
    
    @IBAction func takeMorePhotosButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "showCamera", sender: nil)
    }
    
    //MARK: - Utils
    
    func showAlertRetryMode() {
        let alert = UIAlertController(title: "", message: model.retryModeText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: model.okText, style: .default, handler: { [weak self]  action in
            guard let sSelf = self else { return }
            if let error = sSelf.model.errorUpload {
                Notifier.notify(withAlfrescoError: error)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlertCancelUpload() {
        let alert = UIAlertController(title: model.unsavedContentTitleText, message: model.unsavedContentText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: model.dontUploadButtonText, style: .cancel, handler: { [weak self] action in
            guard let sSelf = self else { return }
            if sSelf.model.retryMode == true {
                sSelf.delegate?.finishUploadGallery(documents: sSelf.model.documents)
            }
            sSelf.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: model.uploadButtonText, style: .default, handler: { action in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlertCellularUpload() {
        let alert = UIAlertController(title: model.uploadCellularTitleText, message: model.uploadCellularDescriptionText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: model.dontUploadButtonText, style: .cancel, handler: { action in
        }))
        alert.addAction(UIAlertAction(title: model.uploadButtonText, style: .default, handler: { [weak self] action in
            guard let sSelf = self else { return }
            sSelf.uploadPhotos()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlertInfoNaming() {
        let alert = UIAlertController(title: "", message: model.infoNamingPhotosText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: model.okText, style: .default, handler: { action in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func make(button: UIButton, enable: Bool) {
        button.isUserInteractionEnabled = enable
        button.setTitleColor((enable) ? takeMorePhotosButton.tintColor : UIColor.gray, for: .normal)
    }
    
    func make(button: UIBarButtonItem?, enable: Bool) {
        button?.isEnabled = enable
    }
    
    func uploadPhotos() {
        userInteraction(enable: false)
        mbprogressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        mbprogressHUD.mode = .indeterminate
        mbprogressHUD.label.text = model.photosRemainingToUploadText()
        model.uploadPhotosWithContentStream()
    }
    
    func userInteraction(enable: Bool) {
        view.isUserInteractionEnabled = enable
        make(button: navigationItem.rightBarButtonItem, enable: enable)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCamera" {
            let cvc = segue.destination as! CameraViewController
            cvc.delegate = self
            cvc.model = model
        }
    }
}

//MARK: - CameraDelegate

extension GalleryPhotosViewController: CameraDelegate {
    func closeCamera(savePhotos: Bool, photos: [CameraPhoto], model: GalleryPhotosModel) {
        if savePhotos {
            model.cameraPhotos.append(contentsOf: photos)
            collectionView.reloadData()
        }
        make(button: navigationItem.rightBarButtonItem, enable: !model.isAllPhoto(selected: false))
        make(button: selectAllButton, enable: !model.isAllPhoto(selected: true))
    }
}

//MARK: - GalleryPhotos Delegate

extension GalleryPhotosViewController: GalleryPhotosDelegate {

    func uploading(photo: CameraPhoto, with progress: Float) {
        mbprogressHUD.progress = progress
    }
    
    func errorUploading(photo: CameraPhoto, error: NSError?) {
        mbprogressHUD.label.text = model.photosRemainingToUploadText()
    }
    
    func successUploading(photo: CameraPhoto) {
        mbprogressHUD.label.text = model.photosRemainingToUploadText()
        mbprogressHUD.progress = 1.0
    }
    
    func finishUploadPhotos() {
        self.delegate?.finishUploadGallery(documents: model.documents)
        self.dismiss(animated: true, completion: nil)
    }
    
    func retryMode() {
        showAlertRetryMode()
        userInteraction(enable: true)
        mbprogressHUD.hide(animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: model.retryButtonText , style: .done, target: self, action: #selector(uploadButtonTapped))
        collectionView.reloadData()
    }
}

//MARK: - UITextField Delegate

extension GalleryPhotosViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let name = textField.text {
            model.imagesName = name
        }
    }
}

//MARK: - UIColectionView Delegates

extension GalleryPhotosViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.cameraPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell",
                                                      for: indexPath) as! PhotoCollectionViewCell
        cell.photo.image = model.cameraPhotos[indexPath.row].getImage()
        cell.selectedView.isHidden = !model.cameraPhotos[indexPath.row].selected
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        model.cameraPhotos[indexPath.row].selected = !model.cameraPhotos[indexPath.row].selected
        collectionView.reloadItems(at: [indexPath])
        make(button: selectAllButton, enable: !model.isAllPhoto(selected: true))
        make(button: navigationItem.rightBarButtonItem, enable: !model.isAllPhoto(selected: false))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var minSize: CGFloat = 0.0
        if UIDevice.current.userInterfaceIdiom == .pad {
            minSize = max(collectionView.bounds.width, collectionView.bounds.height) - distanceBetweenCells * (cellPerRow + 1)
        } else {
            minSize = min(collectionView.bounds.width, collectionView.bounds.height) - distanceBetweenCells * (cellPerRow + 1)
        }
        let newSize = minSize / cellPerRow

        return CGSize(width: newSize , height: newSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: distanceBetweenCells, left: distanceBetweenCells, bottom: distanceBetweenCells, right: distanceBetweenCells)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return distanceBetweenCells
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return distanceBetweenCells
    }
}

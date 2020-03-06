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
import AVFoundation

@objc class GalleryPhotosViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var selectAllButton: UIButton!
    
    @IBOutlet weak var collectionViewTraillingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewLeadingConstraint: NSLayoutConstraint!
    
    @objc var model: GalleryPhotosModel!
    
    var distanceBetweenCells: CGFloat = 10.0
    var cellPerRow: CGFloat = 3.0
    
    var onlyOnceOpenCamera: Bool = true
    
    var cancelText = NSLocalizedString("gallery.photos.cancel", comment: "Cancel")
    var uploadText = NSLocalizedString("gallery.photos.upload", comment: "Upload")
    var selectAllText = NSLocalizedString("gallery.photos.selectAll", comment: "SelectAll")
    
    //MARK: - Cycle Life View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        model.delegate = self
        
        nameTextField.text = model.imagesName
        
        cancelButton.setTitle(cancelText, for: .normal)
        uploadButton.setTitle(uploadText, for: .normal)
        selectAllButton.setTitle(selectAllText, for: .normal)
        
        make(button: selectAllButton, enable: !model.isAllPhoto(selected: true))
        make(button: uploadButton, enable: !model.isAllPhoto(selected: false))
        make(button: cancelButton, enable: true)
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if onlyOnceOpenCamera {
            self.performSegue(withIdentifier: "showCamera", sender: nil)
            onlyOnceOpenCamera = false
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - IBActions
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func uploadButtonTapped(_ sender: UIButton) {
        self.view.isUserInteractionEnabled = false
        model.uploadPhotosWithContentStream()
    }
    
    @IBAction func selectButtonTapped(_ sender: Any) {
        model.selectAllPhotos()
        collectionView.reloadData()
        make(button: selectAllButton, enable: false)
    }
    
    //MARK: - Utils
    
    func make(button: UIButton, enable: Bool) {
        button.isUserInteractionEnabled = enable
        button.setTitleColor((enable) ? UIColor.blue : UIColor.gray, for: .normal)
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
    
    func closeCamera(savePhotos: Bool, photos: [CameraPhoto]) {
        if savePhotos {
            model.cameraPhotos.append(contentsOf: photos)
            collectionView.reloadData()
        }
        make(button: uploadButton, enable: !model.isAllPhoto(selected: false))
        make(button: selectAllButton, enable: !model.isAllPhoto(selected: true))
    }
}

//MARK: - GalleryPhotos Delegate

extension GalleryPhotosViewController: GalleryPhotosDelegate {
    func finishUploadPhotos() {
        self.dismiss(animated: true, completion: nil)
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
        return model.cameraPhotos.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cameraCell",
                                                          for: indexPath) as! CameraOpenCollectionViewCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell",
                                                          for: indexPath) as! PhotoCollectionViewCell
            cell.photo.image = model.cameraPhotos[indexPath.row - 1].getImage()
            cell.selectedView.isHidden = !model.cameraPhotos[indexPath.row - 1].selected
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.performSegue(withIdentifier: "showCamera", sender: nil)
        } else {
            model.cameraPhotos[indexPath.row - 1].selected = !model.cameraPhotos[indexPath.row - 1].selected
            collectionView.reloadItems(at: [indexPath])
            make(button: selectAllButton, enable: !model.isAllPhoto(selected: true))
            make(button: uploadButton, enable: !model.isAllPhoto(selected: false))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margin = collectionViewLeadingConstraint.constant + collectionViewTraillingConstraint.constant
        let minSize = min(self.view.bounds.width, self.view.bounds.height) - margin
        let yourWidth = minSize / cellPerRow - distanceBetweenCells * cellPerRow - distanceBetweenCells
        let yourHeight = yourWidth

        return CGSize(width: yourWidth, height: yourHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return distanceBetweenCells
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return distanceBetweenCells
    }
}

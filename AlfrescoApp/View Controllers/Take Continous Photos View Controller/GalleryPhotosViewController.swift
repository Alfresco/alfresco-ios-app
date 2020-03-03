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
    
    @objc var model: GalleryPhotosModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.text = model.imagesName
        
        make(button: selectAllButton, enable: !model.isAllPhoto(selected: true))
        make(button: uploadButton, enable: !model.isAllPhoto(selected: false))
        
        model.delegate = self
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.performSegue(withIdentifier: "showCamera", sender: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - IBActions
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func uploadButtonTapped(_ sender: UIButton) {
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
        button.tintColor = (enable) ? UIColor.blue : UIColor.gray
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

extension GalleryPhotosViewController: CameraDelegate {
    
    func closeCamera(savePhotos: Bool, photos: [AVCapturePhoto], selectedPhotos: [Bool]) {
        if savePhotos {
            model.photos.append(contentsOf: photos)
            model.selectedPhotos.append(contentsOf: selectedPhotos)
            collectionView.reloadData()
        }
        make(button: uploadButton, enable: savePhotos)
        make(button: selectAllButton, enable: !model.isAllPhoto(selected: true))
    }
}

extension GalleryPhotosViewController: GalleryPhotosDelegate {
    func finishUploadPhotos() {
        self.dismiss(animated: true, completion: nil)
    }
}

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

extension GalleryPhotosViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.photos.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cameraCell",
                                                          for: indexPath) as! CameraOpenCollectionViewCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell",
                                                          for: indexPath) as! PhotoCollectionViewCell
            cell.photo.image = model.getImage(from: model.photos[indexPath.row - 1])
            cell.selectedView.isHidden = !model.selectedPhotos[indexPath.row - 1]
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.performSegue(withIdentifier: "showCamera", sender: nil)
        } else {
            model.selectedPhotos[indexPath.row - 1] = !model.selectedPhotos[indexPath.row - 1]
            collectionView.reloadItems(at: [indexPath])
            make(button: selectAllButton, enable: !model.isAllPhoto(selected: true))
            make(button: uploadButton, enable: !model.isAllPhoto(selected: false))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = collectionView.bounds.width/3.0 - 20
        let yourHeight = yourWidth

        return CGSize(width: yourWidth, height: yourHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

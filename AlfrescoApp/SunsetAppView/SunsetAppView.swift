//
//  SunsetAppView.swift
//  AlfrescoApp
//
//  Created by global on 23/03/22.
//  Copyright © 2022 Alfresco. All rights reserved.
//

import UIKit

class SunsetAppView: UIView {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupLocalization()
    }
    
    func setupLocalization() {
        if SunsetAppService().isAppReachedToEndOfLife() {
            messageLabel.text = NSLocalizedString("sunsetAppView.afterEOL.message", comment: "")
        } else {
            messageLabel.text = NSLocalizedString("sunsetAppView.beforeEOL.message", comment: "")
        }
        titleLabel.text = NSLocalizedString("sunsetAppView.title", comment: "")
        continueButton.setTitle(NSLocalizedString("sunsetAppView.takeMeThere.ButtonTitle", comment: ""), for: .normal)
        dismissButton.setTitle(NSLocalizedString("sunsetAppView.dismiss.ButtonTitle", comment: ""), for: .normal)
    }
    
    @IBAction func continueButtonAction(_ sender: Any) {
        SunsetAppService().redirectUserToOpenApp()
    }
    
    @IBAction func dismissButtonAction(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { done in
            self.removeFromSuperview()
        }
    }
}

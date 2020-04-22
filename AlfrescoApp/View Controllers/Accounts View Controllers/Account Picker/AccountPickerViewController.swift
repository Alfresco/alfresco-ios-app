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

@objc protocol AccountPickerDelegate: class {
    func resignin(currentUser: UserAccount?, viewcontroller: UIViewController)
    func addAccount()
    func signIn(userAccount: UserAccount?)
}

@objc class AccountPickerViewController: UIViewController {
    
    let kDefaultFontSize: CGFloat = 20.0
    let kCellHeight: CGFloat = 65.0
    let kMinimView: CGFloat = 250
    
    @IBOutlet weak var titlePickerLabel: UILabel!
    @IBOutlet weak var subtitlePickerLabel: UILabel!
    @IBOutlet weak var separatorBig: UIView!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var separatorSmall1: UIView!
    @IBOutlet weak var separatorSmall2: UIView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var contraintView: UIView!
    
    @IBOutlet weak var bottomInfoLabelConstraint: NSLayoutConstraint!
    
    var model: AccountPickerModel
    @objc weak var delegate: AccountPickerDelegate?

    @objc init(withAccount currentAccount: UserAccount, withDelegate delegate: AccountPickerDelegate) {
        self.model = AccountPickerModel(with: currentAccount)
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self.preferredContentSize = CGSize(width: self.view.bounds.size.width/2,
                                           height: kMinimView + CGFloat(self.model.accounts.count + 1) * kCellHeight)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titlePickerLabel.text = ""
        self.subtitlePickerLabel.text = NSLocalizedString("accountpicker.subtitle", comment: "Expired Session")
        self.infoLabel.text = NSLocalizedString("accountpicker.info.other", comment: "Expired Session")
        self.signInButton.setTitle(NSLocalizedString("login.sign.in", comment: "Sign in"), for: .normal)
        self.title = NSLocalizedString("accountpicker.title", comment: "Expired Session")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .cancel,
                                                                     target: self, action: #selector(cancelButtonPressed))
        
        if self.model.accounts.count == 0 {
            self.separatorSmall1.isHidden = true
            self.infoLabel.isHidden = true
            self.separatorSmall2.isHidden = true
            self.infoLabel.text = ""
            self.bottomInfoLabelConstraint.constant = 0
        }
    }
    
    @objc func cancelButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signInButtonPressed(_ sender: Any) {
        self.delegate?.resignin(currentUser: self.model.currentAccount, viewcontroller: self)
    }
    
}

extension AccountPickerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.accounts.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        let accountCellIdentifier = "AccountCellIdentifier"
        var celll = tableView.dequeueReusableCell(withIdentifier: accountCellIdentifier)
        if celll == nil {
            celll = UITableViewCell.init(style: .default, reuseIdentifier: accountCellIdentifier)
        }
        
        guard let cell = celll else { return UITableViewCell() }
        let cellHeight = kCellHeight
        let cellWidth = tableView.bounds.size.width
        let colorGrayish = UIColor(red: 36.0/255, green: 36.0/255, blue: 36.0/255, alpha: 0.75)
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cellHeight, height: cellHeight))
        let label = UILabel(frame: CGRect(x: cellHeight, y: 0, width: cellWidth - 2 * cellHeight, height: cellHeight))
        
        switch indexPath.row {
        case self.model.accounts.count:
            label.text = NSLocalizedString("accountpicker.button.addaccount", comment: "Expired Session")
            imageView.image = UIImage(named: "add-account")?.withRenderingMode(.alwaysTemplate)
        default:
            let account = self.model.accounts[indexPath.row]
            label.text = account.accountDescription
            let imageNamed = (account.accountType == .AIMS) ? "aims-account" : "account-type-onpremise.png"
            imageView.image = UIImage(named: imageNamed)?.withRenderingMode(.alwaysTemplate)
        }
        
        imageView.contentMode = .center
        imageView.tintColor = colorGrayish
        label.textColor = colorGrayish
        label.font = UIFont.systemFont(ofSize: kDefaultFontSize)
        
        cell.accessoryView = UIImageView(image: UIImage(named: "ButtonBarArrowRight"))
        cell.accessoryView?.tintColor = colorGrayish
        
        cell.addSubview(imageView)
        cell.addSubview(label)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: false) { [weak self] in
            guard let sSelf = self else { return }
            switch indexPath.row {
            case sSelf.model.accounts.count:
                sSelf.delegate?.addAccount()
            default:
                sSelf.delegate?.signIn(userAccount: sSelf.model.userAccount(at: indexPath))
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kCellHeight
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

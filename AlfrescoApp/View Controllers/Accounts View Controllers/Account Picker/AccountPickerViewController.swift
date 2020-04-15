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
    func resignin(currentUser: UserAccount?)
    func addAccount()
    func signIn(userAccount: UserAccount?)
}

@objc class AccountPickerViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var model: AccountPickerModel
    @objc weak var delegate: AccountPickerDelegate?
    var currentAccount: UserAccount!

    @objc init(withAccount currentAccount: UserAccount, withDelegate delegate: AccountPickerDelegate) {
        self.currentAccount = currentAccount
        self.model = AccountPickerModel(with: currentAccount)
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AccountPickerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.dataSource[section].count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return model.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return model.tableView(tableView, cellForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: false) { [weak self] in
            guard let sSelf = self else { return }
            switch indexPath.section {
            case 0:
                sSelf.delegate?.resignin(currentUser: sSelf.model.currentAccount)
            case sSelf.model.dataSource.count - 1:
                sSelf.delegate?.addAccount()
            default:
                sSelf.delegate?.signIn(userAccount: sSelf.model.userAccount(at: indexPath))
            }
        }
    }
}

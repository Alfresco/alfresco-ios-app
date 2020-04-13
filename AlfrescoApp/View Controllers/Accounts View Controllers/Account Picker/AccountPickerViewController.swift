//
//  AccountPickerViewController.swift
//  AlfrescoApp
//
//  Created by Florin Baincescu on 10/04/2020.
//  Copyright © 2020 Alfresco. All rights reserved.
//

import UIKit

@objc protocol AccountPickerDelegate: class {
    func resignin(currentUser: UserAccount?)
    func addAccount()
    func signIn(userAccount: UserAccount?)
}

@objc class AccountPickerViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var model = AccountPickerModel()
    @objc weak var delegate: AccountPickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

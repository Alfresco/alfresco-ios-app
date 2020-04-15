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

class AccountPickerModel: NSObject {
    let kDefaultFontSize: CGFloat = 20.0
    let kButtonFontSize: CGFloat = 25.0

    var dataSource: [[Any]] = []
    var currentAccount: UserAccount
    private var accounts: [UserAccount] = []
    
    init(with currentAccount: UserAccount) {
        self.currentAccount = currentAccount
        self.accounts = (AccountManager.shared()?.allAccounts() ?? []) as [UserAccount]
        super.init()
        removeCurrentAccountFromDataSource()
        let currentAccountName = self.currentAccount.accountDescription as String
        let array = [String(format: NSLocalizedString("accountpicker.label.notAuth", comment: "No Auth"), currentAccountName),
                     NSLocalizedString("login.sign.in", comment: "Sign in"), 
                     NSLocalizedString("accountpicker.label.other", comment: "OR")]
        dataSource = [array, accounts, [NSLocalizedString("acciuntpicker.button.addaccount", comment: "Add account")]]
    }
    
    //MARK: Helpers
    
    private func removeCurrentAccountFromDataSource() {
        for idx in 0...accounts.count {
            let account = accounts[idx]
            if account == currentAccount {
                accounts.remove(at: idx)
                return
            }
        }
    }
    
    //MARK: Public
    
    func userAccount(at indexPath: IndexPath) -> UserAccount? {
        if let userAccount = dataSource[indexPath.section][indexPath.row] as? UserAccount {
            return userAccount
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let accountCellIdentifier = "AccountCellIdentifier"
        var celll = tableView.dequeueReusableCell(withIdentifier: accountCellIdentifier)
        if celll == nil {
            celll = UITableViewCell.init(style: .default, reuseIdentifier: accountCellIdentifier)
        }
        
        guard let cell = celll else { return UITableViewCell() }
        switch indexPath.section {
        case 0:
            guard let text = dataSource[indexPath.section][indexPath.row] as? String else {
                return cell
            }
            cell.textLabel?.font = UIFont.systemFont(ofSize: kDefaultFontSize)
            cell.textLabel?.text = text
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            cell.isSelected = false
            if indexPath.row == 1 { //sign in
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: kButtonFontSize)
                cell.textLabel?.text = text.uppercased()
                cell.textLabel?.textColor = UIColor(red: 0.22, green: 0.67, blue: 0.85, alpha: 1.0)
                cell.isSelected = true
            } else {
                cell.backgroundColor = UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
            }
        case dataSource.count - 1:
            guard let text = dataSource[indexPath.section][indexPath.row] as? String else {
                return cell
            }
            cell.textLabel?.font = UIFont.systemFont(ofSize: kDefaultFontSize)
            cell.textLabel?.text = text
            cell.imageView?.image = UIImage(named: "add-account")
        default:
            guard let account = dataSource[indexPath.section][indexPath.row] as? UserAccount else {
                return cell
            }
            cell.textLabel?.font = UIFont.systemFont(ofSize: kDefaultFontSize)
            cell.textLabel?.text = account.accountDescription
            cell.imageView?.image = UIImage(named: "account-type-onpremise.png")
        }
        return cell
    }
}

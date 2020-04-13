//
//  AccountPickerDataSource.swift
//  AlfrescoApp
//
//  Created by Florin Baincescu on 13/04/2020.
//  Copyright © 2020 Alfresco. All rights reserved.
//

import UIKit

class AccountPickerModel: NSObject {
    let kDefaultFontSize: CGFloat = 20.0
    let kButtonFontSize: CGFloat = 25.0

    var dataSource: [[Any]] = []
    var currentAccount: UserAccount?
    private var accounts: [UserAccount]
    
    override init() {
        accounts = AccountManager.shared()?.allAccounts() as! [UserAccount]
        super.init()
        removeCurrentAccountFromDataSource()
        let currentAccountName = self.currentAccount?.accountDescription ?? ""
        let array = [String(format: NSLocalizedString("accountpicker.label.notAuth", comment: "No Auth"), currentAccountName),
                     NSLocalizedString("login.sign.in", comment: "Sign in"), 
                     NSLocalizedString("accountpicker.label.other", comment: "OR")]
        dataSource = [array, accounts, [NSLocalizedString("acciuntpicker.button.addaccount", comment: "Add account")]]
    }
    
    //MARK: Helpers
    
    private func removeCurrentAccountFromDataSource() {
        for idx in 0...accounts.count {
            let account = accounts[idx]
            if account.isSelectedAccount {
                currentAccount = account
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
            let text = dataSource[indexPath.section][indexPath.row] as! String
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
            let text = dataSource[indexPath.section][indexPath.row] as! String
            cell.textLabel?.font = UIFont.systemFont(ofSize: kDefaultFontSize)
            cell.textLabel?.text = text
            cell.imageView?.image = UIImage(named: "add-account")
        default:
            let account = dataSource[indexPath.section][indexPath.row] as! UserAccount
            cell.textLabel?.font = UIFont.systemFont(ofSize: kDefaultFontSize)
            cell.textLabel?.text = account.accountDescription
            cell.imageView?.image = UIImage(named: "account-type-onpremise.png")
        }
        return cell
    }
}

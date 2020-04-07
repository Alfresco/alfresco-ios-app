/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

import Foundation
import AlfrescoAuth

public typealias AvailableAuthTypeCallback<AuthType> = (Result<AuthType, APIError>) -> Void

class AIMSLoginService: NSObject, AlfrescoAuthDelegate {
    // Public variables
    var session: AlfrescoAuthSession?
    private (set) var account: UserAccount?
    private (set) lazy var alfrescoAuth: AlfrescoAuth = {
        let authConfig = authConfiguration()
        return AlfrescoAuth.init(configuration: authConfig)
    }()
    private (set) var alfrescoCredential: AlfrescoCredential?
    
    // Private variables
    private var loginCompletionBlock: LoginAuthenticationCompletionBlock?
    
    override init() {
    }
    
    @objc init(with account: UserAccount?) {
        self.account = account
    }
    
    @objc func update(with newAccount: UserAccount?) {
        self.account = newAccount;
    }
    
    @objc func availableAuthType(completionBlock: @escaping AvailableAuthenticationTypeCompletionBlock) {
        let authConfig = authConfiguration()
        alfrescoAuth.update(configuration: authConfig)
        alfrescoAuth.availableAuthType(handler: { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let authType):
                    if authType == .aimsAuth {
                        completionBlock(.AIMS, nil)
                    } else {
                        completionBlock(.basic, nil)
                    }
                case .failure(let error):
                    completionBlock(.undefined, error)
                }
            }
        })
    }
    
    @objc func login(onViewController: UIViewController, completionBlock: @escaping LoginAuthenticationCompletionBlock) {
        loginCompletionBlock = completionBlock
        let authConfig = authConfiguration()
        alfrescoAuth.update(configuration: authConfig)
        alfrescoAuth.pkceAuth(onViewController: onViewController, delegate: self)
    }
    
    @objc func logout(onViewController viewController: UIViewController, completionBlock: @escaping LogoutAIMSCompletionBlock) {
        logoutCompletionBlock = completionBlock
        self.session = nil
        let authConfig = authConfiguration()
        alfrescoAuth.update(configuration: authConfig)
        if let credential = obtainAlfrescoCredential() {
            alfrescoAuth.logout(onViewController: viewController, delegate: self, forCredential: credential)
        } else {
            if let logouCompletionBlock = self.logoutCompletionBlock {
                logouCompletionBlock(false, nil)
            }
        }
    }
    
    // MARK: - AlfrescoAuthDelegate
    
    func didReceive(result: Result<AlfrescoCredential, APIError>, session: AlfrescoAuthSession?) {
        switch result {
        case .success(let alfrescoCredential):
            self.session = session
            self.alfrescoCredential = alfrescoCredential
            self.account?.oauthData = AlfrescoOAuthData(tokenType: alfrescoCredential.tokenType,
                                                        accessToken: alfrescoCredential.accessToken,
                                                        accessTokenExpiresIn: alfrescoCredential.accessTokenExpiresIn as NSNumber?,
                                                        refreshToken: alfrescoCredential.refreshToken,
                                                        refreshTokenExpiresIn: alfrescoCredential.refreshTokenExpiresIn as NSNumber?,
                                                        sessionState: alfrescoCredential.sessionState)
            if let loginCompletionBlock = self.loginCompletionBlock {
                loginCompletionBlock(true, nil, nil)
            }
        case .failure(let error):
            if let loginCompletionBlock = self.loginCompletionBlock {
                loginCompletionBlock(false, nil, error)
            }
        }
    }
    
    func didLogOut(result: Result<Int, APIError>) {
        
    }
    
    // MARK: - Private
    
    private func authConfiguration() -> AuthConfiguration {
        guard let account = self.account else { return AuthConfiguration(baseUrl: "",
                                                                         clientID: kAlfrescoDefaultAIMSClientIDString,
                                                                         realm: kAlfrescoDefaultAIMSRealmString,
                                                                         redirectURI: kAlfrescoDefaultAIMSRedirectURI) }
        
        let authConfig = AuthConfiguration(baseUrl: fullFormatURL(for: account),
                                           clientID: account.clientID,
                                           realm: account.realm,
                                           redirectURI: account.redirectURI.encoding())
        
        return authConfig
    }
    
    private func fullFormatURL(for account: UserAccount) -> String {
        var fullFormatURL = String(format:"%@://%@", account.protocol, account.serverAddress)
        if account.serverPort.count != 0 {
            fullFormatURL.append(contentsOf: String(format:":%@", account.serverPort))
        }
        return fullFormatURL
    }
}

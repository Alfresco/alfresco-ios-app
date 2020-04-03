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

class AIMSLoginService: NSObject {
    private (set) var account: UserAccount?
    private (set) lazy var alfrescoAuth: AlfrescoAuth = {
        let authConfig = authConfiguration()
        return AlfrescoAuth.init(configuration: authConfig)
    }()
    var session: AlfrescoAuthSession?
    
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

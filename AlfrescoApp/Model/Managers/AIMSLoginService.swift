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

class AIMSLoginService: NSObject {
    private (set) var account: UserAccount?
    
    init(with account: UserAccount) {
        self.account = account
    }
    
//    private (set) lazy var alfrescoAuth: AlfrescoAuth = {
//        let authConfig = authConfiguration()
//        return AlfrescoAuth.init(configuration: authConfig)
//    }()
    
    // MARK: - Private
    
    private func authConfiguration() -> AuthConfiguration {
        guard let account = self.account else { return AuthConfiguration(baseUrl: "",
                                                                         clientID: "alfresco-ios-acs-app",
                                                                         realm: "alfresco",
                                                                         redirectURI: "iosapsapp://aims/auth") }
        
        let authConfig = AuthConfiguration(baseUrl: fullFormatURL(for: account),
                                           clientID: account.clientID ?? "alfresco-ios-acs-app",
                                           realm: account.realm ?? "alfresco",
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

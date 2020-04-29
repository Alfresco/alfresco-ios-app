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

import Foundation
import AlfrescoAuth
import JWT

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
    private var loginCompletionBlock: LoginAIMSCompletionBlock?
    private var logoutCompletionBlock: LogoutAIMSCompletionBlock?
    
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
    
    @objc func saveInKeychain() {
        if let credential = self.alfrescoCredential, let session = self.session {
            self.saveToKeychain(session: session, credential: credential)
        }
    }
    
    @objc func login(onViewController: UIViewController, completionBlock: @escaping LoginAIMSCompletionBlock) {
        loginCompletionBlock = completionBlock
        let authConfig = authConfiguration()
        alfrescoAuth.update(configuration: authConfig)
        alfrescoAuth.pkceAuth(onViewController: onViewController, delegate: self)
    }
    
    @objc func refreshSession(for account: UserAccount, completionBlock: @escaping LoginAIMSCompletionBlock) {
        loginCompletionBlock = completionBlock
        session = obtainAlfrescoAuthSession(for: account)
        guard let activeSession = session else { return }
        
        let authConfig = authConfiguration()
        alfrescoAuth.update(configuration: authConfig)
        alfrescoAuth.pkceRefresh(session: activeSession, delegate: self)
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
    
    func obtainAlfrescoCredential() -> AlfrescoCredential? {
        if let account = self.account {
            let credentialIdentifier = String(format: "%@-%@", account.accountIdentifier, kPersistenceStackCredentialParameter)
            if let data =  KeychainUtils.dataFor(matchingIdentifier: credentialIdentifier) {
                do {
                    return try JSONDecoder().decode(AlfrescoCredential.self, from: data)
                } catch {
                    AlfrescoLog.logError("Unable to restore last valid aims data.")
                }
            }
        }
        return nil
    }
    
    func obtainAlfrescoAuthSession(for account: UserAccount) -> AlfrescoAuthSession? {
        let credentialIdentifier = String(format: "%@-%@", account.accountIdentifier, kPersistenceStackSessionParameter)
        
        if let data = KeychainUtils.dataFor(matchingIdentifier: credentialIdentifier) {
            do {
                if let session = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? AlfrescoAuthSession {
                    return session
                }
            } catch {
                AlfrescoLog.logError("Unable to restore last valid aims data.")
            }
        }
        
        return nil
    }
    
    private func saveToKeychain(session: AlfrescoAuthSession?, credential: AlfrescoCredential) {
        let encoder = JSONEncoder()
        var credentialData: Data?
        var sessionData: Data?
        
        do {
            credentialData = try encoder.encode(credential)
            
            if let authSession = session {
                sessionData = try NSKeyedArchiver.archivedData(withRootObject: authSession, requiringSecureCoding: true)
            }
        } catch {
            AlfrescoLog.logError("Unable to persist credentials to Keychain.")
        }
        
        if let cData = credentialData, let sData = sessionData, let account = self.account {
            KeychainUtils.createKeychainData(cData, forIdentifier: String(format: "%@-%@", account.accountIdentifier, kPersistenceStackCredentialParameter))
            KeychainUtils.createKeychainData(sData, forIdentifier: String(format: "%@-%@", account.accountIdentifier, kPersistenceStackSessionParameter))
        }
    }
    
    // MARK: - AlfrescoAuthDelegate
    
    func didReceive(result: Result<AlfrescoCredential, APIError>, session: AlfrescoAuthSession?) {
        switch result {
        case .success(let alfrescoCredential):
            self.session = session
            self.alfrescoCredential = alfrescoCredential
            let decode = self.decodeJWTPayloadToken()
            self.account?.oauthData = AlfrescoOAuthData(tokenType: alfrescoCredential.tokenType,
                                                        accessToken: alfrescoCredential.accessToken,
                                                        accessTokenExpiresIn: alfrescoCredential.accessTokenExpiresIn as NSNumber?,
                                                        refreshToken: alfrescoCredential.refreshToken,
                                                        refreshTokenExpiresIn: alfrescoCredential.refreshTokenExpiresIn as NSNumber?,
                                                        sessionState: alfrescoCredential.sessionState,
                                                        payloadToken: decode)
            self.saveToKeychain(session: session, credential: alfrescoCredential)
            if let loginCompletionBlock = self.loginCompletionBlock {
                loginCompletionBlock(self.account, nil)
            }
        case .failure(let error):
            if let loginCompletionBlock = self.loginCompletionBlock {
                if error.responseCode == kAFALoginSSOViewModelCancelErrorCode {
                    loginCompletionBlock(nil, nil)
                } else {
                    loginCompletionBlock(nil, error)
                }
            }
        }
    }
    
    func didLogOut(result: Result<Int, APIError>) {
        switch result {
        case .success(_):
            AlfrescoLog.logInfo("AIMS session terminated successfully.")
            if let logoutCompletionBlock = self.logoutCompletionBlock {
                logoutCompletionBlock(true, nil)
            }
        case .failure(let error):
            if error.responseCode == kAFALoginSSOViewModelCancelErrorCode {
                if let logouCompletionBlock = self.logoutCompletionBlock {
                    logouCompletionBlock(false, nil)
                }
            } else {
                if let logouCompletionBlock = self.logoutCompletionBlock {
                    logouCompletionBlock(false, error)
                }
                let errorMessage = String(format: "AIMS session failed to be terminated succesfully. Reason:%@", error.localizedDescription)
                AlfrescoLog.logError(errorMessage)
            }
        }
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
    
    private func decodeJWTPayloadToken() -> [AnyHashable: Any]? {
        if let jwtToken = alfrescoCredential?.accessToken {
            if let decodeBuilder = JWT.decodeMessage(jwtToken) {
                let options = NSNumber(booleanLiteral: true)
                let result = decodeBuilder.message(jwtToken)?.options(options)?.decode
                return result
            }
        }
        return nil
    }
}

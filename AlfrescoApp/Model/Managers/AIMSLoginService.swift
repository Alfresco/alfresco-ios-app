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
    private (set) var activeAccount: UserAccount?
    private (set) var accountToBeRefreshed: UserAccount?
    private (set) lazy var alfrescoAuth: AlfrescoAuth = {
        let authConfig = authConfiguration()
        return AlfrescoAuth.init(configuration: authConfig)
    }()
    private (set) var alfrescoCredential: AlfrescoCredential?
    
    // Private variables
    private var loginCompletionBlock: LoginAIMSCompletionBlock?
    private var logoutCompletionBlock: LogoutAIMSCompletionBlock?
    private var refreshSessionCompletionBlock: LoginAIMSCompletionBlock?
    private var isSessionRefreshInProgress: Bool = false
    
    override init() {
    }
    
    @objc func update(with newAccount: UserAccount?) {
        self.activeAccount = newAccount
    }
    
    @objc func availableAuthType(forAccount account: UserAccount?, completionBlock: @escaping AvailableAuthenticationTypeCompletionBlock) {
        let authConfig = authConfiguration(for: account)
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
        accountToBeRefreshed = account
        refreshSessionCompletionBlock = completionBlock
        isSessionRefreshInProgress = true
        
        session = obtainAlfrescoAuthSession(for: account)
        guard let activeSession = session else { return }
        
        let authConfig = authConfiguration(for: account)
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
        if let account = activeAccount {
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
        let saveAccount = (isSessionRefreshInProgress) ? accountToBeRefreshed : activeAccount
        if let cData = credentialData, let sData = sessionData, let account = saveAccount {
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
            self.saveToKeychain(session: session, credential: alfrescoCredential)
            
            let oauthData = AlfrescoOAuthData(tokenType: alfrescoCredential.tokenType,
                                              accessToken: alfrescoCredential.accessToken,
                                              accessTokenExpiresIn: alfrescoCredential.accessTokenExpiresIn as NSNumber?,
                                              refreshToken: alfrescoCredential.refreshToken,
                                              refreshTokenExpiresIn: alfrescoCredential.refreshTokenExpiresIn as NSNumber?,
                                              sessionState: alfrescoCredential.sessionState,
                                              payloadToken: decode)
            if isSessionRefreshInProgress {
                accountToBeRefreshed?.oauthData = oauthData
                
                if let refreshCompletionBlock = self.refreshSessionCompletionBlock {
                    refreshCompletionBlock(accountToBeRefreshed, nil)
                    self.refreshSessionCompletionBlock = nil
                    isSessionRefreshInProgress = false
                }
            } else {
                activeAccount?.oauthData = oauthData
                
                if let loginCompletionBlock = self.loginCompletionBlock {
                    loginCompletionBlock(self.activeAccount, nil)
                    self.loginCompletionBlock = nil
                }
            }
        case .failure(let error):
            if !isSessionRefreshInProgress {
                if let loginCompletionBlock = self.loginCompletionBlock {
                    if error.responseCode == kAFALoginSSOViewModelCancelErrorCode {
                        loginCompletionBlock(nil, nil)
                    } else {
                        loginCompletionBlock(nil, error)
                    }
                    self.loginCompletionBlock = nil
                }
            }
            if let refreshCompletionBlock = self.refreshSessionCompletionBlock {
                refreshCompletionBlock(nil, error)
                self.refreshSessionCompletionBlock = nil
                isSessionRefreshInProgress = false
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
    
    private func authConfiguration(for account: UserAccount?) -> AuthConfiguration {
        guard let account = account else { return AuthConfiguration(baseUrl: "",
                                                                    clientID: kAlfrescoDefaultAIMSClientIDString,
                                                                    realm: kAlfrescoDefaultAIMSRealmString,
                                                                    redirectURI: kAlfrescoDefaultAIMSRedirectURI) }
        let redirectURI: String? = account.redirectURI?.encoding()
        let authConfig = AuthConfiguration(baseUrl: fullFormatURL(for: account),
                                           clientID: account.clientID ?? kAlfrescoDefaultAIMSClientIDString,
                                           realm: account.realm ?? kAlfrescoDefaultAIMSRealmString,
                                           redirectURI: redirectURI ?? kAlfrescoDefaultAIMSRedirectURI)
        
        return authConfig
    }
    
    private func authConfiguration() -> AuthConfiguration {
        return authConfiguration(for: activeAccount)
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

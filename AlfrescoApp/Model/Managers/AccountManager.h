/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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
  
#import "UserAccount.h"

@class RequestHandler;

typedef NS_ENUM(NSInteger, ImportCertificateStatus)
{
    ImportCertificateStatusCancelled = 0,
    ImportCertificateStatusFailed,
    ImportCertificateStatusSucceeded
};

@interface AccountManager : NSObject

@property (nonatomic, strong, readonly) UserAccount *selectedAccount;

+ (AccountManager *)sharedManager;
- (NSArray *)allAccounts;
- (void)addAccount:(UserAccount *)account;
- (void)addAccounts:(NSArray *)accounts;
- (void)removeAccount:(UserAccount *)account;
- (void)removeAllAccounts;
- (void)saveAccountsToKeychain;
- (NSInteger)totalNumberOfAddedAccounts;
- (NSInteger)numberOfPaidAccounts;
- (void)selectAccount:(UserAccount *)selectedAccount selectNetwork:(NSString *)networkIdentifier alfrescoSession:(id<AlfrescoSession>)alfrescoSession;
- (void)deselectSelectedAccount;
- (RequestHandler *)updateAccountStatusForAccount:(UserAccount *)account completionBlock:(void (^)(BOOL successful, NSError *error))completionBlock;

/*
 * Account Certificates Methods
 */
- (ImportCertificateStatus)validatePKCS12:(NSData *)pkcs12Data withPasscode:(NSString *)passcode;
- (ImportCertificateStatus)saveCertificateIdentityData:(NSData *)identityData withPasscode:(NSString *)passcode forAccount:(UserAccount *)account;

@end

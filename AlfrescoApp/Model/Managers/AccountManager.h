//
//  AccountManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

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
- (void)selectAccount:(UserAccount *)selectedAccount selectNetwork:(NSString *)networkIdentifier alfrescoSession:(id<AlfrescoSession>)alfrescoSession;
- (RequestHandler *)updateAccountStatusForAccount:(UserAccount *)account completionBlock:(void (^)(BOOL successful, NSError *error))completionBlock;

/*
 * Account Certificates Methods
 */
- (ImportCertificateStatus)validatePKCS12:(NSData *)pkcs12Data withPasscode:(NSString *)passcode;
- (ImportCertificateStatus)saveCertificateIdentityData:(NSData *)identityData withPasscode:(NSString *)passcode forAccount:(UserAccount *)account;

@end

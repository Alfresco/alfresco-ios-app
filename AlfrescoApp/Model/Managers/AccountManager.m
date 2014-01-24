//
//  AccountManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AccountManager.h"
#import "KeychainUtils.h"
#import "RequestHandler.h"
#import "Constants.h"
#import "AccountCertificate.h"

static NSString * const kKeychainAccountListIdentifier = @"AccountListNew";

@interface AccountManager ()

@property (nonatomic, strong, readwrite) NSMutableArray *accountsFromKeychain;
@property (nonatomic, strong, readwrite) UserAccount *selectedAccount;
@property (nonatomic, strong, readwrite) id<AlfrescoSession> alfrescoSessionForSelectedAccount;

@end

@implementation AccountManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static AccountManager *sharedAccountManager = nil;
    dispatch_once(&onceToken, ^{
        sharedAccountManager = [[self alloc] init];
    });
    return sharedAccountManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self loadAccountsFromKeychain];
    }
    return self;
}

- (NSArray *)allAccounts
{
    return self.accountsFromKeychain;
}

- (void)addAccount:(UserAccount *)account
{
    NSComparator comparator = ^(UserAccount *account1, UserAccount *account2)
    {
        return (NSComparisonResult)[account1.accountDescription caseInsensitiveCompare:account2.accountDescription];
    };
    NSInteger index = [self.accountsFromKeychain indexOfObject:account inSortedRange:NSMakeRange(0, self.accountsFromKeychain.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
    
    [self.accountsFromKeychain insertObject:account atIndex:index];
    [self saveAllAccountsToKeychain];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountAddedNotification object:account];
}

- (void)addAccounts:(NSArray *)accounts
{
    for (UserAccount *account in accounts)
    {
        NSComparator comparator = ^(UserAccount *account1, UserAccount *account2)
        {
            return (NSComparisonResult)[account1.accountDescription caseInsensitiveCompare:account2.accountDescription];
        };
        NSInteger index = [self.accountsFromKeychain indexOfObject:account inSortedRange:NSMakeRange(0, self.accountsFromKeychain.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
        
        [self.accountsFromKeychain insertObject:account atIndex:index];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountAddedNotification object:account];
    }
    [self saveAllAccountsToKeychain];
}

- (void)removeAccount:(UserAccount *)account
{
    [self.accountsFromKeychain removeObject:account];
    [self saveAllAccountsToKeychain];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountRemovedNotification object:account];
    if (self.accountsFromKeychain.count == 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountsListEmptyNotification object:nil];
    }
}

- (void)removeAllAccounts
{
    [self.accountsFromKeychain removeAllObjects];
    NSError *deleteError = nil;
    [KeychainUtils deleteSavedAccountsForListIdentifier:kKeychainAccountListIdentifier error:&deleteError];
    
    if (deleteError)
    {
        AlfrescoLogDebug(@"Error deleting all accounts from the keychain. Error: %@", deleteError.localizedDescription);
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountsListEmptyNotification object:nil];
    }
}

- (void)saveAccountsToKeychain
{
    [self saveAllAccountsToKeychain];
}

- (void)selectAccount:(UserAccount *)selectedAccount selectNetwork:(NSString *)networkIdentifier alfrescoSession:(id<AlfrescoSession>)alfrescoSession
{
    self.selectedAccount = selectedAccount;
    self.alfrescoSessionForSelectedAccount = alfrescoSession;
    
    for (UserAccount *account in self.accountsFromKeychain)
    {
        account.selectedNetworkId = nil;
        account.isSelectedAccount = NO;
    }
    selectedAccount.isSelectedAccount = YES;
    if ([selectedAccount.accountNetworks containsObject:networkIdentifier])
    {
        selectedAccount.selectedNetworkId = networkIdentifier;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:self.alfrescoSessionForSelectedAccount userInfo:nil];
    [self saveAccountsToKeychain];
}

- (NSInteger)totalNumberOfAddedAccounts
{
    return self.allAccounts.count;
}

#pragma mark - Certificate Import Methods

- (ImportCertificateStatus)validatePKCS12:(NSData *)pkcs12Data withPasscode:(NSString *)passcode
{
    ImportCertificateStatus status = ImportCertificateStatusFailed;
    CFArrayRef importedItems = NULL;
    OSStatus importStatus = SecPKCS12Import((__bridge CFDataRef)pkcs12Data, (__bridge CFDictionaryRef)@{(__bridge id)kSecImportExportPassphrase : passcode}, &importedItems);
    
    if (importStatus == noErr)
    {
        status = ImportCertificateStatusSucceeded;
    }
    else if (importStatus == errSecAuthFailed)
    {
        status = ImportCertificateStatusCancelled;
    }
    
    if (importedItems != NULL)
    {
        CFRelease(importedItems);
    }
    return status;
}

- (ImportCertificateStatus)saveCertificateIdentityData:(NSData *)identityData withPasscode:(NSString *)passcode forAccount:(UserAccount *)account
{
    OSStatus importStatus = noErr;
    CFArrayRef importedItems = NULL;
    NSDictionary *itemDictionary = NULL;
    
    ImportCertificateStatus status = ImportCertificateStatusFailed;
    importStatus = SecPKCS12Import((__bridge CFDataRef)identityData, (__bridge CFDictionaryRef)@{(__bridge id)kSecImportExportPassphrase: passcode}, &importedItems);
    
    if (importStatus == noErr)
    {
        SecIdentityRef identity = NULL;
        
        // If there are multiple identities in the PKCS#12, we only use the first one
        id item = ((__bridge id)importedItems)[0];
        if ([item isKindOfClass:[NSDictionary class]])
        {
            itemDictionary = item;
        }
        identity = (__bridge SecIdentityRef)itemDictionary[(__bridge __strong id)(kSecImportItemIdentity)];
        
        // Making sure there's an actual identity in the imported items
        if (CFGetTypeID(identity) == SecIdentityGetTypeID())
        {
            AccountCertificate *accountCertificate = [[AccountCertificate alloc] initWithIdentityData:identityData andPasscode:passcode];
            account.accountCertificate = accountCertificate;
            status = ImportCertificateStatusSucceeded;
        }
        else
        {
            // Unknown error/wrong identity data
            status = ImportCertificateStatusFailed;
        }
    }
    else if (importStatus == errSecAuthFailed)
    {
        // The passcode is wrong
        status = ImportCertificateStatusCancelled;
    }
    
    if (importedItems != NULL)
    {
        CFRelease(importedItems);
    }
    return status;
}

#pragma mark - Private Functions

- (void)saveAllAccountsToKeychain
{
    NSError *saveError = nil;
    [KeychainUtils updateSavedAccounts:self.accountsFromKeychain forListIdentifier:kKeychainAccountListIdentifier error:&saveError];
    
    if (saveError && saveError.code != -25300)
    {
        AlfrescoLogDebug(@"Error saving to keychain. Error: %@", saveError.localizedDescription);
    }
}

- (void)loadAccountsFromKeychain
{
    NSError *keychainRetrieveError = nil;
    self.accountsFromKeychain = [[KeychainUtils savedAccountsForListIdentifier:kKeychainAccountListIdentifier error:&keychainRetrieveError] mutableCopy];
    
    if (keychainRetrieveError)
    {
        AlfrescoLogDebug(@"Error in retrieving saved accounts. Error: %@", keychainRetrieveError.localizedDescription);
    }
    
    if (!self.accountsFromKeychain)
    {
        self.accountsFromKeychain = [NSMutableArray array];
    }
    
    for (UserAccount *account in self.accountsFromKeychain)
    {
        if (account.isSelectedAccount)
        {
            self.selectedAccount = account;
        }
        
        if (account.accountType == UserAccountTypeCloud && account.accountStatus == UserAccountStatusAwaitingVerification)
        {
            [self updateAccountStatusForAccount:account completionBlock:^(BOOL successful, NSError *error) {
                
                if (successful && account.accountStatus != UserAccountStatusAwaitingVerification)
                {
                    [self saveAllAccountsToKeychain];
                }
            }];
        }
    }
}

- (RequestHandler *)updateAccountStatusForAccount:(UserAccount *)account completionBlock:(void (^)(BOOL successful, NSError *error))completionBlock
{
    NSString *accountStatusUrl = [kAlfrescoCloudAPIAccountStatusUrl stringByReplacingOccurrencesOfString:kAlfrescoCloudAPIAccountID withString:account.cloudAccountId];
    accountStatusUrl = [accountStatusUrl stringByReplacingOccurrencesOfString:kAlfrescoCloudAPIAccountKey withString:account.cloudAccountKey];
    
    NSDictionary *headers = @{kCloudAPIHeaderKey : ALFRESCO_CLOUD_API_KEY};
    
    RequestHandler *request = [[RequestHandler alloc] init];
    [request connectWithURL:[NSURL URLWithString:accountStatusUrl] method:kHTTPMethodGET headers:headers requestBody:nil completionBlock:^(NSData *data, NSError *error) {
        
        if (error)
        {
            BOOL success = NO;
            if (error.code == kAlfrescoErrorCodeRequestedNodeNotFound)
            {
                account.accountStatus = UserAccountStatusActive;
                success = YES;
            }
            if (completionBlock != NULL)
            {
                completionBlock(success, error);
            }
        }
        else
        {
            NSError *parserError = nil;
            NSDictionary *accountInfoReceived = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parserError];
            
            if (error && completionBlock != NULL)
            {
                completionBlock(NO, parserError);
            }
            else
            {
                BOOL isActiviated = [[accountInfoReceived valueForKeyPath:kCloudAccountStatusValuePath] boolValue];
                account.accountStatus = isActiviated ? UserAccountStatusActive : UserAccountStatusAwaitingVerification;
                
                if (completionBlock != NULL)
                {
                    completionBlock(YES, nil);
                }
            }
        }
    }];
    return request;
}

@end

/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
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
 
#import "AccountManager.h"
#import "KeychainUtils.h"
#import "RequestHandler.h"
#import "Constants.h"
#import "AccountCertificate.h"
#import "AlfrescoProfileConfig.h"
#import "AppConfigurationManager.h"
#import "RealmManager.h"

static NSString * const kKeychainAccountListIdentifier = @"AccountListNew";

@interface AccountManager ()
@property (nonatomic, strong, readwrite) NSMutableArray *accountsFromKeychain;
@property (nonatomic, strong, readwrite) UserAccount *selectedAccount;
@end

@implementation AccountManager

+ (AccountManager *)sharedManager
{
#ifndef DEBUG
    SEC_IS_BEING_DEBUGGED_RETURN_NIL();
#endif
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileChanged:) name:kAlfrescoConfigProfileDidChangeNotification object:nil];
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
    [self saveAccountsToKeychain];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountAddedNotification object:account];
    
    if (account.isPaidAccount && [self numberOfPaidAccounts] == 1)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoFirstPaidAccountAddedNotification object:nil];
    }
}

- (void)addAccounts:(NSArray *)accounts
{
    NSInteger previousNumberOfPaidAccounts = [self numberOfPaidAccounts];
    
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
    [self saveAccountsToKeychain];
    
    if (previousNumberOfPaidAccounts == 0 && [self numberOfPaidAccounts] > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoFirstPaidAccountAddedNotification object:nil];
    }
}

- (void)removeAccount:(UserAccount *)account
{
    NSString *labelString = account.accountType == UserAccountTypeOnPremise ? ([account.samlData isSamlEnabled] ? kAnalyticsEventLabelOnPremiseSAML : kAnalyticsEventLabelOnPremise) : kAnalyticsEventLabelCloud;
    
    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryAccount
                                                      action:kAnalyticsEventActionDelete
                                                       label:labelString
                                                       value:@1];
    
    [self.accountsFromKeychain removeObject:account];
    [self saveAccountsToKeychain];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountRemovedNotification object:account];

    if (self.accountsFromKeychain.count == 0)
    {
        self.selectedAccount = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountsListEmptyNotification object:nil];
    }
    
    if (account.isPaidAccount && [self numberOfPaidAccounts] == 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoLastPaidAccountRemovedNotification object:nil];
    }
}

- (void)removeAllAccounts
{
    NSInteger previousNumberOfPaidAccounts = [self numberOfPaidAccounts];

    [self.accountsFromKeychain removeAllObjects];
    self.selectedAccount = nil;
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
    
    if (previousNumberOfPaidAccounts > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoLastPaidAccountRemovedNotification object:nil];
    }
}

- (void)saveAccountsToKeychain
{
    NSError *saveError = nil;
    [KeychainUtils updateSavedAccounts:self.accountsFromKeychain forListIdentifier:kKeychainAccountListIdentifier error:&saveError];
    
    if (saveError && saveError.code != -25300)
    {
        AlfrescoLogDebug(@"Error saving to keychain. Error: %@", saveError.localizedDescription);
    }
}

- (void)selectAccount:(UserAccount *)selectedAccount selectNetwork:(NSString *)networkIdentifier alfrescoSession:(id<AlfrescoSession>)alfrescoSession
{
    if (self.selectedAccount == selectedAccount)
    {
        [[[AppConfigurationManager sharedManager] configurationServiceForAccount:selectedAccount] clear];
    }
    
    self.selectedAccount = selectedAccount;
    
    if (selectedAccount)
    {
        [[RealmManager sharedManager] changeDefaultConfigurationForAccount:selectedAccount completionBlock:nil];
    }
    
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:alfrescoSession userInfo:nil];
    [self saveAccountsToKeychain];
}

- (void)deselectSelectedAccount
{
    self.selectedAccount = nil;
    
    for (UserAccount *account in self.accountsFromKeychain)
    {
        account.selectedNetworkId = nil;
        account.isSelectedAccount = NO;
    }
}

- (NSInteger)totalNumberOfAddedAccounts
{
    return self.accountsFromKeychain.count;
}

- (NSInteger)numberOfPaidAccounts
{
    NSInteger paidAccounts = 0;
    
    for (UserAccount *account in self.accountsFromKeychain)
    {
        if (account.isPaidAccount)
        {
            ++paidAccounts;
        }
    }
    return paidAccounts;
}

#pragma mark - Notification Methods

- (void)profileChanged:(NSNotification *)notification
{
    AlfrescoProfileConfig *profile = notification.object;
    UserAccount *changedAccount = notification.userInfo[kAlfrescoConfigProfileDidChangeForAccountKey];
    changedAccount.selectedProfileIdentifier = profile.identifier;
    changedAccount.selectedProfileName = profile.label;
    [self saveAccountsToKeychain];
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

    NSArray *accounts = [NSArray arrayWithArray:self.accountsFromKeychain];
    for (UserAccount *account in accounts)
    {
        if (account.accountType == UserAccountTypeCloud && account.accountStatus == UserAccountStatusAwaitingVerification)
        {
            // Check for bad accounts in "awaiting" status
            if ([account.cloudAccountId isKindOfClass:[NSNull class]] || [account.cloudAccountKey isKindOfClass:[NSNull class]])
            {
                [self.accountsFromKeychain removeObject:account];
                [self saveAccountsToKeychain];
                account.isSelectedAccount = NO;
            }
            else
            {
                [self updateAccountStatusForAccount:account completionBlock:^(BOOL successful, NSError *error) {
                    if (successful && account.accountStatus != UserAccountStatusAwaitingVerification)
                    {
                        [self saveAccountsToKeychain];
                    }
                }];
            }
        }

        if (account.isSelectedAccount)
        {
            self.selectedAccount = account;
        }
    }
}

- (RequestHandler *)updateAccountStatusForAccount:(UserAccount *)account completionBlock:(void (^)(BOOL successful, NSError *error))completionBlock
{
    NSString *accountStatusUrl = [kAlfrescoCloudAPIAccountStatusUrl stringByReplacingOccurrencesOfString:kAlfrescoCloudAPIAccountID withString:account.cloudAccountId];
    accountStatusUrl = [accountStatusUrl stringByReplacingOccurrencesOfString:kAlfrescoCloudAPIAccountKey withString:account.cloudAccountKey];
    
    NSDictionary *headers = @{kCloudAPIHeaderKey : INTERNAL_CLOUD_API_KEY};
    
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
                BOOL isActivated = [[accountInfoReceived valueForKeyPath:kCloudAccountStatusValuePath] boolValue];
                account.accountStatus = isActivated ? UserAccountStatusActive : UserAccountStatusAwaitingVerification;
                
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

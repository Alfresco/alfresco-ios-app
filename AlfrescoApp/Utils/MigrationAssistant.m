//
//  MigrationAssistant.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 28/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MigrationAssistant.h"
#import "AccountInfo.h"
#import "NSData+Base64.h"
#import "RNDecryptor.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "KeychainUtils.h"

static NSString * const kOldAccountListIdentifier = @"AccountList";

@interface MigrationAssistant ()

@end

@implementation MigrationAssistant

#pragma mark - Public Functions

+ (void)runMigrationAssistant
{
    if ([self shouldStartMigration])
    {
        [self migrateAccounts];
    }
}

#pragma mark - Private Functions

+ (BOOL)shouldStartMigration
{
    BOOL shouldMigrateAccounts = NO;
    
    NSError *oldAccountRetrieveError = nil;
    NSArray *oldAccounts = [KeychainUtils savedAccountsForListIdentifier:kOldAccountListIdentifier error:&oldAccountRetrieveError];
    
    if ([[AccountManager sharedManager] totalNumberOfAddedAccounts] <= 0 && (oldAccounts && !oldAccountRetrieveError))
    {
        shouldMigrateAccounts = YES;
    }
    
    return shouldMigrateAccounts;
}

+ (void)migrateAccounts
{
    NSError *oldAccountRetrieveError = nil;
    NSArray *oldAccounts = [KeychainUtils savedAccountsForListIdentifier:kOldAccountListIdentifier error:&oldAccountRetrieveError];
    
    NSMutableArray *migratedAccounts = [NSMutableArray arrayWithCapacity:oldAccounts.count];
    
    for (AccountInfo *oldAccount in oldAccounts)
    {
        UserAccount *account = [self createUserAccountFromOldAccount:oldAccount];
        [migratedAccounts addObject:account];
    }
    
    [[AccountManager sharedManager] addAccounts:migratedAccounts];
    
    [self removeLegacyAccounts];
}

+ (void)removeLegacyAccounts
{
    NSError *removalError = nil;
    [KeychainUtils deleteSavedAccountsForListIdentifier:kOldAccountListIdentifier error:&removalError];
    
    if (removalError)
    {
        AlfrescoLogError(@"Unable to remove old accounts. Error: %@", removalError.localizedDescription);
    }
}

+ (UserAccount *)createUserAccountFromOldAccount:(AccountInfo *)oldAccount
{
    UserAccount *account = [[UserAccount alloc] init];
    if ([oldAccount.multitenant boolValue])
    {
        account.accountType = UserAccountTypeCloud;
    }
    else
    {
        account.username = oldAccount.username;
        account.password = oldAccount.password;
        account.serverAddress = oldAccount.hostname;
        account.serverPort = oldAccount.port;
        account.protocol = oldAccount.protocol;
        account.serviceDocument = oldAccount.serviceDocumentRequestPath;
    }
    account.accountDescription = oldAccount.description;
    account.isSelectedAccount = NO;
    return account;
}

@end

/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
 
#import "MigrationAssistant.h"
#import "AccountInfo.h"
#import "NSData+Base64.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "KeychainUtils.h"
#import "AppDelegate.h"

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
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] updateAppFirstLaunchFlag];
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
        account.cloudAccountId = oldAccount.cloudId;
        account.cloudAccountKey = oldAccount.cloudKey;
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

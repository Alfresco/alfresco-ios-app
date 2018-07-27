/*******************************************************************************
 * Copyright (C) 2005-2018 Alfresco Software Limited.
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

#import "AFPRootEnumerator.h"

#import "KeychainUtils.h"

#import "AFPItem.h"
#import "AFPDataManager.h"
#import "AFPAccountManager.h"

@implementation AFPRootEnumerator

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    NSError *authenticationError = [AFPAccountManager authenticationErrorForPIN];
    if (authenticationError)
    {
        [observer finishEnumeratingWithError:authenticationError];
    }
    else
    {
        
        NSArray *accounts = [self getAccountFromKeychain];
        NSMutableArray *enumeratedAccounts = [NSMutableArray new];
        for(UserAccount *account in accounts)
        {
            AFPItem *fpItem = [[AFPItem alloc] initWithUserAccount:account];
            [enumeratedAccounts addObject:fpItem];
        }
        
        AFPItem *localFilesItem = [[AFPItem alloc] initWithItemMetadata:[[AFPDataManager sharedManager] localFilesItem]];
        [enumeratedAccounts addObject:localFilesItem];
        
        [observer didEnumerateItems:enumeratedAccounts];
        [observer finishEnumeratingUpToPage:nil];
    }
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

#pragma mark - Private methods
- (NSArray *)getAccountFromKeychain
{
    NSError *keychainError = nil;
    NSArray *accounts = [KeychainUtils savedAccountsForListIdentifier:kAccountsListIdentifier error:&keychainError];
    
    if (keychainError)
    {
        AlfrescoLogError(@"Error retreiving accounts. Error: %@", keychainError.localizedDescription);
    }
    
    return accounts;
}

@end

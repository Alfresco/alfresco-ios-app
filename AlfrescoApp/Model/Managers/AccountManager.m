//
//  AccountManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AccountManager.h"
#import "KeychainUtils.h"

@interface AccountManager ()

@property (nonatomic, strong, readwrite) NSMutableArray *accountsFromKeychain;

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

- (void)addAccount:(Account *)account
{
    [self.accountsFromKeychain addObject:account];
    [self saveAllAccountsToKeychain];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountAddedNotification object:account];
}

- (void)removeAccount:(Account *)account
{
    [self.accountsFromKeychain removeObject:account];
    [self saveAllAccountsToKeychain];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountRemovedNotification object:account];
}

- (void)removeAllAccounts
{
    [self.accountsFromKeychain removeAllObjects];
    NSError *deleteError = nil;
    [KeychainUtils deleteSavedAccountsWithError:&deleteError];
    
    if (deleteError)
    {
        AlfrescoLogDebug(@"Error deleting all accounts from the keychain. Error: %@", deleteError.localizedDescription);
    }
}

- (void)saveAccountsToKeychain
{
    [self saveAllAccountsToKeychain];
}

- (void)setSelectedAccount:(Account *)selectedAccount
{
    _selectedAccount = selectedAccount;
    
    for (Account *account in self.accountsFromKeychain)
    {
        account.isSelectedAccount = NO;
    }
    selectedAccount.isSelectedAccount = YES;
    [self saveAccountsToKeychain];
}

- (NSInteger)totalNumberOfAddedAccounts
{
    return self.allAccounts.count;
}

#pragma mark - Private Functions

- (void)saveAllAccountsToKeychain
{
    NSError *saveError = nil;
    [KeychainUtils updateSavedAccounts:self.accountsFromKeychain error:&saveError];
    
    if (saveError)
    {
        AlfrescoLogDebug(@"Error saving to keychain. Error: %@", saveError.localizedDescription);
    }
}

- (void)loadAccountsFromKeychain
{
    NSError *keychainRetrieveError = nil;
    self.accountsFromKeychain = [[KeychainUtils savedAccountsWithError:&keychainRetrieveError] mutableCopy];
    
    if (keychainRetrieveError)
    {
        AlfrescoLogDebug(@"Error in retrieving saved accounts. Error: %@", keychainRetrieveError.localizedDescription);
    }
    
    if (!self.accountsFromKeychain)
    {
        self.accountsFromKeychain = [NSMutableArray array];
    }
    
    for (Account *account in self.accountsFromKeychain)
    {
        if (account.isSelectedAccount)
        {
            self.selectedAccount = account;
        }
    }
}

@end

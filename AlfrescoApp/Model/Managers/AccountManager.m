//
//  AccountManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AccountManager.h"
#import "KeychainUtils.h"

static NSString * const kKeychainAccountListIdentifier = @"AccountListNew";

@interface AccountManager ()

@property (nonatomic, strong, readwrite) NSMutableArray *accountsFromKeychain;
@property (nonatomic, strong, readwrite) UserAccount *selectedAccount;

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
}

- (void)saveAccountsToKeychain
{
    [self saveAllAccountsToKeychain];
}

- (void)selectAccount:(UserAccount *)selectedAccount selectNetwork:(NSString *)networkIdentifier
{
    self.selectedAccount = selectedAccount;
    
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
    }
}

@end

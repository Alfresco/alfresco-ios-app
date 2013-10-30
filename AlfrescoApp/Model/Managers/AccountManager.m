//
//  AccountManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AccountManager.h"
#import "KeychainUtils.h"

static NSString * const kAccountRepositoryId= @"kAccountRepositoryId";

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
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountAddedNotification object:nil];
}

- (void)removeAccount:(Account *)account
{
    [self.accountsFromKeychain removeObject:account];
    [self saveAllAccountsToKeychain];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountRemovedNotification object:nil];
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
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:selectedAccount.repositoryId forKey:kAccountRepositoryId];
    [userDefaults synchronize];
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
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *selectedAccountRepositoryId = [userDefaults objectForKey:kAccountRepositoryId];
    
    for (Account *account in self.accountsFromKeychain)
    {
        if ([account.repositoryId isEqualToString:selectedAccountRepositoryId])
        {
            self.selectedAccount = account;
        }
    }
}

@end

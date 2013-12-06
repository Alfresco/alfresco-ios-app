//
//  AccountManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserAccount.h"

@interface AccountManager : NSObject

@property (nonatomic, strong, readonly) UserAccount *selectedAccount;

+ (instancetype)sharedManager;
- (NSArray *)allAccounts;
- (void)addAccount:(UserAccount *)account;
- (void)addAccounts:(NSArray *)accounts;
- (void)removeAccount:(UserAccount *)account;
- (void)removeAllAccounts;
- (void)saveAccountsToKeychain;
- (NSInteger)totalNumberOfAddedAccounts;
- (void)selectAccount:(UserAccount *)selectedAccount selectNetwork:(NSString *)networkIdentifier;

@end

//
//  AccountManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Account.h"

@interface AccountManager : NSObject

@property (nonatomic, strong, readwrite) Account *selectedAccount;

+ (instancetype)sharedManager;
- (NSArray *)allAccounts;
- (BOOL)isSelectedAccount:(Account *)account;
- (void)addAccount:(Account *)account;
- (void)removeAccount:(Account *)account;
- (void)removeAllAccounts;
- (void)saveAccountsToKeychain;
- (NSInteger)totalNumberOfAddedAccounts;

@end

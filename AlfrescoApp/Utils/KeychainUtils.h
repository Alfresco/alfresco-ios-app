//
//  KeychainManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeychainUtils : NSObject

+ (NSArray *)savedAccountsWithError:(NSError **)error;
+ (void)updateSavedAccounts:(NSArray *)accounts error:(NSError **)updateError;
+ (void)deleteSavedAccountsWithError:(NSError **)deleteError;

@end

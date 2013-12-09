//
//  KeychainManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeychainUtils : NSObject

+ (NSArray *)savedAccountsForListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)error;
+ (void)updateSavedAccounts:(NSArray *)accounts forListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)updateError;
+ (void)deleteSavedAccountsForListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)deleteError;

@end

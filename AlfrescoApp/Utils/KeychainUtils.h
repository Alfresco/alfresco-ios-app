/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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

#import <Foundation/Foundation.h>
@class UserAccount;

@interface KeychainUtils : NSObject

+ (BOOL)createKeychainData:(NSData *)data forIdentifier:(NSString *)identifier;
+ (NSData *)dataForMatchingIdentifier:(NSString *)identifier;
+ (NSArray *)savedAccountsForListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)error;
+ (NSArray *)savedAccountsForListIdentifier:(NSString *)listIdentifier inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)error;
+ (BOOL)updateSavedAccounts:(NSArray *)accounts forListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)updateError;
+ (BOOL)updateSavedAccounts:(NSArray *)accounts forListIdentifier:(NSString *)listIdentifier inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)updateError;
+ (BOOL)updateSavedAccount:(UserAccount *)account forListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)updateError;
+ (BOOL)deleteSavedAccountsForListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)deleteError;
+ (BOOL)deleteSavedAccountsForListIdentifier:(NSString *)listIdentifier inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)deleteError;

+ (OSStatus)saveItem:(id)value forKey:(NSString *)keychainItemId error:(NSError *__autoreleasing *)error;
+ (OSStatus)saveItem:(id)value forKey:(NSString *)keychainItemId inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)error;
+ (id)retrieveItemForKey:(NSString *)keychainItemId error:(NSError *__autoreleasing *)error;
+ (id)retrieveItemForKey:(NSString *)keychainItemId inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)error;
+ (OSStatus)deleteItemForKey:(NSString *)keychainItemId error:(NSError *__autoreleasing *)error;
+ (OSStatus)deleteItemForKey:(NSString *)keychainItemId inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)error;

@end

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

#import "KeychainUtils.h"
#import "NSObject+DebugCheck.h"
#import "UserAccount.h"
#import "SharedConstants.h"

@implementation KeychainUtils

static NSString *kKeychainItemServiceName = @"Alfresco";

+ (NSArray *)savedAccountsForListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)error
{
    return [self savedAccountsForListIdentifier:listIdentifier
                                        inGroup:kSharedAppGroupIdentifier
                                          error:error];
}

+ (NSArray *)savedAccountsForListIdentifier:(NSString *)listIdentifier inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)error {
#ifndef DEBUG
    SEC_IS_BEING_DEBUGGED_RETURN_NIL();
#endif
    
    NSArray *accountsArray = nil;
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithDictionary:
                                  @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                    (__bridge id)kSecAttrGeneric : (id)listIdentifier,
                                    (__bridge id)kSecReturnData : @YES
                                    }];
    if (groupID.length)
    {
        [query setObject:groupID forKey:(__bridge id)kSecAttrAccessGroup];
    }
    
    
    NSData *data = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (void *)&data);
    
    if (status == noErr)
    {
        if (data)
        {
            accountsArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        else
        {
            if (error)
            {
                *error = [NSError errorWithDomain:@"Error retrieving accounts. No Data found." code:-1 userInfo:nil];
            }
        }
    }
    else
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"Error retrieving accounts" code:status userInfo:nil];
        }
    }
    return accountsArray;
}

+ (BOOL)updateSavedAccounts:(NSArray *)accounts forListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)updateError
{
    return [self updateSavedAccounts:accounts
                   forListIdentifier:listIdentifier
                             inGroup:kSharedAppGroupIdentifier
                               error:updateError];
}

+ (BOOL)updateSavedAccounts:(NSArray *)accounts forListIdentifier:(NSString *)listIdentifier inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)updateError
{
    BOOL updateSucceeded = YES;
    if (accounts)
    {
        NSData *accountsArrayData = [NSKeyedArchiver archivedDataWithRootObject:accounts];
        NSMutableDictionary *searchDictionary = [NSMutableDictionary dictionaryWithDictionary:
                                                 @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                                   (__bridge id)kSecAttrGeneric : (id)listIdentifier
                                                   }];
        
        if (groupID.length)
        {
            [searchDictionary setObject:groupID forKey:(__bridge id)kSecAttrAccessGroup];
        }
        
        NSDictionary *updateDictionary = @{(__bridge id)kSecValueData : (id)accountsArrayData};
        
        NSArray *accountsList = [self savedAccountsForListIdentifier:listIdentifier error:updateError];
        OSStatus status = noErr;
        
        // if no accounts in the keychain, add to the keychain, else, update
        if (!accountsList)
        {
            NSMutableDictionary *createDictionary = [NSMutableDictionary dictionary];
            [createDictionary addEntriesFromDictionary:searchDictionary];
            [createDictionary addEntriesFromDictionary:updateDictionary];
            status = SecItemAdd((__bridge CFDictionaryRef)createDictionary, NULL);
        }
        else
        {
            status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary, (__bridge CFDictionaryRef)updateDictionary);
            updateSucceeded = NO;
        }
        
        if (updateError && status != noErr)
        {
            *updateError = [NSError errorWithDomain:@"Error updating the accounts" code:status userInfo:nil];
            updateSucceeded = NO;
        }
    }
    else if (updateError)
    {
        *updateError = [NSError errorWithDomain:@"Nil account array" code:-1 userInfo:nil];
        updateSucceeded = NO;
    }
    return updateSucceeded;
}

+ (BOOL)updateSavedAccount:(UserAccount *)account forListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)updateError
{
    BOOL updateSucceeded = YES;
    
    if(account)
    {
        NSMutableArray *accountsList = [[self savedAccountsForListIdentifier:listIdentifier error:updateError] mutableCopy];
        if(accountsList)
        {
            // Get the account
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"accountIdentifier == %@", account.accountIdentifier];
            NSArray *accountArray = [accountsList filteredArrayUsingPredicate:predicate];
            UserAccount *keychainAccount = accountArray.firstObject;
            NSUInteger index = [accountsList indexOfObject:keychainAccount];
            if(index < accountsList.count)
            {
                [accountsList replaceObjectAtIndex:index withObject:account];
                [self updateSavedAccounts:accountsList forListIdentifier:listIdentifier error:updateError];
            }
            else
            {
                *updateError = [NSError errorWithDomain:@"Account not found in Keychain" code:-1 userInfo:nil];
                updateSucceeded = NO;
            }
        }
        else
        {
            [self updateSavedAccounts:[NSArray arrayWithObject:account] forListIdentifier:listIdentifier error:updateError];
        }
    }
    else if(updateError)
    {
        *updateError = [NSError errorWithDomain:@"Nil account" code:-1 userInfo:nil];
        updateSucceeded = NO;
    }
    
    return updateSucceeded;
}

+ (BOOL)deleteSavedAccountsForListIdentifier:(NSString *)listIdentifier inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)deleteError
{
    BOOL deleteSucceeded = YES;
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithDictionary:
                                  @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                    (__bridge id)kSecAttrGeneric : (id)listIdentifier
                                    }];
    
    if (groupID.length)
    {
        [query setObject:groupID forKey:(__bridge id)kSecAttrAccessGroup];
    }
    
    OSStatus status = noErr;
    status = SecItemDelete((__bridge CFDictionaryRef)query);
    
    if (deleteError && status != noErr)
    {
        *deleteError = [NSError errorWithDomain:@"Error deleting accounts" code:status userInfo:nil];
        deleteSucceeded = NO;
    }
    return deleteSucceeded;
}

+ (BOOL)deleteSavedAccountsForListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)deleteError
{
    return [self deleteSavedAccountsForListIdentifier:listIdentifier
                                              inGroup:kSharedAppGroupIdentifier
                                                error:deleteError];
}

#pragma mark - Public Methods

+ (OSStatus)saveItem:(id)value forKey:(NSString *)keychainItemId error:(NSError *__autoreleasing *)error
{
    return [self saveItem:value forKey:keychainItemId inGroup:nil error:error];
}

+ (OSStatus)saveItem:(id)value forKey:(NSString *)keychainItemId inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)error
{
    id existingValue = [self retrieveItemForKey:keychainItemId error:error];
    
    if (existingValue == nil)
    {
        NSMutableDictionary *keychainItem = [self keychainItem:keychainItemId withValue:value];
        if (groupID.length)
        {
            [keychainItem setObject:groupID forKey:(__bridge id)kSecAttrAccessGroup];
        }
        
        OSStatus statusCode = SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
        if (error && statusCode != errSecSuccess)
        {
            *error = [NSError errorWithDomain:@"SecItemAdd failed" code:statusCode userInfo:nil];
        }
        
        return statusCode;
    }
    else
    {
        NSMutableDictionary *keychainItemQuery = [self keychainItem:keychainItemId];
        if (groupID.length)
        {
            [keychainItemQuery setObject:groupID forKey:(__bridge id)kSecAttrAccessGroup];
        }
        NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
        NSData *encodedValue = [NSData data];
        
        if(value != nil)
        {
            encodedValue = [NSKeyedArchiver archivedDataWithRootObject:value];
        }
        
        [updateDictionary setObject:encodedValue forKey:(__bridge id)kSecValueData];
        
        OSStatus statusCode = SecItemUpdate((__bridge CFDictionaryRef)keychainItemQuery, (__bridge CFDictionaryRef)updateDictionary);
        if (error && statusCode != errSecSuccess)
        {
            *error = [NSError errorWithDomain:@"SecItemUpdate failed" code:statusCode userInfo:nil];
        }
        
        return statusCode;
    }
}

+ (id)retrieveItemForKey:(NSString *)keychainItemId inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)error
{
    NSMutableDictionary *keychainItemQuery = [self keychainItemQuery:keychainItemId];
    if (groupID.length)
    {
        [keychainItemQuery setObject:groupID forKey:(__bridge id)kSecAttrAccessGroup];
    }
    
    CFTypeRef decryptedItem = NULL;
    OSStatus statusCode = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItemQuery, &decryptedItem);
    
    if (statusCode == errSecSuccess)
    {
        NSData *decryptedData = (__bridge NSData *) decryptedItem;
        id obj = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
        return obj;
    }
    else if (error && statusCode == errSecItemNotFound)
    {
        *error = [NSError errorWithDomain:@"SecItemCopyMatching failed. Item not found" code:statusCode userInfo:nil];
    }
    else if (error)
    {
        *error = [NSError errorWithDomain:@"SecItemCopyMatching failed " code:statusCode userInfo:nil];
    }
    return nil;
}

+ (id)retrieveItemForKey:(NSString *)keychainItemId error:(NSError *__autoreleasing *)error
{
    return [self retrieveItemForKey:keychainItemId inGroup:nil error:error];
}

+ (OSStatus)deleteItemForKey:(NSString *)keychainItemId inGroup:(NSString *)groupID error:(NSError *__autoreleasing *)error
{
    NSMutableDictionary *keychainItemQuery = [self keychainItem:keychainItemId];
    
    if (groupID.length)
    {
        [keychainItemQuery setObject:groupID forKey:(__bridge id)kSecAttrAccessGroup];
    }
    
    OSStatus statusCode = SecItemDelete((__bridge CFDictionaryRef)keychainItemQuery);
    
    if (error)
    {
        if (statusCode == errSecItemNotFound)
        {
            // Already deleted; we're good
            *error = [NSError errorWithDomain:@"SecItemDelete failed. Item not found" code:statusCode userInfo:nil];
        }
        else if (statusCode != noErr)
        {
            *error = [NSError errorWithDomain:@"SecItemDelete failed" code:statusCode userInfo:nil];
        }
    }
    
    return statusCode;
}

+ (OSStatus)deleteItemForKey:(NSString *)keychainItemId error:(NSError *__autoreleasing *)error
{
    return [self deleteSavedAccountsForListIdentifier:keychainItemId
                                              inGroup:nil
                                                error:error];
}

+ (BOOL)createKeychainData:(NSData *)data
             forIdentifier:(NSString *)identifier
{
    NSMutableDictionary *dictionary = [self keychainItem:identifier];
    [dictionary setObject:data
                   forKey:(__bridge id)kSecValueData];
    
    // Protect the keychain entry so it's only valid when the device is unlocked.
    [dictionary setObject:(__bridge id)kSecAttrAccessibleWhenUnlocked
                   forKey:(__bridge id)kSecAttrAccessible];
    
    // Add.
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    
    // If the addition was successful, return. Otherwise, attempt to update existing key or quit (return NO).
    if (status == errSecSuccess) {
        AlfrescoLogInfo(@"Added value to Keychain for identifier:%@", identifier);
        return YES;
    } else if (status == errSecDuplicateItem){
        return [self updateKeychainData:data
                          forIdentifier:identifier];
    } else {
        AlfrescoLogError(@"Cannot add value to Keychain for identifier:%@", identifier);
        return NO;
    }
}

+ (NSData *)dataForMatchingIdentifier:(NSString *)identifier {
    if (!identifier.length) {
        return nil;
    }
    
    NSMutableDictionary *searchDictionary = [self keychainItem:identifier];
    // Limit search results to one.
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    // Specify we want NSData/CFData returned.
    [searchDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
    // Search.
    NSData *result = nil;
    CFTypeRef foundDict = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &foundDict);
    
    if (status == noErr) {
        result = (__bridge_transfer NSData *)foundDict;
    } else {
        result = nil;
    }
    
    return result;
}

#pragma mark - Private Methods

+ (BOOL)updateKeychainData:(NSData *)data
             forIdentifier:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self keychainItem:identifier];
    NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
    [updateDictionary setObject:data forKey:(__bridge id)kSecValueData];
    
    // Update.
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary,
                                    (__bridge CFDictionaryRef)updateDictionary);
    
    if (status == errSecSuccess) {
        AlfrescoLogInfo(@"Updated value in Keychain for identifier:%@", identifier);
        return YES;
    } else {
        AlfrescoLogError(@"Cannot update value in Keychain for identifier:%@", identifier);
        return NO;
    }
}

+ (NSMutableDictionary *)keychainItem:(NSString *)keychainItemId
{
    // Create a new keychain item as a key/value pair dictionary
    NSMutableDictionary *keychainItem = [[NSMutableDictionary alloc] init];
    
    // Set as generic password type
    [keychainItem setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    // Set the unique key for this keychain item
    [keychainItem setObject:keychainItemId forKey:(__bridge id)kSecAttrGeneric];
    
    // Set the service name
    [keychainItem setObject:kKeychainItemServiceName forKey:(__bridge id)kSecAttrService];
    
    // Set the account name the same as the unique key
    [keychainItem setObject:keychainItemId forKey:(__bridge id)kSecAttrAccount];
    
    return keychainItem;
}

+ (NSMutableDictionary *)keychainItem:(NSString *)keychainItemId withValue:(id)value
{
    // Create a new keychain item as a key/value pair dictionary
    NSMutableDictionary *keychainItem = [self keychainItem:keychainItemId];
    
    // Set the value as the encrypted data
    NSData *encryptedData = [NSKeyedArchiver archivedDataWithRootObject:value];
    [keychainItem setObject:encryptedData forKey:(__bridge id)kSecValueData];
    
    return keychainItem;
}

+ (NSMutableDictionary *)keychainItemQuery:(NSString *)keychainItemId
{
    // Create a new keychain item query as a key/value pair dictionary
    NSMutableDictionary *keychainItemQuery = [self keychainItem:keychainItemId];
    
    // Return the data (not the attributes) of the keychain item
    [keychainItemQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
    return keychainItemQuery;
}

@end

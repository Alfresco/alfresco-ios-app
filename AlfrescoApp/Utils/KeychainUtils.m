/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

@implementation KeychainUtils

static NSString *kKeychainItemServiceName = @"Alfresco";

+ (NSArray *)savedAccountsForListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)error
{
#ifndef DEBUG
    SEC_IS_BEING_DEBUGGED_RETURN_NIL();
#endif
    NSArray *accountsArray = nil;
    NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrGeneric : (id)listIdentifier,
                            (__bridge id)kSecReturnData : @YES};
    
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
    BOOL updateSucceeded = YES;
    if (accounts)
    {
        NSData *accountsArrayData = [NSKeyedArchiver archivedDataWithRootObject:accounts];
        NSDictionary *searchDictionary = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                           (__bridge id)kSecAttrGeneric : (id)listIdentifier};
        
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

+ (BOOL)deleteSavedAccountsForListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)deleteError
{
    BOOL deleteSucceeded = YES;
    NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrGeneric : (id)listIdentifier};
    
    OSStatus status = noErr;
    status = SecItemDelete((__bridge CFDictionaryRef)query);
    
    if (deleteError && status != noErr)
    {
        *deleteError = [NSError errorWithDomain:@"Error deleting accounts" code:status userInfo:nil];
        deleteSucceeded = NO;
    }
    return deleteSucceeded;
}

#pragma mark - Public Methods

+ (OSStatus)saveItem:(id)value forKey:(NSString *)keychainItemId error:(NSError *__autoreleasing *)error
{
    id existingValue = [self retrieveItemForKey:keychainItemId error:error];
    
    if (existingValue == nil)
    {
        NSMutableDictionary *keychainItem = [self keychainItem:keychainItemId withValue:value];
        
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

+ (id)retrieveItemForKey:(NSString *)keychainItemId error:(NSError *__autoreleasing *)error
{
    NSMutableDictionary *keychainItemQuery = [self keychainItemQuery:keychainItemId];
    
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

+ (OSStatus)deleteItemForKey:(NSString *)keychainItemId error:(NSError *__autoreleasing *)error
{
    NSMutableDictionary *keychainItemQuery = [self keychainItem:keychainItemId];
    
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

#pragma mark - Private Methods

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

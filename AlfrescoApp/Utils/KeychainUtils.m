/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

@implementation KeychainUtils

+ (NSArray *)savedAccountsForListIdentifier:(NSString *)listIdentifier error:(NSError *__autoreleasing *)error
{
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

@end

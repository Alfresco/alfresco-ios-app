//
//  KeychainManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

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

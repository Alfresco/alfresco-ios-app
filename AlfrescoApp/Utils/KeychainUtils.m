//
//  KeychainManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "KeychainUtils.h"

static NSString * const kKeychainAccountListIdentifier = @"AccountList";
static NSString * const kKeychainServiceName = @"com.alfresco.mobile.alfrescoapp";

@implementation KeychainUtils

+ (NSArray *)savedAccountsWithError:(NSError *__autoreleasing *)error
{
    NSArray *accountsArray = nil;
    NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : (id)kKeychainServiceName,
                            (__bridge id)kSecAttrGeneric : (id)kKeychainAccountListIdentifier,
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
            *error = [NSError errorWithDomain:@"Error retrieving accounts. No Data found." code:-1 userInfo:nil];
        }
    }
    else
    {
        *error = [NSError errorWithDomain:@"Error retrieving accounts" code:status userInfo:nil];
    }
    return accountsArray;
}

+ (void)updateSavedAccounts:(NSArray *)accounts error:(NSError *__autoreleasing *)updateError
{
    if (accounts)
    {
        NSData *accountsArrayData = [NSKeyedArchiver archivedDataWithRootObject:accounts];
        NSDictionary *searchDictionary = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                           (__bridge id)kSecAttrService : (id)kKeychainServiceName,
                                           (__bridge id)kSecAttrGeneric : (id)kKeychainAccountListIdentifier};
        
        NSDictionary *updateDictionary = @{(__bridge id)kSecValueData : (id)accountsArrayData};
        
        NSArray *accountsList = [self savedAccountsWithError:updateError];
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
        }
        
        if (status != noErr)
        {
            *updateError = [NSError errorWithDomain:@"Error updating the accounts" code:status userInfo:nil];
        }
    }
    else
    {
        *updateError = [NSError errorWithDomain:@"Nil account array" code:-1 userInfo:nil];
    }
}

+ (void)deleteSavedAccountsWithError:(NSError *__autoreleasing *)deleteError
{
    NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : (id)kKeychainServiceName,
                            (__bridge id)kSecAttrGeneric : (id)kKeychainAccountListIdentifier};
    
    OSStatus status = noErr;
    status = SecItemDelete((__bridge CFDictionaryRef)query);
    
    if (status != noErr)
    {
        *deleteError = [NSError errorWithDomain:@"Error deleting accounts" code:status userInfo:nil];
    }
}

@end

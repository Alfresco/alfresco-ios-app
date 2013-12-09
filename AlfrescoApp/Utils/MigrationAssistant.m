//
//  MigrationAssistant.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 28/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MigrationAssistant.h"
#import "AccountInfo.h"
#import "NSData+Base64.h"
#import "RNDecryptor.h"
#import "UserAccount.h"
#import "AccountManager.h"

static NSString * const kOldAppMigrationFilePath = @"AppConfiguration/.migration.plist";
static NSString * oldAppMigrationAbsoluteFilePath = nil;

@interface MigrationAssistant ()

+ (NSString *)oldAppMigrationAbsoluteFilePath;

@end

@implementation MigrationAssistant

#pragma mark - Public Functions

+ (void)runMigrationAssistant
{
    if ([self shouldStartMigration])
    {
        [self migrateAccounts];
    }
}

#pragma mark - Custom Setters

+ (NSString *)oldAppMigrationAbsoluteFilePath
{
    if (!oldAppMigrationAbsoluteFilePath)
    {
        NSString *libraryPathString = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        oldAppMigrationAbsoluteFilePath = [libraryPathString stringByAppendingPathComponent:kOldAppMigrationFilePath];
    }
    
    return oldAppMigrationAbsoluteFilePath;
}

#pragma mark - Private Functions

+ (BOOL)shouldStartMigration
{
    return [[AlfrescoFileManager sharedManager] fileExistsAtPath:[self oldAppMigrationAbsoluteFilePath]];
}

+ (void)migrateAccounts
{
    NSArray *oldAccounts = [NSKeyedUnarchiver unarchiveObjectWithFile:[self oldAppMigrationAbsoluteFilePath]];
    NSMutableArray *migratedAccounts = [NSMutableArray arrayWithCapacity:oldAccounts.count];
    
    for (AccountInfo *oldAccount in oldAccounts)
    {
        [self decryptPasswordOnOldAccount:oldAccount];
        UserAccount *account = [self createUserAccountFromOldAccount:oldAccount];
        [migratedAccounts addObject:account];
    }
    
    [[AccountManager sharedManager] addAccounts:migratedAccounts];
    
    [self removeLegacyAccounts];
}

+ (void)removeLegacyAccounts
{
    NSError *oldAccountPlistRemovalError = nil;
    [[AlfrescoFileManager sharedManager] removeItemAtPath:[self oldAppMigrationAbsoluteFilePath] error:&oldAccountPlistRemovalError];
    
    if (oldAccountPlistRemovalError)
    {
        AlfrescoLogError(@"Unable to remove the existing accounts plist file. Error: %@", oldAccountPlistRemovalError.localizedDescription);
    }
}

+ (void)decryptPasswordOnOldAccount:(AccountInfo *)oldAccount
{
    NSData *encryptedPasswordData = [NSData dataFromBase64String:oldAccount.password];
    
    NSError *decryptionError = nil;
    NSData *decryptedPasswordData = [RNDecryptor decryptData:encryptedPasswordData withPassword:DECRYPTION_KEY error:&decryptionError];
    
    if (decryptionError)
    {
        AlfrescoLogDebug(@"Error trying to decrypt password for %@. Error: %@", oldAccount.description, decryptionError.localizedDescription);
    }
    
    oldAccount.password = [[NSString alloc] initWithData:decryptedPasswordData encoding:NSUTF8StringEncoding];
}

+ (UserAccount *)createUserAccountFromOldAccount:(AccountInfo *)oldAccount
{
    UserAccount *account = [[UserAccount alloc] init];
    if ([oldAccount.multitenant boolValue])
    {
        account.accountType = UserAccountTypeCloud;
    }
    else
    {
        account.username = oldAccount.username;
        account.password = oldAccount.password;
        account.serverAddress = oldAccount.hostname;
        account.serverPort = oldAccount.port;
        account.protocol = oldAccount.protocol;
        account.serviceDocument = oldAccount.serviceDocumentRequestPath;
    }
    account.accountDescription = oldAccount.description;
    account.isSelectedAccount = NO;
    return account;
}

@end

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
 
#import "MigrationAssistant.h"
#import "AccountInfo.h"
#import "NSData+Base64.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "KeychainUtils.h"
#import "AppDelegate.h"

static NSString * const kOldAccountListIdentifier = @"AccountList";
static NSString * const kOldAccountCMISServicePath = @"/service/cmis";

@interface MigrationAssistant ()

@end

@implementation MigrationAssistant

#pragma mark - Public Functions

+ (void)runMigrationAssistant
{
    if ([self shouldStartAccountMigration])
    {
        [self migrateAccounts];
        [self migrateLegacyAppDownloadedFiles];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] updateAppFirstLaunchFlag];
    }
}

+ (void)runDownloadsMigration
{
    if ([self shouldStartDownloadFolderMigration])
    {
        [self migrateDownloadsToSharedContainer];
    }
}

#pragma mark - Private Functions

#pragma mark Legacy Account Migration

+ (BOOL)shouldStartAccountMigration
{
    BOOL shouldMigrateAccounts = NO;
    
    NSError *oldAccountRetrieveError = nil;
    NSArray *oldAccounts = [KeychainUtils savedAccountsForListIdentifier:kOldAccountListIdentifier error:&oldAccountRetrieveError];
    
    if ([[AccountManager sharedManager] totalNumberOfAddedAccounts] <= 0 && (oldAccounts && !oldAccountRetrieveError))
    {
        shouldMigrateAccounts = YES;
    }
    
    return shouldMigrateAccounts;
}

+ (void)migrateAccounts
{
    NSError *oldAccountRetrieveError = nil;
    NSArray *oldAccounts = [KeychainUtils savedAccountsForListIdentifier:kOldAccountListIdentifier error:&oldAccountRetrieveError];
    
    NSMutableArray *migratedAccounts = [NSMutableArray arrayWithCapacity:oldAccounts.count];
    
    for (AccountInfo *oldAccount in oldAccounts)
    {
        UserAccount *account = [self createUserAccountFromOldAccount:oldAccount];
        if (account != nil)
        {
            [migratedAccounts addObject:account];
        }
    }
    
    [[AccountManager sharedManager] addAccounts:migratedAccounts];
    
    [self removeLegacyAccounts];
}

+ (void)removeLegacyAccounts
{
    NSError *removalError = nil;
    [KeychainUtils deleteSavedAccountsForListIdentifier:kOldAccountListIdentifier error:&removalError];
    
    if (removalError)
    {
        AlfrescoLogError(@"Unable to remove old accounts. Error: %@", removalError.localizedDescription);
    }
}

+ (UserAccount *)createUserAccountFromOldAccount:(AccountInfo *)oldAccount
{
    UserAccount *account = [[UserAccount alloc] init];
    if ([oldAccount.multitenant boolValue])
    {
        account.accountType = UserAccountTypeCloud;
        if (oldAccount.accountStatus == FDAccountStatusAwaitingVerification)
        {
            account.cloudAccountId = oldAccount.cloudId;
            account.cloudAccountKey = oldAccount.cloudKey;
            if (account.cloudAccountId == nil || account.cloudAccountKey == nil)
            {
                // Invalid cloud sign-up; don't migrate the account
                return nil;
            }
        }
    }
    else
    {
        account.username = oldAccount.username;
        account.password = oldAccount.password;
        account.serverAddress = oldAccount.hostname;
        account.serverPort = oldAccount.port;
        account.protocol = oldAccount.protocol;
        account.serviceDocument = oldAccount.serviceDocumentRequestPath;
        if (account.serviceDocument && [account.serviceDocument rangeOfString:kOldAccountCMISServicePath].location != NSNotFound)
        {
            account.serviceDocument = [account.serviceDocument stringByReplacingOccurrencesOfString:kOldAccountCMISServicePath withString:@""];
        }
    }
    account.accountDescription = oldAccount.description;
    account.isSelectedAccount = NO;
    return account;
}

// Moves downloads from the legacy app (v1.5) to the the updated Downloads location
+ (void)migrateLegacyAppDownloadedFiles
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    
    NSError *documentsFolderContentError = nil;
    NSArray *documentsContent = [fileManager contentsOfDirectoryAtPath:fileManager.documentsDirectory error:&documentsFolderContentError];
    
    if (!documentsFolderContentError)
    {
        for (NSString *fileName in documentsContent)
        {
            BOOL isDirectory = NO;
            NSString *absoluteSourceFilePath = [fileManager.documentsDirectory stringByAppendingPathComponent:fileName];
            
            if ([fileManager fileExistsAtPath:absoluteSourceFilePath isDirectory:&isDirectory])
            {
                if (!isDirectory && ![fileName hasPrefix:@"."])
                {
                    NSError *moveError = nil;
                    NSString *absoluteTargetPath = [fileManager.downloadsContentFolderPath stringByAppendingPathComponent:fileName];
                    [fileManager moveItemAtPath:absoluteSourceFilePath toPath:absoluteTargetPath error:&moveError];
                    
                    if (moveError)
                    {
                        AlfrescoLogError(@"Unable to move item at path: %@ to %@", absoluteSourceFilePath, absoluteTargetPath);
                    }
                }
            }
        }
    }
    else
    {
        AlfrescoLogError(@"Unable to retrieve documents folder");
    }
    
}

#pragma mark Downloads Folder Migration

+ (BOOL)shouldStartDownloadFolderMigration
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    
    BOOL shouldMigrateDownloads = NO;
    
    if ([fileManager fileExistsAtPath:fileManager.legacyDownloadsFolderPath])
    {
        shouldMigrateDownloads = YES;
    }
    
    return shouldMigrateDownloads;
}

+ (void)migrateDownloadsToSharedContainer
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    
    NSString *sourcePath = fileManager.legacyDownloadsFolderPath;
    NSString *destinationPath = fileManager.downloadsFolderPath;
    
    NSError *moveError = nil;
    [fileManager moveItemAtPath:sourcePath toPath:destinationPath error:&moveError];
    
    if (moveError)
    {
        AlfrescoLogError(@"Unable to migrate Downloads folder from source location: %@, to destination location: %@. Error: %@", sourcePath, destinationPath, moveError.localizedDescription);
    }
}

@end

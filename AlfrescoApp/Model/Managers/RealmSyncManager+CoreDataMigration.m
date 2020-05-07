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

#import "RealmSyncManager+CoreDataMigration.h"

#import <CoreData/CoreData.h>
#import "AccountManager.h"
#import "CoreDataSyncHelper.h"
#import "SyncManager.h"

#import "SyncNodeInfo.h"
#import "SyncError.h"
#import "SyncAccount.h"

#import "RealmSyncNodeInfo.h"
#import "RealmSyncError.h"

@implementation RealmSyncManager (CoreDataMigration)

- (BOOL)isCoreDataMigrationNeeded
{
    BOOL isMigrationNeededResult = ![[NSUserDefaults standardUserDefaults] objectForKey:kHasCoreDataMigrationOccurred] && [self hasSyncContentToMigrate];
    
    return isMigrationNeededResult;
}

- (BOOL)hasSyncContentToMigrate
{
    BOOL hasSyncContentToMigrate = NO;
    //creating a background context
    CoreDataSyncHelper *coreDataSyncHelper = [CoreDataSyncHelper new];
    NSManagedObjectContext *privateContext = [coreDataSyncHelper createChildManagedObjectContext];
    
    for(UserAccount *account in [[AccountManager sharedManager] allAccounts])
    {
        if(account.isSyncOn)
        {
            if([self hasSyncContentToMigrateInAccount:account usingContext:privateContext])
            {
                hasSyncContentToMigrate = YES;
                break;
            }
        }
    }
    
    return hasSyncContentToMigrate;
}

- (BOOL)hasSyncContentToMigrateInAccount:(UserAccount *)userAccount usingContext:(NSManagedObjectContext *)privateContext
{
    BOOL hasContent = NO;
    NSFetchRequest *accountRequest = [[NSFetchRequest alloc] initWithEntityName:@"SyncAccount"];
    NSPredicate *specificAccountPredicate = [NSPredicate predicateWithFormat:@"accountId == %@", userAccount.accountIdentifier];
    [accountRequest setPredicate:specificAccountPredicate];
    
    __block NSArray *coreDataAccountRecord = nil;
    __block NSError *coreDataAccountFetchError = nil;
    
    //getting the account information from core data
    [privateContext performBlockAndWait:^{
        coreDataAccountRecord = [privateContext executeFetchRequest:accountRequest error:&coreDataAccountFetchError];
    }];
    
    if(coreDataAccountRecord.count > 0)
    {
        hasContent = YES;
    }
    
    return hasContent;
}

- (BOOL)shouldShowSyncInfoPanel
{
    BOOL isSyncEnabled = NO;
    for(UserAccount *account in [[AccountManager sharedManager] allAccounts])
    {
        if(account.isSyncOn)
        {
            isSyncEnabled = YES;
        }
    }
    
    BOOL hasCoreDataMigrationOccured = [[[NSUserDefaults standardUserDefaults] objectForKey:kHasCoreDataMigrationOccurred] boolValue];
    BOOL shouldShowSyncInfoPanelResult = ((![[NSUserDefaults standardUserDefaults] objectForKey:kWasSyncInfoPanelShown]) && isSyncEnabled && hasCoreDataMigrationOccured);
    return shouldShowSyncInfoPanelResult;
}

- (void)initiateMigrationProcess
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for(UserAccount *account in [[AccountManager sharedManager] allAccounts])
        {
            if(account.isSyncOn)
            {
                [self migrateAccount:account];
            }
        }
        
        [self cleanCoreData];
    });
}

- (void)migrateAccount:(UserAccount *)account
{
    //creating a background context
    CoreDataSyncHelper *coreDataSyncHelper = [CoreDataSyncHelper new];
    NSManagedObjectContext *privateContext = [coreDataSyncHelper createChildManagedObjectContext];
    
    NSFetchRequest *accountRequest = [[NSFetchRequest alloc] initWithEntityName:@"SyncAccount"];
    NSPredicate *specificAccountPredicate = [NSPredicate predicateWithFormat:@"accountId == %@", account.accountIdentifier];
    [accountRequest setPredicate:specificAccountPredicate];
    
    __block NSArray *coreDataAccountRecord = nil;
    __block NSError *coreDataAccountFetchError = nil;
    
    //getting the account information from core data
    [privateContext performBlockAndWait:^{
        coreDataAccountRecord = [privateContext executeFetchRequest:accountRequest error:&coreDataAccountFetchError];
    }];
    
    if(coreDataAccountFetchError)
    {
        AlfrescoLogDebug(@"Error with core data account fetch for migration: %@", coreDataAccountFetchError);
    }
    else if(coreDataAccountRecord.count > 0)
    {
        RLMRealm *realm = [self realmForAccount:account.accountIdentifier];
        
        NSMutableArray *objectsToAddToRealm = [NSMutableArray new];
        NSMutableDictionary *parentNodeMappingDictionary = [NSMutableDictionary new];
        
        SyncAccount *coreDataSyncAccount = coreDataAccountRecord[0];
        for(SyncNodeInfo *coreDataSyncNodeInfo in coreDataSyncAccount.nodes)
        {
            RealmSyncError *newSyncError = nil;
            if(coreDataSyncNodeInfo.syncError)
            {
                newSyncError = [RealmSyncError new];
                newSyncError.errorCode = coreDataSyncNodeInfo.syncError.errorCode.integerValue;
                newSyncError.errorDescription = coreDataSyncNodeInfo.syncError.errorDescription;
                newSyncError.errorId = coreDataSyncNodeInfo.syncError.errorId;
                
                [objectsToAddToRealm addObject:newSyncError];
            }
            
            if(coreDataSyncNodeInfo.parentNode)
            {
                parentNodeMappingDictionary[coreDataSyncNodeInfo.syncNodeInfoId] = coreDataSyncNodeInfo.parentNode.syncNodeInfoId;
            }
            
            RealmSyncNodeInfo *newSyncNodeInfo = [RealmSyncNodeInfo new];
            newSyncNodeInfo.isFolder = coreDataSyncNodeInfo.isFolder.boolValue;
            newSyncNodeInfo.isRemovedFromSyncHasLocalChanges = coreDataSyncNodeInfo.isRemovedFromSyncHasLocalChanges.boolValue;
            newSyncNodeInfo.isTopLevelSyncNode = coreDataSyncNodeInfo.isTopLevelSyncNode.boolValue;
            newSyncNodeInfo.lastDownloadedDate = coreDataSyncNodeInfo.lastDownloadedDate;
            newSyncNodeInfo.node = coreDataSyncNodeInfo.node;
            newSyncNodeInfo.permissions = coreDataSyncNodeInfo.permissions;
            newSyncNodeInfo.reloadContent = coreDataSyncNodeInfo.reloadContent.boolValue;
            newSyncNodeInfo.syncContentPath = [self relativeSyncPath:coreDataSyncNodeInfo.syncContentPath];
            newSyncNodeInfo.syncNodeInfoId = coreDataSyncNodeInfo.syncNodeInfoId;
            newSyncNodeInfo.title = coreDataSyncNodeInfo.title;
            
            newSyncNodeInfo.syncError = newSyncError;
            
            [objectsToAddToRealm addObject:newSyncNodeInfo];
        }
        
        if(objectsToAddToRealm.count > 0)
        {
            [realm beginWriteTransaction];
            for(RLMObject *object in objectsToAddToRealm)
            {
                [realm addOrUpdateObject:object];
            }
            NSError *writeError = nil;
            [realm commitWriteTransaction:&writeError];
            if(writeError)
            {
                AlfrescoLogDebug(@"Error with realm transaction: %@", writeError);
            }
        }
        
        if([parentNodeMappingDictionary allKeys].count > 0)
        {
            [realm beginWriteTransaction];
            for(NSString *key in [parentNodeMappingDictionary allKeys])
            {
                RLMResults *firstObjectResult = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncNodeInfoId == %@", key];
                RealmSyncNodeInfo *firstNode = firstObjectResult.firstObject;
                RLMResults *secondObjectResult = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncNodeInfoId == %@", parentNodeMappingDictionary[key]];
                RealmSyncNodeInfo *secondNode = secondObjectResult.firstObject;
                firstNode.parentNode = secondNode;
            }
            NSError *writeError = nil;
            [realm commitWriteTransaction:&writeError];
            if(writeError)
            {
                AlfrescoLogDebug(@"Error with realm transaction: %@", writeError);
            }
        }
    }
}

- (void)cleanCoreData
{
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kHasCoreDataMigrationOccurred];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //creating a background context
    CoreDataSyncHelper *coreDataSyncHelper = [CoreDataSyncHelper new];
    NSManagedObjectContext *privateContext = [coreDataSyncHelper createChildManagedObjectContext];
    
    NSFetchRequest *accountRequest = [[NSFetchRequest alloc] initWithEntityName:@"SyncAccount"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:accountRequest];
    
    //deleting all core data sync information
    __block NSError *deleteError = nil;
    
    [privateContext performBlockAndWait:^{
        [privateContext executeRequest:delete error:&deleteError];
    }];
}

// this parses a path to get the relative path to the Sync folder
- (NSString *)relativeSyncPath:(NSString *)oldPath
{
    NSString *newPath = nil;
    NSArray *array = [oldPath componentsSeparatedByString:[NSString stringWithFormat:@"%@/",kSyncFolder]];
    if(array.count >= 2)
    {
        newPath = array[1];
    }
    
    return newPath;
}

@end

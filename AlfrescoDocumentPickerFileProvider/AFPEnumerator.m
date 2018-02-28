/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
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

#import "AFPEnumerator.h"
#import "AFPItemIdentifier.h"
#import "AFPItem.h"
#import "CustomFolderService.h"
#import "AFPAccountManager.h"
#import "FavouriteManager.h"
#import "AFPDataManager.h"
#import "KeychainUtils.h"
#import "AlfrescoFileManager+Extensions.h"

@interface AFPEnumerator()

@property (nonatomic, strong) NSURLRequest *currentRequest;
@property (nonatomic, strong) id<NSFileProviderEnumerationObserver> observer;
@property (nonatomic, strong) AFPAccountManager *accountManager;

@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) CustomFolderService *customFolderService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;

@end

@implementation AFPEnumerator

- (instancetype)initWithEnumeratedItemIdentifier:(NSFileProviderItemIdentifier)enumeratedItemIdentifier
{
    if (self = [super init])
    {
        _enumeratedItemIdentifier = enumeratedItemIdentifier;
        self.accountManager = [AFPAccountManager new];
    }
    return self;
}

- (AlfrescoSiteService *)siteService
{
    if(_siteService)
    {
        [_siteService clear];
    }
    
    return _siteService;
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    self.observer = observer;
    
    if([self.enumeratedItemIdentifier isEqualToString:NSFileProviderRootContainerItemIdentifier])
    {
        [self enumerateItemsInRootContainer];
    }
    else if([self.enumeratedItemIdentifier isEqualToString:kFileProviderLocalFilesPrefix])
    {
        [self enumerateItemsInLocalFiles];
    }
    else
    {
        NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.enumeratedItemIdentifier];
        [self.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
            if(loginError)
            {
                [self.observer finishEnumeratingWithError:loginError];
            }
            else
            {
                [self createServicesWithSession:session];
                AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:self.enumeratedItemIdentifier];
                switch (identifierType) {
                    case AlfrescoFileProviderItemIdentifierTypeAccount:
                    {
                        [self enumerateItemsInAccount];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeMyFiles:
                    {
                        [self enumerateItemsInMyFilesWithSession:session];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeSharedFiles:
                    {
                        [self enumerateItemsInSharedFilesWithSession:session];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeFolder:
                    {
                        NSString *folderRef = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:self.enumeratedItemIdentifier];
                        [self enumerateItemsInFolderWithFolderRef:folderRef withSession:session];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeFavorites:
                    {
                        [self enumerateItemsInFavoriteFolderWithSession:session];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeSites:
                    {
                        [self enumerateItemsInSites];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeMySites:
                    {
                        [self enumerateItemsInMySitesWithSession:session];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeSite:
                    {
                        NSString *siteShortName = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:self.enumeratedItemIdentifier];
                        [self enumerateItemsInSiteWithSiteShortName:siteShortName withSession:session];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeFavoriteSites:
                    {
                        [self enumerateItemsInFavoriteSitesWithSession:session];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeSynced:
                    {
                        [self enumerateItemsInSyncedFolder];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeSyncNode:
                    {
                        NSString *nodeId = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:self.enumeratedItemIdentifier];
                        [self enumerateItemsInSyncedFolderWithIdentifier:nodeId];
                        break;
                    }
                    default:
                        break;
                }
            }
        }];
    }
}

- (void)enumerateChangesForObserver:(id<NSFileProviderChangeObserver>)observer fromSyncAnchor:(NSFileProviderSyncAnchor)anchor
{
    /* TODO:
     - query the server for updates since the passed-in sync anchor
     
     If this is an enumerator for the active set:
     - note the changes in your local database
     
     - inform the observer about item deletions and updates (modifications + insertions)
     - inform the observer when you have finished enumerating up to a subsequent sync anchor
     */
}

#pragma mark - Private methods
- (NSArray *)getAccountFromKeychain
{
    NSError *keychainError = nil;
    NSArray *accounts = [KeychainUtils savedAccountsForListIdentifier:kAccountsListIdentifier error:&keychainError];
    
    if (keychainError)
    {
        AlfrescoLogError(@"Error retreiving accounts. Error: %@", keychainError.localizedDescription);
    }
    
    return accounts;
}

- (void)createServicesWithSession:(id<AlfrescoSession>)session
{
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
    self.customFolderService = [[CustomFolderService alloc] initWithSession:session];
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
}

- (void)handleEnumeratedSitesWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (error)
    {
        [self.observer finishEnumeratingWithError:error];
    }
    else
    {
        NSMutableArray *enumeratedResults = [NSMutableArray new];
        for(AlfrescoSite *site in pagingResult.objects)
        {
            AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] saveSite:site parentIdentifier:self.enumeratedItemIdentifier];
            AFPItem *item = [[AFPItem alloc] initWithItemMetadata:itemMetadata];
            [enumeratedResults addObject:item];
        }
        
        [self.observer didEnumerateItems:enumeratedResults];
        [self.observer finishEnumeratingUpToPage:nil];
    }
}

- (void)handleEnumeratedFolderWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (!error)
    {
        NSMutableArray *fileProviderItems = [NSMutableArray new];
        for (AlfrescoNode *node in pagingResult.objects)
        {
            AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] saveNode:node parentIdentifier:self.enumeratedItemIdentifier];
            AFPItem *item = [[AFPItem alloc] initWithItemMetadata:itemMetadata];
            [fileProviderItems addObject:item];
        }
        [self.observer didEnumerateItems:fileProviderItems];
        [self.observer finishEnumeratingUpToPage:nil];
    }
    else
    {
        [self.observer finishEnumeratingWithError:error];
    }
}

- (void)handleEnumeratedCustomFolder:(AlfrescoNode *)node error:(NSError *)error session:(id<AlfrescoSession>)session {
    if (error)
    {
        [self.observer finishEnumeratingWithError:error];
    }
    else if ([node isKindOfClass:[AlfrescoFolder class]])
    {
        [self enumerateItemsInFolder:(AlfrescoFolder *)node withSession:session];
    }
}

#pragma mark - Enumeration methods
- (void)enumerateItemsInMyFilesWithSession:(id<AlfrescoSession>)session
{
    [self.customFolderService retrieveMyFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        [self handleEnumeratedCustomFolder:folder error:error session:session];
    }];
}

- (void)enumerateItemsInSharedFilesWithSession:(id<AlfrescoSession>)session
{
    [self.customFolderService retrieveSharedFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        [self handleEnumeratedCustomFolder:folder error:error session:session];
    }];
}

- (void)enumerateItemsInFolderWithFolderRef:(NSString *)folderRef withSession:(id<AlfrescoSession>)session
{
    [self.documentService retrieveNodeWithIdentifier:folderRef completionBlock:^(AlfrescoNode *nodeRefNode, NSError *nodeRefError) {
        [self handleEnumeratedCustomFolder:nodeRefNode error:nodeRefError session:session];
    }];
}

- (void)enumerateItemsInFavoriteFolderWithSession:(id<AlfrescoSession>)session
{
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    [self.documentService retrieveFavoriteNodesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self handleEnumeratedFolderWithPagingResult:pagingResult error:error];
    }];
}

- (void)enumerateItemsInFolder:(AlfrescoFolder *)folder withSession:(id<AlfrescoSession>)session
{
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    [self.documentService retrieveChildrenInFolder:folder listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self handleEnumeratedFolderWithPagingResult:pagingResult error:error];
    }];
}

- (void)enumerateItemsInSites
{
    NSMutableArray *enumeratedResults = [NSMutableArray new];
    RLMResults<AFPItemMetadata *> *results = [[AFPDataManager sharedManager] menuItemsForParentIdentifier:self.enumeratedItemIdentifier];
    for(AFPItemMetadata *result in results)
    {
        AFPItem *item = [[AFPItem alloc] initWithItemMetadata:result];
        [enumeratedResults addObject:item];
    }
    
    [self.observer didEnumerateItems:enumeratedResults];
    [self.observer finishEnumeratingUpToPage:nil];
}

- (void)enumerateItemsInMySitesWithSession:(id<AlfrescoSession>)session
{
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    [self.siteService retrieveSitesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self handleEnumeratedSitesWithPagingResult:pagingResult error:error];
    }];
}

- (void)enumerateItemsInFavoriteSitesWithSession:(id<AlfrescoSession>)session
{
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    [self.siteService retrieveFavoriteSitesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self handleEnumeratedSitesWithPagingResult:pagingResult error:error];
    }];
}

- (void)enumerateItemsInSiteWithSiteShortName:(NSString *)siteShortName withSession:(id<AlfrescoSession>)session
{
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
    [self.siteService retrieveDocumentLibraryFolderForSite:siteShortName completionBlock:^(AlfrescoFolder *folder, NSError *error) {
        if (folder)
        {
            [self enumerateItemsInFolder:folder withSession:session];
        }
        else
        {
            [self.observer finishEnumeratingWithError:error];
        }
    }];
}

- (void)enumerateItemsInAccount
{
    NSMutableArray *enumeratedFolders = [NSMutableArray new];
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.enumeratedItemIdentifier];
    RLMResults<AFPItemMetadata *> *menuItems = [[AFPDataManager sharedManager] menuItemsForAccount:accountIdentifier];
    for(AFPItemMetadata *menuItem in menuItems)
    {
        AFPItem *item = [[AFPItem alloc] initWithItemMetadata:menuItem];
        [enumeratedFolders addObject:item];
    }
    
    [self.observer didEnumerateItems:enumeratedFolders];
    [self.observer finishEnumeratingUpToPage:nil];
}

- (void)enumerateItemsInRootContainer
{
    NSArray *accounts = [self getAccountFromKeychain];
    NSMutableArray *enumeratedAccounts = [NSMutableArray new];
    for(UserAccount *account in accounts)
    {
        AFPItem *fpItem = [[AFPItem alloc] initWithUserAccount:account];
        [enumeratedAccounts addObject:fpItem];
    }
    
    AFPItem *localFilesItem = [[AFPItem alloc] initWithItemMetadata:[[AFPDataManager sharedManager] localFilesItem]];
    [enumeratedAccounts addObject:localFilesItem];
    
    [self.observer didEnumerateItems:enumeratedAccounts];
    [self.observer finishEnumeratingUpToPage:nil];
}

- (void)enumerateItemsInLocalFiles
{
    __block NSMutableArray *documents = [NSMutableArray array];
    NSError *enumeratorError = nil;
    
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *downloadContentPath = [fileManager downloadsContentFolderPath];
    [fileManager enumerateThroughDirectory:downloadContentPath includingSubDirectories:NO withBlock:^(NSString *fullFilePath) {
        AFPItem *item = [[AFPItem alloc] initWithLocalFilesPath:fullFilePath];
        [documents addObject:item];
    } error:&enumeratorError];
    
    if (enumeratorError)
    {
        AlfrescoLogError(@"Enumeration Error: %@", enumeratorError.localizedDescription);
    }
    
    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^NSComparisonResult(AFPItem *firstDocument, AFPItem *secondDocument) {
        return [firstDocument.filename caseInsensitiveCompare:secondDocument.filename];
    }];
    
    [self.observer didEnumerateItems:[documents sortedArrayUsingDescriptors:@[sortOrder]]];
    [self.observer finishEnumeratingUpToPage:nil];
}

- (void)enumerateItemsInSyncedFolder
{
    [self enumerateItemsInSyncedFolderWithIdentifier:nil];
}

- (void)enumerateItemsInSyncedFolderWithIdentifier:(NSString *)nodeId
{
    NSMutableArray *enumeratedSyncedItems = [NSMutableArray new];
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.enumeratedItemIdentifier];
    
    RLMResults<RealmSyncNodeInfo *> *syncedItems = [[AFPDataManager sharedManager] syncItemsInNodeWithId:nodeId forAccountIdentifier:accountIdentifier];
    for(RealmSyncNodeInfo *node in syncedItems)
    {
        AFPItem *fpItem = [[AFPItem alloc] initWithSyncedNode:node parentItemIdentifier:self.enumeratedItemIdentifier];
        [enumeratedSyncedItems addObject:fpItem];
    }
    
    [self.observer didEnumerateItems:enumeratedSyncedItems];
    [self.observer finishEnumeratingUpToPage:nil];
}

@end

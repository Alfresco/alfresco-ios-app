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

#import "AlfrescoEnumerator.h"
#import "AlfrescoFileProviderItemIdentifier.h"
#import "AlfrescoFileProviderItem.h"
#import "CustomFolderService.h"
#import "FileProviderAccountManager.h"
#import "FavouriteManager.h"
#import "FileProviderDataManager.h"
#import "KeychainUtils.h"

@interface AlfrescoEnumerator()

@property (nonatomic, strong) NSURLRequest *currentRequest;
@property (nonatomic, strong) id<NSFileProviderEnumerationObserver> observer;
@property (nonatomic, strong) FileProviderAccountManager *accountManager;

@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) CustomFolderService *customFolderService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;

@end

@implementation AlfrescoEnumerator

- (instancetype)initWithEnumeratedItemIdentifier:(NSFileProviderItemIdentifier)enumeratedItemIdentifier
{
    if (self = [super init])
    {
        _enumeratedItemIdentifier = enumeratedItemIdentifier;
        self.accountManager = [FileProviderAccountManager new];
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
    else
    {
        NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.enumeratedItemIdentifier];
        [self.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
            if(loginError)
            {
                [self.observer finishEnumeratingWithError:loginError];
            }
            else
            {
                [self createServicesWithSession:session];
                AlfrescoFileProviderItemIdentifierType identifierType = [AlfrescoFileProviderItemIdentifier itemIdentifierTypeForIdentifier:self.enumeratedItemIdentifier];
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
                        NSString *folderRef = [AlfrescoFileProviderItemIdentifier identifierFromItemIdentifier:self.enumeratedItemIdentifier];
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
                        NSString *siteShortName = [AlfrescoFileProviderItemIdentifier identifierFromItemIdentifier:self.enumeratedItemIdentifier];
                        [self enumerateItemsInSiteWithSiteShortName:siteShortName withSession:session];
                        break;
                    }
                    case AlfrescoFileProviderItemIdentifierTypeFavoriteSites:
                    {
                        [self enumerateItemsInFavoriteSitesWithSession:session];
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
            AlfrescoFileProviderItem *item = [[AlfrescoFileProviderItem alloc] initWithSite:site parentItemIdentifier:self.enumeratedItemIdentifier];
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
            AlfrescoFileProviderItem *item = [[AlfrescoFileProviderItem alloc] initWithAlfrescoNode:node parentItemIdentifier:self.enumeratedItemIdentifier];
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
    RLMResults<FileProviderAccountInfo *> *results = [[FileProviderDataManager sharedManager] menuItemsForParentIdentifier:self.enumeratedItemIdentifier];
    for(FileProviderAccountInfo *result in results)
    {
        AlfrescoFileProviderItem *item = [[AlfrescoFileProviderItem alloc] initWithAccountInfo:result];
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
    NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.enumeratedItemIdentifier];
    RLMResults<FileProviderAccountInfo *> *menuItems = [[FileProviderDataManager sharedManager] menuItemsForAccount:accountIdentifier];
    for(FileProviderAccountInfo *menuItem in menuItems)
    {
        AlfrescoFileProviderItem *item = [[AlfrescoFileProviderItem alloc] initWithAccountInfo:menuItem];
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
        AlfrescoFileProviderItem *fpItem = [[AlfrescoFileProviderItem alloc] initWithUserAccount:account];
        [enumeratedAccounts addObject:fpItem];
    }
    
    [self.observer didEnumerateItems:enumeratedAccounts];
    [self.observer finishEnumeratingUpToPage:nil];
}

@end

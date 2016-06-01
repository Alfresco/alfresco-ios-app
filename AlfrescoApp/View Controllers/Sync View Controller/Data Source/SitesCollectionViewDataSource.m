/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

#import "SitesCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"

//@property (nonatomic, strong) CustomFolderService *customFolderService;

@interface SitesCollectionViewDataSource()

@property (nonatomic, strong) NSString *siteShortName;
@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) AlfrescoListingContext *defaultListingContext;

@end

@implementation SitesCollectionViewDataSource

- (instancetype)initWithSiteShortname:(NSString *)siteShortName session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.delegate = delegate;
    self.siteShortName = siteShortName;
    self.session = session;
    
    __weak typeof(self) weakSelf = self;
    [self.siteService retrieveDocumentLibraryFolderForSite:self.siteShortName completionBlock:^(AlfrescoFolder *documentLibraryFolder, NSError *documentLibraryFolderError) {
        if (documentLibraryFolderError)
        {
            [weakSelf.delegate requestFailedWithError:documentLibraryFolderError stringFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found")];
        }
        else
        {
            self.parentNode = documentLibraryFolder;
            [self.siteService retrieveSiteWithShortName:self.siteShortName completionBlock:^(AlfrescoSite *site, NSError *error) {
                self.screenTitle = site.title;
            }];
            [self retrieveContentOfFolder:documentLibraryFolder usingListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                // folder permissions not set, retrieve and update the UI
                if (!self.parentFolderPermissions)
                {
                    [self retrieveAndSetPermissionsOfCurrentFolder];
                }
                else
                {
                    [self.delegate didRetrievePermissionsForParentNode];
                }

                [self reloadCollectionViewWithPagingResult:pagingResult error:error];
            }];
        }
    }];
    
    return self;
}

- (void)setSession:(id<AlfrescoSession>)session
{
    [super setSession:session];
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
}

- (void)retrieveContentOfFolder:(AlfrescoFolder *)folder usingListingContext:(AlfrescoListingContext *)listingContext completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock;
{
    if (!listingContext)
    {
        listingContext = self.defaultListingContext;
    }
    
    [self.documentService retrieveChildrenInFolder:folder listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        if (!error)
        {
            for (AlfrescoNode *node in pagingResult.objects)
            {
                [self retrievePermissionsForNode:node];
            }
        }
        if (completionBlock != NULL)
        {
            completionBlock(pagingResult, error);
        }
    }];
}

@end

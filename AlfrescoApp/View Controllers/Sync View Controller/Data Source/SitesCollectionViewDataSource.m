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

#import "SitesCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"

@interface SitesCollectionViewDataSource()

@property (nonatomic, strong) NSString *siteShortName;
@property (nonatomic, strong) AlfrescoSiteService *siteService;

@end

@implementation SitesCollectionViewDataSource

- (instancetype)initWithSiteShortname:(NSString *)siteShortName session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.shouldAllowMultiselect = YES;
    self.delegate = delegate;
    self.siteShortName = siteShortName;
    self.session = session;
    
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    
    [self reloadDataSource];
    
    return self;
}

- (void)setSession:(id<AlfrescoSession>)session
{
    [super setSession:session];
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
}

- (void)reloadDataSource
{
    __weak typeof(self) weakSelf = self;
    [self.siteService retrieveDocumentLibraryFolderForSite:self.siteShortName completionBlock:^(AlfrescoFolder *documentLibraryFolder, NSError *documentLibraryFolderError) {
        if (documentLibraryFolder)
        {
            self.parentNode = documentLibraryFolder;
            [self.siteService retrieveSiteWithShortName:self.siteShortName completionBlock:^(AlfrescoSite *site, NSError *error) {
                self.screenTitle = site.title;
            }];
            
            [self retrieveContentsOfParentNode];
        }
        else
        {
            NSString *stringFormat = NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found");
            
            if (documentLibraryFolderError == nil)
            {
                stringFormat = NSLocalizedString(@"error.generic.noaccess.message", @"You might not have access to all views in this profile. Check with your IT Team or choose a different profile. ");
            }
            [weakSelf.delegate requestFailedWithError:documentLibraryFolderError stringFormat:stringFormat];
        }
    }];
}

@end

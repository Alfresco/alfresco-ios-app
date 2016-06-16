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

#import "SearchCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"

@interface SearchCollectionViewDataSource ()

@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, strong) AlfrescoKeywordSearchOptions *searchOptions;

@end

@implementation SearchCollectionViewDataSource

- (instancetype)initWithSearchStatement:(NSString *)searchStatement session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.session = session;
    self.delegate = delegate;
    
    __weak typeof(self) weakSelf = self;
    [self.searchService searchWithStatement:searchStatement language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *array, NSError *error) {
        if(array)
        {
            weakSelf.dataSourceCollection = [array mutableCopy];
            [weakSelf.delegate dataSourceUpdated];
        }
        else
        {
            [weakSelf.delegate requestFailedWithError:error stringFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed")];
        }
    }];
    
    return self;
}

- (instancetype)initWithSearchString:(NSString *)searchString searchOptions:(AlfrescoKeywordSearchOptions *)options emptyMessage:(NSString *)emptyMessage session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.emptyMessage = emptyMessage;
    self.session = session;
    self.delegate = delegate;
    
    __weak typeof(self) weakSelf = self;
    [self.searchService searchWithKeywords:searchString options:options completionBlock:^(NSArray *array, NSError *error) {
        if (array)
        {
//            self.isOnSearchResults = isFromSearchBar;
//            if(isFromSearchBar)
//            {
//                self.searchResults = [array mutableCopy];
//            }
//            else
//            {
//                self.collectionViewData = [array mutableCopy];
//            }
//            [self reloadCollectionView];
            
            weakSelf.dataSourceCollection = [array mutableCopy];
            [weakSelf.delegate dataSourceUpdated];
        }
        else
        {
            [weakSelf.delegate requestFailedWithError:error stringFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed")];
        }
    }];
    
    return self;
}

- (void)setSession:(id<AlfrescoSession>)session
{
    if(session)
    {
        [super setSession:session];
        self.searchService = [[AlfrescoSearchService alloc] initWithSession:self.session];
    }
}

@end

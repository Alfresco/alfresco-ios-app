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

#import "SearchCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"

@interface SearchCollectionViewDataSource ()

@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, strong) AlfrescoKeywordSearchOptions *searchOptions;
@property (nonatomic, strong) NSString *searchStatement;
@property (nonatomic, strong) NSString *searchString;

@end

@implementation SearchCollectionViewDataSource

- (instancetype)initWithSearchStatement:(NSString *)searchStatement session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.session = session;
    self.delegate = delegate;
    self.searchStatement = searchStatement;
    self.shouldAllowLayoutChange = NO;
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    
    [self reloadDataSource];
    
    return self;
}

- (instancetype)initWithSearchString:(NSString *)searchString searchOptions:(AlfrescoKeywordSearchOptions *)options emptyMessage:(NSString *)emptyMessage session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.emptyMessage = emptyMessage;
    self.session = session;
    self.delegate = delegate;
    self.searchString = searchString;
    self.searchOptions = options;
    self.shouldAllowLayoutChange = NO;
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    
    [self reloadDataSource];
    
    return self;
}

- (void)setSession:(id<AlfrescoSession>)session
{
    if(session)
    {
        [super setSession:session];
        self.searchService = [[AlfrescoSearchService alloc] initWithSession:self.session];
        self.shouldAllowMultiselect = YES;
    }
}

#pragma mark - Public Methods

- (void)retrieveNextItems:(AlfrescoListingContext *)moreListingContext
{
    __weak typeof(self) weakSelf = self;
    
    void (^completionBlock)(AlfrescoPagingResult *, NSError *) = ^void(AlfrescoPagingResult *pagingResult, NSError *error){
        if(pagingResult)
        {
            if (self.dataSourceCollection == nil)
            {
                self.dataSourceCollection = [NSMutableArray array];
            }
            [self.dataSourceCollection addObjectsFromArray:pagingResult.objects];
            
            self.moreItemsAvailable = pagingResult.hasMoreItems;
            [weakSelf.delegate dataSourceUpdated];
        }
        else
        {
            NSString *stringFormat = NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed");
            
            if (error == nil)
            {
                stringFormat = NSLocalizedString(@"error.generic.noaccess.message", @"You might not have access to all views in this profile. Check with your IT Team or choose a different profile. ");
            }
            
            [weakSelf.delegate requestFailedWithError:error stringFormat:stringFormat];
        }
    };
    
    if (self.searchStatement)
    {
        [self.searchService searchWithStatement:self.searchStatement language:AlfrescoSearchLanguageCMIS listingContext:moreListingContext completionBlock:completionBlock];
    }
    else if (self.searchString)
    {
        [self.searchService searchWithKeywords:self.searchString options:self.searchOptions listingContext:moreListingContext completionBlock:completionBlock];
    }
}

- (void)reloadDataSource
{
    [self.dataSourceCollection removeAllObjects];
    [self retrieveNextItems:self.defaultListingContext];
}

- (NSString*)getSearchType
{
    return (self.searchOptions) ? self.searchOptions.typeName : [super getSearchType];
}

@end

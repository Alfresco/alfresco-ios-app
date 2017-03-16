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

#import "SearchResultsTableViewDataSource.h"
#import "PreferenceManager.h"

@interface SearchResultsTableViewDataSource ()

@property (nonatomic) SearchViewControllerDataSourceType dataSourceType;
@property (nonatomic, strong) NSString *searchString;
@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) AlfrescoSiteService *siteService;

@end

@implementation SearchResultsTableViewDataSource

- (instancetype)initWithDataSourceType:(SearchViewControllerDataSourceType)dataSourceType searchString:(NSString *)searchString session:(id<AlfrescoSession>)session delegate:(id<SearchResultsTableViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext
{
    if (self = [super init])
    {
        self.dataSourceType = dataSourceType;
        self.searchString = searchString;
        self.session = session;
        self.delegate = delegate;
        
        if (listingContext)
        {
            self.defaultListingContext = listingContext;
        }
        else
        {
            self.defaultListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:0];
        }
        
        switch (self.dataSourceType)
        {
            case SearchViewControllerDataSourceTypeSearchFiles:
            case SearchViewControllerDataSourceTypeSearchFolders:
            {
                self.searchService = [[AlfrescoSearchService alloc] initWithSession:self.session];
            }
                break;
                
            case SearchViewControllerDataSourceTypeSearchUsers:
            {
                self.personService = [[AlfrescoPersonService alloc] initWithSession:self.session];
            }
                break;
                
            case SearchViewControllerDataSourceTypeSearchSites:
            {
                self.siteService = [[AlfrescoSiteService alloc] initWithSession:self.session];
            }
                break;
                
            default:
                break;
        }
        
        [self reloadDataSource];
    }
    
    return self;
}

- (instancetype)initWithDataSourceType:(SearchViewControllerDataSourceType)dataSourceType results:(NSArray *)results delegate:(id<SearchResultsTableViewDataSourceDelegate>)delegate
{
    if (self = [super init])
    {
        self.dataSourceType = dataSourceType;
        self.delegate = delegate;
        self.moreItemsAvailable = NO;
        self.searchResultsArray = [results mutableCopy];
        
        [self.delegate dataSourceUpdated];
    }
    
    return self;
}

- (void)retrieveNextItems:(AlfrescoListingContext *)moreListingContext
{
    __weak typeof(self) weakSelf = self;
    
    void (^completionBlock)(AlfrescoPagingResult *, NSError *) = ^void(AlfrescoPagingResult *pagingResult, NSError *error){
        if(pagingResult)
        {
            if (self.searchResultsArray == nil)
            {
                self.searchResultsArray = [NSMutableArray array];
            }
            [self.searchResultsArray addObjectsFromArray:pagingResult.objects];
            
            self.moreItemsAvailable = pagingResult.hasMoreItems;
            [weakSelf.delegate dataSourceUpdated];
        }
        else
        {
            [weakSelf displayError:error];
        }
    };

    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            [self.searchService searchWithKeywords:self.searchString options:[SearchResultsTableViewDataSource searchOptionsForSearchType:self.dataSourceType] listingContext:moreListingContext completionBlock:completionBlock];
        }
            break;
            
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            [self.personService searchWithKeywords:self.searchString listingContext:moreListingContext completionBlock:completionBlock];
        }
            break;
            
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            [self.siteService searchWithKeywords:self.searchString listingContext:moreListingContext completionBlock:completionBlock];
        }
            break;
            
        default:
            break;
    }
}

- (void)searchKeyword:(NSString *)keyword session:(id<AlfrescoSession>)session listingContext:(AlfrescoListingContext *)listingContext
{
    self.searchString = keyword;
    self.session = session;
    
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    else
    {
        self.defaultListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:0];
    }
    [self reloadDataSource];
}

- (void)clearDataSource
{
    [self.searchResultsArray removeAllObjects];
    [self.delegate dataSourceUpdated];
}

+ (AlfrescoKeywordSearchOptions *)searchOptionsForSearchType:(SearchViewControllerDataSourceType)searchType
{
    BOOL shouldSearchContent = [[PreferenceManager sharedManager] shouldCarryOutFullSearch];
    AlfrescoKeywordSearchOptions *searchOptions = [[AlfrescoKeywordSearchOptions alloc] initWithExactMatch:NO includeContent:shouldSearchContent];
    
    switch (searchType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            searchOptions.typeName = kAlfrescoModelTypeContent;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            searchOptions.typeName = kAlfrescoModelTypeFolder;
            break;
        }
        default:
        {
            searchOptions = nil;
            break;
        }
    }
    
    return searchOptions;
}

#pragma mark - Private Methods

- (void)reloadDataSource
{
    [self.searchResultsArray removeAllObjects];
    
    [self retrieveNextItems:self.defaultListingContext];
}

- (void)displayError:(NSError *)error
{
    NSString *errorMessageFormat = nil;
    
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            errorMessageFormat = NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed");
        }
            break;
            
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            errorMessageFormat = NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed");
        }
            break;
            
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            errorMessageFormat = NSLocalizedString(@"people.picker.search.no.results", @"No Search Results");
        }
            break;
            
        default:
            break;
    }
    
    if (errorMessageFormat)
    {
        displayErrorMessage([NSString stringWithFormat:errorMessageFormat, [ErrorDescriptions descriptionForError:error]]);
        [Notifier notifyWithAlfrescoError:error];
    }
}

@end

/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

#import "SearchManager.h"
#import "PreferenceManager.h"

@interface SearchManager()

@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, strong) id<AlfrescoSession> session;

@end

@implementation SearchManager

- (instancetype)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if(self)
    {
        self.session = session;
        self.siteService = [[AlfrescoSiteService alloc] initWithSession:self.session];
        self.personService = [[AlfrescoPersonService alloc] initWithSession:self.session];
        self.searchService = [[AlfrescoSearchService alloc] initWithSession:self.session];
    }
    
    return self;
}

- (void)searchUserForString:(NSString *)username showOnController:(SearchResultsTableViewController *)controller
{
    [controller showHUD];
    [self.personService searchWithKeywords:username completionBlock:^(NSArray *array, NSError *error) {
        [controller hideHUD];
        if (error)
        {
            // display error
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"people.picker.search.no.results", @"No Search Results"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
        else
        {
            controller.results = [array mutableCopy];
        }
    }];
}

- (void)searchSiteForString:(NSString *)searchString showOnController:(SitesTableListViewController *)controller
{
    [controller showHUD];
    [self.siteService searchWithKeywords:searchString completionBlock:^(NSArray *array, NSError *error) {
        [controller hideHUD];
        if (error)
        {
            // display error
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
        else
        {
            [controller reloadTableViewWithSearchResults:[array mutableCopy]];
        }
    }];
}

- (void)searchNodeForString:(NSString *)nodeName dataSourceType:(SearchViewControllerDataSourceType)dataSourceType showOnController:(SearchResultsTableViewController *)controller
{
    [controller showHUD];
    
    [self.searchService searchWithKeywords:nodeName options:[self searchOptionsForSearchType:dataSourceType] completionBlock:^(NSArray *array, NSError *error) {
        [controller hideHUD];
        
        if (array)
        {
            controller.results = [array mutableCopy];
        }
        else
        {
            // display error
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

- (AlfrescoKeywordSearchOptions *)searchOptionsForSearchType:(SearchViewControllerDataSourceType)searchType
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

@end

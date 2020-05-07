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

#import "SearchViewControllerDataSource.h"
#import "UserAccount.h"

@interface SearchViewControllerDataSource ()

@property (nonatomic, strong) UserAccount *account;

@end

@implementation SearchViewControllerDataSource

- (instancetype)initWithDataSourceType:(SearchViewControllerDataSourceType)dataSourceType account:(UserAccount *)account
{
    self = [super init];
    if (self)
    {
        self.account = account;
        switch (dataSourceType)
        {
            case SearchViewControllerDataSourceTypeLandingPage:
            {
                self.dataSourceArrays = [NSMutableArray new];
                self.sectionHeaderStringsArray = [NSMutableArray new];
                self.numberOfSections = 1;
                self.showsSearchBar = NO;
                
                NSMutableArray *sectionDataSource = nil;
                
                if(account.accountType == UserAccountTypeOnPremise || account.accountType == UserAccountTypeAIMS)
                {
                    sectionDataSource = [[NSMutableArray alloc] initWithObjects:
                                         [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.files", @"Files"), kCellTextKey, @"mainmenu-document", kCellImageKey, nil],
                                         [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.folders", @"Folders"), kCellTextKey, @"mainmenu-folder", kCellImageKey, nil],
                                         [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.sites", @"Sites"), kCellTextKey, @"mainmenu-sites", kCellImageKey, nil],
                                         [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.people", @"People"), kCellTextKey, @"mainmenu-user", kCellImageKey, nil],
                                         nil];
                }
                else
                {
                    sectionDataSource = [[NSMutableArray alloc] initWithObjects:
                                         [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.files", @"Files"), kCellTextKey, @"mainmenu-document", kCellImageKey, nil],
                                         [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.folders", @"Folders"), kCellTextKey, @"mainmenu-folder", kCellImageKey, nil],
                                         [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.people", @"People"), kCellTextKey, @"mainmenu-user", kCellImageKey, nil],
                                         nil];
                }
                
                [self.dataSourceArrays addObject:sectionDataSource];
                
                [self.sectionHeaderStringsArray addObject:NSLocalizedString(@"search.searchfor", @"Search for")];

                break;
            }
            case SearchViewControllerDataSourceTypeSearchFiles:
            case SearchViewControllerDataSourceTypeSearchFolders:
            case SearchViewControllerDataSourceTypeSearchSites:
            case SearchViewControllerDataSourceTypeSearchUsers:
            {
                [self setupDataSourceForSearchType:dataSourceType];
                break;
            }
        }
    }
    
    return self;
}

#pragma mark - Private methods

- (void)setupDataSourceForSearchType:(SearchViewControllerDataSourceType)searchType
{
    self.dataSourceArrays = [NSMutableArray new];
    self.sectionHeaderStringsArray = [NSMutableArray new];
    
    [self.sectionHeaderStringsArray addObject:NSLocalizedString(@"search.search", @"Search")];
    [self.dataSourceArrays addObject:[NSMutableArray new]];
    
    NSArray *previousSearchesArray = [self retriveSearchStringsArrayForSearchType:searchType];
    if (previousSearchesArray.count > 0)
    {
        [self.sectionHeaderStringsArray addObject:NSLocalizedString(@"search.previoussearches", @"Previous searches")];
        [self.dataSourceArrays addObject:previousSearchesArray];
    }
    self.numberOfSections = (previousSearchesArray.count > 0) ? 2 : 1;
    
    self.showsSearchBar = YES;
}

- (NSString *)userDefaultsKeyForSearchType:(SearchViewControllerDataSourceType)searchType
{
    NSString *key;
    
    switch (searchType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            key = kSearchTypeFiles;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            key = kSearchTypeFolders;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            key = kSearchTypeSites;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            key = kSearchTypeUsers;
            break;
        }
        default:
        {
            key = @"";
            break;
        }
    }
    
    return key;
}

#pragma mark - Public methods

- (void)saveSearchString:(NSString *)stringToSave forSearchType:(SearchViewControllerDataSourceType)searchType
{
    NSMutableArray *savedStringsForCurrentDataSourceType = [[self retriveSearchStringsArrayForSearchType:searchType] mutableCopy];
    if((!savedStringsForCurrentDataSourceType) || (savedStringsForCurrentDataSourceType.count == 0))
    {
        savedStringsForCurrentDataSourceType = [NSMutableArray new];
    }
    
    if([savedStringsForCurrentDataSourceType indexOfObject:stringToSave] == NSNotFound)
    {
        //Always insert a new string at the begining of the array in order to have the newest strings at the top
        [savedStringsForCurrentDataSourceType insertObject:stringToSave atIndex:0];
    }
    
    if(savedStringsForCurrentDataSourceType.count > 10)
    {
        [savedStringsForCurrentDataSourceType removeLastObject];
    }
    
    NSString *userSearchSpecificIdentifier = nil;
    if(self.account.accountType == UserAccountTypeOnPremise)
    {
        userSearchSpecificIdentifier = self.account.accountIdentifier;
    }
    else
    {
        userSearchSpecificIdentifier = self.account.selectedNetworkId;
    }
    
    NSMutableDictionary *previousSearchesDict = [[[NSUserDefaults standardUserDefaults] objectForKey:userSearchSpecificIdentifier] mutableCopy];
    if(!previousSearchesDict)
    {
        previousSearchesDict = [NSMutableDictionary new];
    }
    [previousSearchesDict setObject:savedStringsForCurrentDataSourceType forKey:[self userDefaultsKeyForSearchType:searchType]];
    
    [[NSUserDefaults standardUserDefaults] setObject:previousSearchesDict forKey:userSearchSpecificIdentifier];

    [self setupDataSourceForSearchType:searchType];
}

- (NSArray *)retriveSearchStringsArrayForSearchType:(SearchViewControllerDataSourceType)searchType
{
    NSString *userSearchSpecificIdentifier = nil;
    NSArray *previousSearchStringsArray = [NSArray new];
    if(self.account.accountType == UserAccountTypeOnPremise)
    {
        userSearchSpecificIdentifier = self.account.accountIdentifier;
    }
    else
    {
        userSearchSpecificIdentifier = self.account.selectedNetworkId;
    }
    
    if (userSearchSpecificIdentifier)
    {
        NSDictionary *previousSearchesDict = [[NSUserDefaults standardUserDefaults] objectForKey:userSearchSpecificIdentifier];
        if(previousSearchesDict)
        {
            NSArray *searchStringsArray = [previousSearchesDict objectForKey:[self userDefaultsKeyForSearchType:searchType]];
            if(searchStringsArray)
            {
                previousSearchStringsArray = searchStringsArray;
            }
        }
    }
    
    return previousSearchStringsArray;
}

@end

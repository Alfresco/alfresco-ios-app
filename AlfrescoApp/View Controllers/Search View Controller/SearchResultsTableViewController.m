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

#import "SearchResultsTableViewController.h"
#import "AlfrescoNodeCell.h"
#import "ThumbnailManager.h"
#import "UniversalDevice.h"
#import "SyncManager.h"
#import "SearchViewController.h"

@interface SearchResultsTableViewController ()

@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;

@end

@implementation SearchResultsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    switch (self.dataType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            UINib *nib = [UINib nibWithNibName:NSStringFromClass([AlfrescoNodeCell class]) bundle:nil];
            [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            UINib *nib = [UINib nibWithNibName:NSStringFromClass([AlfrescoNodeCell class]) bundle:nil];
            [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            break;
        }
        default:
        {
            break;
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.results.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    switch (self.dataType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            AlfrescoNodeCell *properCell = (AlfrescoNodeCell *)[tableView dequeueReusableCellWithIdentifier:[AlfrescoNodeCell cellIdentifier] forIndexPath:indexPath];
            
            AlfrescoNode *currentNode = [self.results objectAtIndex:indexPath.row];
            [properCell updateCellInfoWithNode:currentNode nodeStatus:nil];
            [properCell updateStatusIconsIsSyncNode:NO isFavoriteNode:NO animate:NO];
            
            AlfrescoDocument *documentNode = (AlfrescoDocument *)currentNode;
            UIImage *thumbnail = [[ThumbnailManager sharedManager] thumbnailForDocument:documentNode renditionType:kRenditionImageDocLib];
            if (thumbnail)
            {
                [properCell.image setImage:thumbnail withFade:NO];
            }
            else
            {
                [properCell.image setImage:smallImageForType([documentNode.name pathExtension]) withFade:NO];
                [[ThumbnailManager sharedManager] retrieveImageForDocument:documentNode renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                    @try
                    {
                        if (image)
                        {
                            // MOBILE-2991, check the tableView and indexPath objects are still valid as there is a chance
                            // by the time completion block is called the table view could have been unloaded.
                            if (tableView && indexPath)
                            {
                                AlfrescoNodeCell *updateCell = (AlfrescoNodeCell *)[tableView cellForRowAtIndexPath:indexPath];
                                [updateCell.image setImage:image withFade:YES];
                            }
                        }
                    }
                    @catch (NSException *exception)
                    {
                        AlfrescoLogError(@"Exception thrown is %@", exception);
                    }
                }];
            }

            cell = properCell;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            AlfrescoNodeCell *properCell = (AlfrescoNodeCell *)[tableView dequeueReusableCellWithIdentifier:[AlfrescoNodeCell cellIdentifier] forIndexPath:indexPath];
            
            AlfrescoNode *currentNode = [self.results objectAtIndex:indexPath.row];
            [properCell updateCellInfoWithNode:currentNode nodeStatus:nil];
            [properCell updateStatusIconsIsSyncNode:NO isFavoriteNode:NO animate:NO];
            
            [properCell.image setImage:smallImageForType(@"folder") withFade:NO];
            
            cell = properCell;
            break;
        }
        default:
        {
            break;
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *currentNode = [self.results objectAtIndex:indexPath.row];
    
    switch (self.dataType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            [self.documentService retrievePermissionsOfNode:currentNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                if (error)
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
                else
                {
                    NSString *contentPath = [[SyncManager sharedManager] contentPathForNode:(AlfrescoDocument *)currentNode];
                    if (![[AlfrescoFileManager sharedManager] fileExistsAtPath:contentPath isDirectory:NO])
                    {
                        contentPath = nil;
                    }
                    
                    if([self.presentingViewController isKindOfClass:[SearchViewController class]])
                    {
                        SearchViewController *vc = (SearchViewController *)self.presentingViewController;
                        [vc pushDocument:currentNode contentPath:contentPath permissions:permissions];
                    }
                }
            }];
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            [self.documentService retrievePermissionsOfNode:currentNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                if (permissions)
                {
                    if([self.presentingViewController isKindOfClass:[SearchViewController class]])
                    {
                        SearchViewController *vc = (SearchViewController *)self.presentingViewController;
                        [vc pushFolder:(AlfrescoFolder *)currentNode folderPermissions:permissions];
                    }
                }
                else
                {
                    // display permission retrieval error
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", @"Permission failed to be retrieved"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
            }];
        }
        default:
        {
            break;
        }
    }
}



#pragma mark - Custom setters/getters
- (void)setResults:(NSMutableArray *)results
{
    _results = results;
    [self.tableView reloadData];
}

@end

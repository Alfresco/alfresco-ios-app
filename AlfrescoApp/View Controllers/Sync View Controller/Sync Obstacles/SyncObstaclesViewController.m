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
 
#import "SyncObstaclesViewController.h"
#import "ThumbnailManager.h"
#import "AlfrescoNodeCell.h"
#import "SyncConstants.h"
#import "RealmSyncManager.h"

static NSInteger const kSectionDataIndex = 0;
static NSInteger const kSectionHeaderIndex = 1;

static CGFloat const kHeaderFontSize = 15.0f;

static NSString * const kUnfavoritedOnServerSectionHeaderKey = @"sync-errors.unfavorited-on-server-with-local-changes.header";
static NSString * const kDeletedOnServerSectionHeaderKey = @"sync-errors.deleted-on-server-with-local-changes.header";

@interface SyncObstaclesViewController ()
@property (nonatomic, strong) NSMutableDictionary *errorDictionary;
@property (nonatomic, strong) NSMutableArray *sectionData;
@end

@implementation SyncObstaclesViewController

- (id)initWithErrors:(NSMutableDictionary *)errors
{
    self = [super init];
    if (self)
    {
        self.errorDictionary = errors;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(dismissModalView)];
    [self.navigationItem setRightBarButtonItem:dismissButton];
    
    [self.navigationItem setTitle:NSLocalizedString(@"sync-errors.title", @"Sync Error Navigation Bar Title")];
    
    NSMutableArray *syncDocumentsRemovedOnServer = self.errorDictionary[kDocumentsRemovedFromSyncOnServerWithLocalChanges];
    NSMutableArray *syncDocumentDeletedOnServer = self.errorDictionary[kDocumentsDeletedOnServerWithLocalChanges];
    
    self.sectionData = [NSMutableArray array];
    if (syncDocumentsRemovedOnServer.count > 0)
    {
        [self.sectionData addObject:@[syncDocumentsRemovedOnServer, kUnfavoritedOnServerSectionHeaderKey]];
    }
    if (syncDocumentDeletedOnServer.count > 0)
    {
        [self.sectionData addObject:@[syncDocumentDeletedOnServer, kDeletedOnServerSectionHeaderKey]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self handleSyncObstacles];
}

#pragma mark - Private Class functions

- (void)dismissModalView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)calculateHeaderHeightForSection:(NSInteger)section
{
    NSUInteger returnHeight = 0;
    
    if ([self.sectionData[section][kSectionDataIndex] count] != 0)
    {
        NSString *headerText = NSLocalizedString(self.sectionData[section][kSectionHeaderIndex], @"TableView Header Section Descriptions");
        CGRect rect = [headerText boundingRectWithSize:CGSizeMake(300, 2000)
                                               options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                            attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:kHeaderFontSize]}
                                               context:nil];
        returnHeight = rect.size.height;
    }
    
    return returnHeight;
}

- (void)handleSyncObstacles
{
    NSArray *syncObstacles = [[self.errorDictionary objectForKey:kDocumentsDeletedOnServerWithLocalChanges] mutableCopy];
    for (AlfrescoDocument *document in syncObstacles)
    {
        [[RealmSyncManager sharedManager] saveDeletedFileBeforeRemovingFromSync:document];
    }
}

- (void)reloadTableView
{
    NSInteger numberOfPopulatedErrorArrays = [self numberOfPopulatedErrorArrays];
    
    if (numberOfPopulatedErrorArrays == 0)
    {
        [self dismissModalView];
    }
    
    [self.tableView reloadData];
}

- (NSInteger)numberOfPopulatedErrorArrays
{
    int numberOfPopulatedErrorArrays = 0;
    
    for (NSMutableArray *data in self.sectionData)
    {
        if ([data[kSectionDataIndex] count] > 0)
        {
            numberOfPopulatedErrorArrays++;
        }
    }
    return numberOfPopulatedErrorArrays;
}

#pragma mark - UITableViewDataSourceDelegate functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self numberOfPopulatedErrorArrays];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sectionData[section][kSectionDataIndex] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *syncErrorCellIdentifier = @"SyncObstacleCellIdentifier";
    
    AlfrescoDocument *document = self.sectionData[indexPath.section][kSectionDataIndex][indexPath.row];
    UIImage *thumbnail = [[ThumbnailManager sharedManager] thumbnailForDocument:document renditionType:kRenditionImageDocLib];
    thumbnail = thumbnail ? thumbnail : smallImageForType([document.name pathExtension]);
    
    UITableViewCell *cell = nil;
    
    if ([self.sectionData[indexPath.section][kSectionHeaderIndex] isEqualToString:kDeletedOnServerSectionHeaderKey])
    {
        AlfrescoNodeCell *standardCell = (AlfrescoNodeCell *)[tableView dequeueReusableCellWithIdentifier:[AlfrescoNodeCell cellIdentifier]];
        if (!standardCell)
        {
            NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"AlfrescoNodeCell" owner:self options:nil];
            standardCell = (AlfrescoNodeCell *)[nibItems objectAtIndex:0];
        }
        
        standardCell.filename.text = document.name;
        standardCell.details.text = @"";
        [standardCell.image setImage:thumbnail withFade:NO];
        
        cell = standardCell;
    }
    else
    {
        SyncObstacleTableViewCell *syncErrorCell = (SyncObstacleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:syncErrorCellIdentifier];
        if (!syncErrorCell)
        {
            NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"SyncObstacleTableViewCell" owner:self options:nil];
            syncErrorCell = (SyncObstacleTableViewCell *)[nibItems objectAtIndex:0];
            syncErrorCell.delegate = self;
            
            [Utility createBorderedButton:syncErrorCell.syncButton label:NSLocalizedString(@"sync-errors.button.sync", @"Sync Button") color:[UIColor appTintColor]];
            [Utility createBorderedButton:syncErrorCell.saveButton label:NSLocalizedString(@"sync-errors.button.save", @"Save Button") color:[UIColor appTintColor]];
            NSAssert(nibItems, @"Failed to load object from NIB");
        }
        
        syncErrorCell.selectionStyle = UITableViewCellSelectionStyleNone;
        syncErrorCell.fileNameTextLabel.text = document.name;
        [syncErrorCell.thumbnail setImage:thumbnail withFade:NO];
        
        // if imageView image is not set, everything would move right for some reason, so setting the superview's imageView and hidding it resolves the problem
        syncErrorCell.imageView.image = thumbnail;
        syncErrorCell.imageView.hidden = YES;
        
        cell = syncErrorCell;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate Functions

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray *syncErrors = self.sectionData[section][kSectionDataIndex];
    if (syncErrors.count > 0)
    {
        int horizontalMargin = 10;
        CGFloat heightRequired = [self calculateHeaderHeightForSection:section];
        
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, heightRequired)];
        headerView.backgroundColor = [UIColor clearColor];
        headerView.contentMode = UIViewContentModeScaleAspectFit;
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(horizontalMargin, 0, tableView.frame.size.width - (horizontalMargin * 2), heightRequired)];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.backgroundColor = [UIColor clearColor];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.textColor = [UIColor textDimmedColor];
        label.font = [UIFont systemFontOfSize:kHeaderFontSize];
        
        label.text = NSLocalizedString(self.sectionData[section][kSectionHeaderIndex], @"TableView Header Section Descriptions");
        
        [headerView addSubview:label];
        return headerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self calculateHeaderHeightForSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0 && !IS_IPAD) ? 100.0f : 60.0f;
}

#pragma mark - SyncErrorTableViewDelegate Functions

- (NSIndexPath *)indexPathForButtonPressed:(UIButton *)button
{
    UIView *cell = button.superview;
    
    BOOL foundTableView = NO;
    while (!foundTableView)
    {
        if (![cell isKindOfClass:[UITableViewCell class]])
        {
            cell = (UITableViewCell *)cell.superview;
        }
        else
        {
            foundTableView = YES;
        }
    }
    
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:(SyncObstacleTableViewCell *)cell];
    return cellIndexPath;
}

@end

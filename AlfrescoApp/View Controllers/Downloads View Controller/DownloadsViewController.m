/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
 
#import "DownloadsViewController.h"
#import "DownloadsDocumentPreviewViewController.h"
#import "UniversalDevice.h"
#import "DownloadManager.h"
#import "MetaDataViewController.h"
#import "AlfrescoDocument+ALF.h"
#import "FileFolderCell.h"

static NSInteger const kCellHeight = 60;
static CGFloat const kPullToRefreshDelay = 0.2f;
static NSString * const kDownloadsInterface = @"DownloadsViewController";
static NSString * const kDownloadInProgressExtension = @"-download";

@interface DownloadsViewController ()

@property (nonatomic) BOOL noDocumentsSaved;
@property (nonatomic) float totalFilesSize;
@property (nonatomic, strong) id<DocumentFilter> documentFilter;
@property (nonatomic, weak) IBOutlet MultiSelectActionsToolbar *multiSelectToolbar;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *multiSelectToolbarHeightConstraint;

@end

@implementation DownloadsViewController

- (id)init
{
    self = [super initWithNibName:kDownloadsInterface andSession:nil];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentDownloadStarted:)
                                                     name:kDocumentPreviewManagerWillStartLocalDocumentDownloadNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentDownloadComplete:)
                                                     name:kDocumentPreviewManagerDocumentDownloadCompletedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentDownloadCancelled:)
                                                     name:kDocumentPreviewManagerDocumentDownloadCancelledNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadsFolderDeleted:)
                                                     name:kAlfrescoDeletedLocalDocumentsFolderNotification
                                                   object:nil];
    }
    return self;
}

- (id)initWithDocumentFilter:(id<DocumentFilter>)documentFilter
{
    self = [self init];
    if (self)
    {
        self.documentFilter = documentFilter;
    }
    return self;
}

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [self init];
    if (self)
    {
        self.session = session;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"downloads.title", @"Local Files");
    self.tableView.emptyMessage = NSLocalizedString(@"downloads.empty", @"No Local Files");
    [self refreshData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDownloaded:) name:kAlfrescoDocumentDownloadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteDocument:) name:kAlfrescoDeleteLocalDocumentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(renamedDocument:) name:kAlfrescoLocalDocumentRenamedNotification object:nil];

    if (self.isDownloadPickerEnabled && !IS_IPAD)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(performCancel:)];
    }
    
    self.multiSelectToolbar.multiSelectDelegate = self;
    [self.multiSelectToolbar createToolBarButtonForTitleKey:@"multiselect.button.delete" actionId:kMultiSelectDelete isDestructive:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self selectIndexPathForAlfrescoNodeInDetailView:nil];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setAllowsMultipleSelectionDuringEditing:editing];
    [self.tableView setEditing:editing animated:animated];
    [self updateBarButtonItems];
    [self.navigationItem setHidesBackButton:editing animated:YES];
    
    if (editing)
    {
        [self disablePullToRefresh];
        [self.multiSelectToolbar enterMultiSelectMode:self.multiSelectToolbarHeightConstraint];
    }
    else
    {
        [self enablePullToRefresh];
        [self.multiSelectToolbar leaveMultiSelectMode:self.multiSelectToolbarHeightConstraint];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"downloadedCell";
    FileFolderCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (nil == cell)
    {
        cell = (FileFolderCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([FileFolderCell class]) owner:self options:nil] lastObject];
    }
    
    NSString *title = @"";
    NSString *details = @"";
    UIImage *iconImage = nil;
    AlfrescoDocument *currentDocument = nil;
    
    if (self.tableViewData.count > 0)
    {
        NSString *fileURLString = self.tableViewData[indexPath.row];
        NSDictionary *fileAttributes = [[AlfrescoFileManager sharedManager] attributesOfItemAtPath:fileURLString error:nil];
        unsigned long fileSize = [[fileAttributes objectForKey:kAlfrescoFileSize] longValue];
        NSDate *modificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
        NSString *modDateString = relativeTimeFromDate(modificationDate);
        
        title = [fileURLString lastPathComponent];
        details = [NSString stringWithFormat:@"%@ • %@", modDateString, stringForLongFileSize(fileSize)];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        tableView.allowsSelection = YES;
        
        NSString *pathToCurrentDocument = [self.tableViewData objectAtIndex:indexPath.row];
        currentDocument = [[DownloadManager sharedManager] infoForDocument:pathToCurrentDocument];
        
        UIImage *thumbnail = [self thumbnailFromDiskForDocument:currentDocument];
        iconImage = thumbnail ?: smallImageForType([fileURLString pathExtension]);

        // Removed rendering of the accessory view as part of MOBILE-1709
//        if (!self.isDownloadPickerEnabled && currentDocument)
//        {
//            cell.accessoryView = [self makeDetailDisclosureButton];
//        }
//        else
//        {
//            cell.accessoryView = nil;
//        }
    }
    
    cell.nodeNameLabel.text = title;
    cell.nodeDetailLabel.text = details;
    cell.node = currentDocument;
    [cell.nodeImageView setImage:iconImage withFade:NO];
    [cell registerForNotifications];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSString *fileToDeletePath = [self.tableViewData objectAtIndex:indexPath.row];
        
        [self deleteDocumentFromDownloads:fileToDeletePath];
        [self updateBarButtonItems];
    }
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isDownloadPickerEnabled)
    {
        [self didSelectDocumentAtIndexPath:indexPath];
    }
    else
    {
        NSString *contentFullPath = self.tableViewData[indexPath.row];
        if (self.tableView.isEditing)
        {
            [self.multiSelectToolbar userDidSelectItem:contentFullPath];
        }
        else
        {
            AlfrescoDocument *documentToDisplay = [[DownloadManager sharedManager] infoForDocument:contentFullPath];
            if (documentToDisplay)
            {
                // Additional property added by category
                documentToDisplay.isDownloaded = YES;
                [UniversalDevice pushToDisplayDownloadDocumentPreviewControllerForAlfrescoDocument:documentToDisplay
                                                                                       permissions:nil
                                                                                       contentFile:contentFullPath
                                                                                  documentLocation:InAppDocumentLocationLocalFiles
                                                                                           session:self.session
                                                                              navigationController:self.navigationController
                                                                                          animated:YES];
            }
            else
            {
                [UniversalDevice pushToDisplayDownloadDocumentPreviewControllerForAlfrescoDocument:nil
                                                                                       permissions:nil
                                                                                       contentFile:contentFullPath
                                                                                  documentLocation:InAppDocumentLocationLocalFiles
                                                                                           session:self.session
                                                                              navigationController:self.navigationController
                                                                                          animated:YES];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing)
    {
        NSString *contentFullPath = self.tableViewData[indexPath.row];
        [self.multiSelectToolbar userDidDeselectItem:contentFullPath];
    }
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    if (indexPath != nil)
    {
        AlfrescoDocument *documentInfo = [[DownloadManager sharedManager] infoForDocument:self.tableViewData[indexPath.row]];
        MetaDataViewController *metaDataViewController = [[MetaDataViewController alloc] initWithAlfrescoNode:documentInfo session:self.session];

        [UniversalDevice pushToDisplayViewController:metaDataViewController usingNavigationController:self.navigationController animated:YES];
    }
}

#pragma mark - Utilities

- (void)deleteDocumentFromDownloads:(NSString *)fileToDeletePath
{
    AlfrescoDocument *documentToDelete = [[DownloadManager sharedManager] infoForDocument:fileToDeletePath];
    NSString *documentInDetailView = [UniversalDevice detailViewItemIdentifier];
    
    // Remove document from view if appropriate
    if ((documentToDelete && [documentInDetailView isEqualToString:documentToDelete.identifier]) ||
        ([documentInDetailView isEqualToString:fileToDeletePath]))
    {
        [UniversalDevice clearDetailViewController];
    }
    
    NSIndexPath *indexPathForNode = [self indexPathForNodeWithIdentifier:fileToDeletePath inNodeIdentifiers:self.tableViewData];
    [[DownloadManager sharedManager] removeFromDownloads:fileToDeletePath];
    [self.tableViewData removeObject:fileToDeletePath];
    
    // The indexPath should never return nil, as it's impossible to delete a download that isn't currently there.
    // However, due to MOBILE-2902, a check has been added to ensure that value is not nil before animating.
    // Otherwise, the entire tableview is refeshed.
    if (indexPathForNode)
    {
        [self.tableView deleteRowsAtIndexPaths:@[indexPathForNode] withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        [self.tableView reloadData];
    }
}

- (void)confirmDeletingMultipleNodes
{
    NSString *titleKey = (self.multiSelectToolbar.selectedItems.count == 1) ? @"multiselect.delete.confirmation.message.one-download" : @"multiselect.delete.confirmation.message.n-downloads";
    NSString *title = [NSString stringWithFormat:NSLocalizedString(titleKey, @"Are you sure you want to delete x items"), self.multiSelectToolbar.selectedItems.count];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"multiselect.button.delete", @"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteMultiSelectedNodes];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { }]];
    
    alertController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverPresenter = [alertController popoverPresentationController];
    popoverPresenter.sourceView = self.multiSelectToolbar;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteMultiSelectedNodes
{
    [self setEditing:NO animated:YES];
    
    for (NSString *filePath in self.multiSelectToolbar.selectedItems)
    {
        [self deleteDocumentFromDownloads:filePath];
    }
    [self refreshData];
}

- (UIButton *)makeDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)refreshData
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSArray *documentPaths = [[DownloadManager sharedManager] downloadedDocumentPaths];
    NSMutableArray *filteredDocumentPaths = [NSMutableArray array];
    self.totalFilesSize = 0;
    
    for (NSString *documentPath in documentPaths)
    {
        if (!self.documentFilter || ![self.documentFilter filterDocumentWithExtension:documentPath.pathExtension])
        {
            [filteredDocumentPaths addObject:documentPath];
            NSError *error = nil;
            NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:documentPath error:&error];
            self.totalFilesSize += [[fileAttributes objectForKey:kAlfrescoFileSize] longValue];
        }
    }
    
    self.noDocumentsSaved = filteredDocumentPaths.count == 0;
    self.tableViewData = filteredDocumentPaths;
    [self.tableView reloadData];
    [self updateBarButtonItems];
    [self selectIndexPathForAlfrescoNodeInDetailView:nil];
}

- (void)updateBarButtonItems
{
    if (!self.isDownloadPickerEnabled)
    {
        UIBarButtonItem *editBarButtonItem = nil;
        if (!self.tableView.editing)
        {
            editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                              target:self
                                                                              action:@selector(performEditBarButtonItemAction:)];
        }
        else
        {
            editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector(performEditBarButtonItemAction:)];
        }
        
        if (editBarButtonItem)
        {
            [self.navigationItem setRightBarButtonItem:editBarButtonItem animated:YES];
            editBarButtonItem.enabled = (self.tableViewData.count > 0);
        }
    }
}

- (void)performEditBarButtonItemAction:(UIBarButtonItem *)sender
{
    [self setEditing:!self.tableView.editing animated:YES];
}

- (void)selectIndexPathForAlfrescoNodeInDetailView:(NSString *)detailViewItemIdentifier
{
    NSMutableArray *documents = [[NSMutableArray alloc] init];
    
    for (NSString *documentPath in self.tableViewData)
    {
        NSString *identifier = [[[DownloadManager sharedManager] infoForDocument:documentPath] identifier];
        if (identifier != nil)
        {
            [documents addObject:identifier];
        }
        else
        {
            [documents addObject:documentPath];
        }
    }
    
    NSString *itemIdentifierInDetailView = detailViewItemIdentifier ? detailViewItemIdentifier : [UniversalDevice detailViewItemIdentifier];
    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:itemIdentifierInDetailView inNodeIdentifiers:documents];
    
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (UIImage *)thumbnailFromDiskForDocument:(AlfrescoDocument *)document
{
    UIImage *returnImage = nil;
    NSString *thumbnailsExtension = @".png";
    
    NSString *savedFileName = [uniqueFileNameForNode(document) stringByAppendingString:thumbnailsExtension];
    if (savedFileName)
    {
        NSString *filePathToFile = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:savedFileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePathToFile];
        NSData *imageData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:fileURL];
        returnImage = [UIImage imageWithData:imageData];
    }
    return returnImage;
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    [self refreshData];
    [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:kPullToRefreshDelay];
}

#pragma mark - DownloadManager Notifications

- (void)documentDownloaded:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSString *documentIdentifier = [userInfo objectForKey:kAlfrescoDocumentDownloadedIdentifierKey];
    
    [self refreshData];
    if (documentIdentifier)
    {
        [self selectIndexPathForAlfrescoNodeInDetailView:documentIdentifier];
    }
}

- (void)documentDownloadStarted:(NSNotification *)notification
{
    AlfrescoDocument *document = notification.object;
    DownloadManager *downloadManager = [DownloadManager sharedManager];
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    
    NSString *documentName = [NSString stringWithFormat:@"%@%@", document.name, kDownloadInProgressExtension];
    NSString *documentPath = [[fileManager temporaryDirectory] stringByAppendingPathComponent:documentName];
    NSError *error = nil;
    
    // creating temporary file for download in Temp folder and ask DownloadManager to save it in LocalFiles (Temporary file will be replaced by actual file after download completes)
    [fileManager createFileAtPath:documentPath contents:nil error:&error];
    [downloadManager saveDocument:document contentPath:documentPath suppressAlerts:YES completionBlock:^(NSString *filePath) {
        // remove temporary file after its saved to Local Files
        [fileManager removeItemAtPath:documentPath error:nil];
    }];
    
    [self refreshData];
}

- (void)documentDownloadComplete:(NSNotification *)notification
{
    AlfrescoDocument *document = notification.object;
    [self removeTemporaryDownloadFilesForDocument:document];
}

- (void)documentDownloadCancelled:(NSNotification *)notification
{
    AlfrescoDocument *document = notification.object;
    [self removeTemporaryDownloadFilesForDocument:document];
    [self refreshData];
}

- (void)removeTemporaryDownloadFilesForDocument:(AlfrescoDocument *)document
{
    DownloadManager *downloadManager = [DownloadManager sharedManager];
    NSString *documentName = [NSString stringWithFormat:@"%@%@", document.name, kDownloadInProgressExtension];
    
    if ([downloadManager isDownloadedDocument:documentName])
    {
        [downloadManager removeFromDownloads:documentName];
    }
}

#pragma mark - Download Picker handlers

- (void)performCancel:(id)sender
{
    if (self.downloadPickerDelegate && [self.downloadPickerDelegate respondsToSelector:@selector(downloadPickerDidCancel)])
    {
        [self.downloadPickerDelegate downloadPickerDidCancel];
    }
}

- (void)didSelectDocumentAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.downloadPickerDelegate && [self.downloadPickerDelegate respondsToSelector:@selector(downloadPicker:didPickDocument:)])
    {
        [self.downloadPickerDelegate downloadPicker:self didPickDocument:self.tableViewData[indexPath.row]];
    }
}

#pragma mark - MultiSelectDelegate Functions

- (void)multiSelectUserDidPerformAction:(NSString *)actionId selectedItems:(NSArray *)selectedItems
{
    if ([actionId isEqualToString:kMultiSelectDelete])
    {
        [self confirmDeletingMultipleNodes];
    }
}

#pragma mark - Notification Methods

- (void)deleteDocument:(NSNotification *)notification
{
    [self deleteDocumentFromDownloads:notification.object];
    [self refreshData];
}

- (void)renamedDocument:(NSNotification *)notification
{
    NSString *oldPath = notification.object;
    NSString *newPath = [notification.userInfo objectForKey:kAlfrescoLocalDocumentNewName];
    
    NSIndexPath *indexPathForNode = [self indexPathForNodeWithIdentifier:oldPath inNodeIdentifiers:self.tableViewData];
    [self.tableViewData replaceObjectAtIndex:indexPathForNode.row withObject:newPath];
    [self.tableView reloadRowsAtIndexPaths:@[indexPathForNode] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)downloadsFolderDeleted:(NSNotification *)notification
{
    [self.tableViewData removeAllObjects];
    [self.tableView reloadData];
}

@end

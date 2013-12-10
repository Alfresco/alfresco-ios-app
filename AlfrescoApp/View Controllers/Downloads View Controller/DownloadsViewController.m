//
//  DownloadsViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "DownloadsViewController.h"
#import "PreviewViewController.h"
#import "UniversalDevice.h"
#import "DownloadManager.h"
#import "Utility.h"
#import "MetaDataViewController.h"
#import "AlfrescoDocument+ALF.h"
#import "FileFolderCell.h"

static NSInteger const kCellHeight = 60;
static CGFloat const kFooterHeight = 32.0f;
static CGFloat const kPullToRefreshDelay = 0.2f;
static CGFloat const kCellImageViewWidth = 32.0f;
static CGFloat const kCellImageViewHeight = 32.0f;
static NSString * const kDownloadsInterface = @"DownloadsViewController";

@interface DownloadsViewController ()

@property (nonatomic, strong) NSString *downloadsFooterTitle;
@property (nonatomic) BOOL noDocumentsSaved;
@property (nonatomic) float totalFilesSize;
@property (nonatomic, strong) MultiSelectActionsToolbar *multiSelectToolbar;
@property (nonatomic, strong) id<DocumentFilter> documentFilter;

@end

@implementation DownloadsViewController

- (id)init
{
    self = [super initWithNibName:kDownloadsInterface andSession:nil];
    if (self)
    {
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"downloads.title", @"downloads title");
    self.downloadsFooterTitle = NSLocalizedString(@"downloadview.footer.no-documents", @"No Downloaded Documents");
    [self refreshData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentDownloaded:)
                                                 name:kAlfrescoDocumentDownloadedNotification
                                               object:nil];
    if (self.isDownloadPickerEnabled && !IS_IPAD)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(performCancel:)];
    }
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
    
    if (!self.multiSelectToolbar)
    {
        self.multiSelectToolbar = [[MultiSelectActionsToolbar alloc] initWithParentViewController:self.tabBarController];
        self.multiSelectToolbar.multiSelectDelegate = self;
        [self.multiSelectToolbar createToolBarButtonForTitleKey:@"multiselect.button.delete" actionId:kMultiSelectDelete isDestructive:YES];
    }
    
    editing ? [self.multiSelectToolbar enterMultiSelectMode] : [self.multiSelectToolbar leaveMultiSelectMode];
    [self.navigationItem setHidesBackButton:editing animated:YES];
    
    if (editing)
    {
        [self disablePullToRefresh];
    }
    else
    {
        [self enablePullToRefresh];
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
    
    if (self.tableViewData.count > 0)
    {
        NSString *fileURLString = self.tableViewData[indexPath.row];
        NSDictionary *fileAttributes = [[AlfrescoFileManager sharedManager] attributesOfItemAtPath:fileURLString error:nil];
        unsigned long fileSize = [[fileAttributes objectForKey:kAlfrescoFileSize] longValue];
        NSDate *modificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
        NSString *modDateString = relativeDateFromDate(modificationDate);
        
        title = [fileURLString lastPathComponent];
        details = [NSString stringWithFormat:@"%@ • %@", modDateString, stringForLongFileSize(fileSize)];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        tableView.allowsSelection = YES;
        
        NSString *pathToCurrentDocument = [self.tableViewData objectAtIndex:indexPath.row];
        AlfrescoDocument *currentDocument = [[DownloadManager sharedManager] infoForDocument:pathToCurrentDocument];
        
        UIImage *thumbnail = [self thumbnailFromDiskForDocument:currentDocument];
        iconImage = thumbnail ? thumbnail : imageForType([fileURLString pathExtension]);

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
    else
    {
        title = self.downloadsFooterTitle;
        cell.imageView.image = nil;
        details = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        tableView.allowsSelection = NO;
    }
    
    cell.nodeNameLabel.text = title;
    cell.nodeDetailLabel.text = details;
    cell.nodeImageView.image = iconImage;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footerText = @"";
    
    if (self.tableViewData.count > 0)
    {
        NSString *documentsText = @"";
        
        switch (self.tableViewData.count)
        {
            case 1:
            {
                documentsText = NSLocalizedString(@"downloadview.footer.one-document", @"1 Document");
                break;
            }
            default:
            {
                documentsText = [NSString stringWithFormat:NSLocalizedString(@"downloadview.footer.multiple-documents", @"%d Documents"), self.tableViewData.count];
                break;
            }
        }
        
        footerText = [NSString stringWithFormat:@"%@ %@", documentsText, stringForLongFileSize(self.totalFilesSize)];
    }
    else
    {
        footerText = self.downloadsFooterTitle;
    }
    
    return footerText;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSString *fileToDeletePath = [self.tableViewData objectAtIndex:indexPath.row];
        
        [self deleteDocumentFromDownloads:fileToDeletePath];
        [self refreshData];
    }
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kFooterHeight;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UILabel *footerBackground = [[UILabel alloc] init];
    
    footerBackground.text = [self tableView:tableView titleForFooterInSection:section];
    footerBackground.backgroundColor = [UIColor whiteColor];
    footerBackground.textAlignment = NSTextAlignmentCenter;
    
    return footerBackground;
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
            // Additional property added by category
            documentToDisplay.isDownloaded = YES;
            PreviewViewController *previewController = [[PreviewViewController alloc] initWithDocument:documentToDisplay documentPermissions:nil contentFilePath:contentFullPath session:self.session displayOverlayCloseButton:NO];
            
            [UniversalDevice pushToDisplayViewController:previewController usingNavigationController:self.navigationController animated:YES];
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
        MetaDataViewController *metaDataViewController = [[MetaDataViewController alloc] initWithAlfrescoNode:documentInfo showingVersionHistoryOption:YES session:self.session];

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
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPathForNode]  withRowAnimation:UITableViewRowAnimationFade];
}

- (void)confirmDeletingMultipleNodes
{
    NSString *titleKey = (self.multiSelectToolbar.selectedItems.count == 1) ? @"multiselect.delete.confirmation.message.one-download" : @"multiselect.delete.confirmation.message.n-downloads";
    NSString *title = [NSString stringWithFormat:NSLocalizedString(titleKey, @"Are you sure you want to delete x items"), self.multiSelectToolbar.selectedItems.count];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                               destructiveButtonTitle:NSLocalizedString(@"multiselect.button.delete", @"Delete")
                                                    otherButtonTitles:nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
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

#pragma mark - UIActionSheetDelegate Functions

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *selectedButtonText = [actionSheet buttonTitleAtIndex:buttonIndex];
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    
    if ([selectedButtonText isEqualToString:NSLocalizedString(@"multiselect.button.delete", @"MultiSelect Delete confirmation")])
    {
        [self deleteMultiSelectedNodes];
    }
}

@end

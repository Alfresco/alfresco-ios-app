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
 
#import "DownloadsDocumentPreviewViewController.h"
#import "FilePreviewViewController.h"
#import "MetaDataViewController.h"

@interface DownloadsDocumentPreviewViewController ()
@property (nonatomic, strong) NSMutableArray *displayedPagingControllers;
@property (nonatomic, assign) CGFloat segmentControlHeightConstraintValue;
@end

@implementation DownloadsDocumentPreviewViewController

- (instancetype)initWithAlfrescoDocument:(AlfrescoDocument *)document
                             permissions:(AlfrescoPermissions *)permissions
                         contentFilePath:(NSString *)contentFilePath
                        documentLocation:(InAppDocumentLocation)documentLocation
                                 session:(id<AlfrescoSession>)session
{
    self = [super initWithAlfrescoDocument:document permissions:permissions contentFilePath:contentFilePath documentLocation:documentLocation session:session];
    if (self)
    {
        self.pagingControllers = [NSMutableArray array];
        self.displayedPagingControllers = [NSMutableArray array];
        self.actionHandler = [[ActionViewHandler alloc] initWithAlfrescoNode:nil session:nil controller:self];
    }
    return self;
}

- (instancetype)initWithFilePath:(NSString *)filePath
{
    self = [self initWithAlfrescoDocument:nil permissions:nil contentFilePath:filePath documentLocation:InAppDocumentLocationLocalFiles session:nil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.segmentControlHeightConstraintValue = self.segmentControlHeightConstraint.constant;

    [self setupPagingScrollView];
    [self refreshViewController];
}

- (void)refreshViewController
{
    self.title = (self.documentLocation == InAppDocumentLocationLocalFiles) ? self.documentContentFilePath.lastPathComponent : self.document.name;
    
    if (!self.document)
    {
        self.segmentControlHeightConstraint.constant = 0;
        self.pagingSegmentControl.hidden = YES;
    }
    else
    {
        self.segmentControlHeightConstraint.constant = self.segmentControlHeightConstraintValue;
        self.pagingSegmentControl.hidden = NO;
    }
    
    [self refreshPagingScrollView];
    [self setupActionCollectionView];
    
    [self localiseUI];
}

- (void)localiseUI
{
    if (IS_IPAD)
    {
        [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.preview.title", @"Preview Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeFilePreview];
        [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.repository.metadata.title", @"Metadata Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeMetadata];
    }
}

- (void)setupPagingScrollView
{
    [self.pagingSegmentControl removeAllSegments];

    [self.pagingSegmentControl insertSegmentWithImage:[UIImage imageNamed:@"segment-icon-preview.png"] atIndex:PagingScrollViewSegmentTypeFilePreview animated:NO];
    [self.pagingSegmentControl insertSegmentWithImage:[UIImage imageNamed:@"segment-icon-properties.png"] atIndex:PagingScrollViewSegmentTypeMetadata animated:NO];
    
    FilePreviewViewController *filePreviewController = [[FilePreviewViewController alloc] initWithFilePath:self.documentContentFilePath document:self.document];
    [self.pagingControllers insertObject:filePreviewController atIndex:PagingScrollViewSegmentTypeFilePreview];
    MetaDataViewController *metadataViewController = [[MetaDataViewController alloc] initWithAlfrescoNode:self.document session:nil];
    [self.pagingControllers insertObject:metadataViewController atIndex:PagingScrollViewSegmentTypeMetadata];
}

 - (void)refreshPagingScrollView
{
    NSUInteger currentlySelectedTabIndex = self.pagingScrollView.selectedPageIndex;
    
    // Remove all existing views in the scroll view
    NSArray *shownControllers = [NSArray arrayWithArray:self.displayedPagingControllers];
    
    for (UIViewController *displayedController in shownControllers)
    {
        [displayedController willMoveToParentViewController:nil];
        [displayedController.view removeFromSuperview];
        [displayedController removeFromParentViewController];
        
        [self.displayedPagingControllers removeObject:displayedController];
    }
    
    // Add them back and refresh the segment control.
    // If the document object is nil, we must not disiplay the MetaDataViewController
    for (UIViewController *pagingController in self.pagingControllers)
    {
        if (self.document == nil && [pagingController isKindOfClass:[MetaDataViewController class]])
        {
            break;
        }
        [self addChildViewController:pagingController];
        [self.pagingScrollView addSubview:pagingController.view];
        [pagingController didMoveToParentViewController:self];
        
        [self.displayedPagingControllers addObject:pagingController];
    }
    
    self.pagingSegmentControl.selectedSegmentIndex = currentlySelectedTabIndex;
    [self.pagingScrollView scrollToDisplayViewAtIndex:currentlySelectedTabIndex animated:NO];
}

- (void)setupActionCollectionView
{
    BOOL isRestricted = NO;
    
    NSMutableArray *items = [NSMutableArray array];

    if (self.documentLocation == InAppDocumentLocationLocalFiles)
    {
        [items addObject:[ActionCollectionItem renameItem]];
    }
    
    if (!isRestricted)
    {
        if ([MFMailComposeViewController canSendMail])
        {
            [items addObject:[ActionCollectionItem emailItem]];
        }
        
        if (![Utility isAudioOrVideo:self.documentContentFilePath])
        {
            [items addObject:[ActionCollectionItem printItem]];
        }
        
        [items addObject:[ActionCollectionItem openInItem]];
    }
    
    if (self.documentLocation == InAppDocumentLocationLocalFiles)
    {
        [items addObject:[ActionCollectionItem deleteItem]];
    }
    
    self.actionMenuView.items = items;
}

#pragma mark - ActionCollectionViewDelegate Functions

- (void)didPressActionItem:(ActionCollectionItem *)actionItem cell:(UICollectionViewCell *)cell inView:(UICollectionView *)view
{
    if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierEmail])
    {
        [self.actionHandler pressedEmailActionItem:actionItem documentPath:self.documentContentFilePath documentLocation:self.documentLocation];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierPrint])
    {
        [self.actionHandler pressedPrintActionItem:actionItem documentPath:self.documentContentFilePath documentLocation:self.documentLocation presentFromView:cell inView:view];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierOpenIn])
    {
        [self.actionHandler pressedOpenInActionItem:actionItem documentPath:self.documentContentFilePath documentLocation:self.documentLocation presentFromView:cell inView:view];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierDelete])
    {
        [self.actionHandler pressedDeleteLocalFileActionItem:actionItem documentPath:self.documentContentFilePath];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierRename])
    {
        [self.actionHandler pressedRenameActionItem:actionItem atPath:self.documentContentFilePath];
    }
}

#pragma mark - NodeUpdatableProtocal Functions

- (void)updateToAlfrescoDocument:(AlfrescoDocument *)node
                     permissions:(AlfrescoPermissions *)permissions
                 contentFilePath:(NSString *)contentFilePath
                documentLocation:(InAppDocumentLocation)documentLocation
                         session:(id<AlfrescoSession>)session
{
    [super updateToAlfrescoDocument:node permissions:permissions contentFilePath:contentFilePath documentLocation:documentLocation session:session];
    
    [self refreshViewController];
    
    for (UIViewController *pagingController in self.displayedPagingControllers)
    {
        if ([pagingController conformsToProtocol:@protocol(NodeUpdatableProtocol)])
        {
            UIViewController<NodeUpdatableProtocol> *conformingController = (UIViewController<NodeUpdatableProtocol> *)pagingController;
            if ([conformingController respondsToSelector:@selector(updateToAlfrescoDocument:permissions:contentFilePath:documentLocation:session:)])
            {
                [conformingController updateToAlfrescoDocument:node permissions:permissions contentFilePath:contentFilePath documentLocation:documentLocation session:session];
            }
            else if ([conformingController respondsToSelector:@selector(updateToAlfrescoNode:permissions:session:)])
            {
                [conformingController updateToAlfrescoNode:node permissions:permissions session:session];
            }
        }
    }
}

@end

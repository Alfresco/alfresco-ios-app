//
//  DownloadsDocumentPreviewViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 14/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "DownloadsDocumentPreviewViewController.h"
#import "FilePreviewViewController.h"
#import "MetaDataViewController.h"

@interface DownloadsDocumentPreviewViewController ()

@end

@implementation DownloadsDocumentPreviewViewController

- (instancetype)initWithFilePath:(NSString *)filePath
{
    self = [self initWithNibName:@"BaseDocumentPreviewViewController" bundle:nil];
    if (self)
    {
        self.documentContentFilePath = filePath;
        self.documentLocation = InAppDocumentLocationLocalFiles;
        self.pagingControllers = [NSMutableArray array];
        self.actionHandler = [[ActionViewHandler alloc] initWithAlfrescoNode:nil session:nil controller:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.documentContentFilePath.lastPathComponent;
    
    [self.pagingSegmentControl removeAllSegments];
    [self.pagingSegmentControl insertSegmentWithTitle:NSLocalizedString(@"document.segment.preview.title", @"Preview Segment Title") atIndex:PagingScrollViewSegmentTypeFilePreview animated:NO];
    [self.pagingSegmentControl insertSegmentWithTitle:NSLocalizedString(@"document.segment.metadata.title", @"Metadata Segment Title") atIndex:PagingScrollViewSegmentTypeMetadata animated:NO];
    
    if (!self.document)
    {
        self.segmentControlHeightConstraint.constant = 0;
        self.pagingSegmentControl.hidden = YES;
    }
    
    self.pagingSegmentControl.selectedSegmentIndex = PagingScrollViewSegmentTypeFilePreview;
    
    [self setupPagingScrollView];
    [self setupActionCollectionView];
    
    [self localiseUI];
}

- (void)localiseUI
{
    [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.preview.title", @"Preview Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeFilePreview];
    [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.metadata.title", @"Metadata Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeMetadata];
}

- (void)setupPagingScrollView
{
    FilePreviewViewController *filePreviewController = [[FilePreviewViewController alloc] initWithFilePath:self.documentContentFilePath document:nil loadingCompletionBlock:nil];
  
    for (int i = 0; i < PagingScrollViewSegmentType_MAX; i++)
    {
        [self.pagingControllers addObject:[NSNull null]];
    }

    [self.pagingControllers insertObject:filePreviewController atIndex:PagingScrollViewSegmentTypeFilePreview];
    
    if (self.document)
    {
        MetaDataViewController *metadataViewController = [[MetaDataViewController alloc] initWithAlfrescoNode:self.document session:nil];
        [self.pagingControllers insertObject:metadataViewController atIndex:PagingScrollViewSegmentTypeMetadata];
    }
  
    for (int i = 0; i < self.pagingControllers.count; i++)
    {
        if (![self.pagingControllers[i] isKindOfClass:[NSNull class]])
        {
            UIViewController *currentController = self.pagingControllers[i];
            [self addChildViewController:currentController];
            [self.pagingScrollView addSubview:currentController.view];
            [currentController didMoveToParentViewController:self];
        }
    }
}

- (void)setupActionCollectionView
{
    BOOL isRestricted = NO;
    
    NSMutableArray *items = [NSMutableArray array];

    [items addObject:[ActionCollectionItem renameItem]];
    
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
    
    [items addObject:[ActionCollectionItem deleteItem]];
    
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
        [self.actionHandler pressedDeleteActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierRename])
    {
        [self.actionHandler pressedRenameActionItem:actionItem atPath:self.documentContentFilePath];
    }
}

@end

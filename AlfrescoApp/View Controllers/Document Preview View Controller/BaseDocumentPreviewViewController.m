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
 
#import "BaseDocumentPreviewViewController.h"
#import "DocumentPreviewViewController.h"
#import "DownloadsDocumentPreviewViewController.h"

@implementation BaseDocumentPreviewViewController

- (instancetype)initWithAlfrescoDocument:(AlfrescoDocument *)document
                             permissions:(AlfrescoPermissions *)permissions
                         contentFilePath:(NSString *)contentFilePath
                        documentLocation:(InAppDocumentLocation)documentLocation
                                 session:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:@"BaseDocumentPreviewViewController" bundle:nil];
    if (self)
    {
        self.document = document;
        self.documentPermissions = permissions;
        self.session = session;
        self.documentContentFilePath = contentFilePath;
        self.documentLocation = documentLocation;
        self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
        self.ratingService = [[AlfrescoRatingService alloc] initWithSession:session];
        self.pagingControllers = [NSMutableArray array];
        self.actionHandler = [[ActionViewHandler alloc] initWithAlfrescoNode:document session:session controller:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localDocumentWasRenamed:) name:kAlfrescoLocalDocumentRenamedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setAccessibilityIdentifiers];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.progressHUD)
        {
            self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:self.progressHUD];
        }
        [self.progressHUD showAnimated:YES];
    });
}

- (void)hideHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideAnimated:YES];
    });
}

- (void)localiseUI
{
    if (IS_IPAD)
    {
        [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.preview.title", @"Preview Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeFilePreview];
        [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.metadata.title", @"Metadata Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeMetadata];
        [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.version.history.title", @"Version Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeVersionHistory];
        [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.nocomments.title", @"Comments Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeComments];
        [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.map.title", @"Map Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeMap];
    }
}

#pragma mark - IBActions

- (IBAction)segmentValueChanged:(id)sender
{
    PagingScrollViewSegmentType selectedSegment = self.pagingSegmentControl.selectedSegmentIndex;
    [self.pagingScrollView scrollToDisplayViewAtIndex:selectedSegment animated:YES];
    
    if((selectedSegment != PagingScrollViewSegmentTypeComments) && ([self isKindOfClass:[DocumentPreviewViewController class]]))
    {
        [self shouldFocusComments:NO];
    }
}

#pragma mark - Private methods
- (void) shouldFocusComments:(BOOL)shouldFocusComments
{
    AlfrescoLogError(@"You need to implement %@", _cmd);
}

- (void)setAccessibilityIdentifiers
{
    self.view.accessibilityIdentifier = kBaseDocumentPreviewVCViewIdentifier;
    self.pagingSegmentControl.accessibilityIdentifier = kBaseDocumentPreviewVCSegmentedControlIdentifier;
}

#pragma mark - ActionCollectionViewDelegate Functions

- (void)didPressActionItem:(ActionCollectionItem *)actionItem cell:(UICollectionViewCell *)cell inView:(UICollectionView *)view
{
    AlfrescoLogError(@"You need to implement %@", _cmd);
}

#pragma mark - PagedScrollViewDelegate Functions

- (void)pagedScrollViewDidScrollToFocusViewAtIndex:(NSInteger)viewIndex whilstDragging:(BOOL)dragging
{
    // only want to update the segment control on each call if we are swiping and not using the segemnt control
    if (dragging)
    {
        [self.pagingSegmentControl setSelectedSegmentIndex:viewIndex];
    }
}

#pragma mark - DocumentInDetailView Protocol functions

- (NSString *)detailViewItemIdentifier
{
    return (self.document) ? self.document.identifier : nil;
}

#pragma mark - NodeUpdatableProtocol Functions

- (void)updateToAlfrescoNode:(AlfrescoNode *)node permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session
{
    self.document = (AlfrescoDocument *)node;
    self.documentPermissions = permissions;
    self.session = session;
    self.documentContentFilePath = nil;
    self.documentLocation = 0;
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    self.ratingService = [[AlfrescoRatingService alloc] initWithSession:session];
    self.actionHandler = [[ActionViewHandler alloc] initWithAlfrescoNode:node session:session controller:self];
}

- (void)updateToAlfrescoDocument:(AlfrescoDocument *)node permissions:(AlfrescoPermissions *)permissions contentFilePath:(NSString *)contentFilePath documentLocation:(InAppDocumentLocation)documentLocation session:(id<AlfrescoSession>)session
{
    self.document = node;
    self.documentPermissions = permissions;
    self.session = session;
    self.documentContentFilePath = contentFilePath;
    self.documentLocation = documentLocation;
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    self.ratingService = [[AlfrescoRatingService alloc] initWithSession:session];
    self.actionHandler = [[ActionViewHandler alloc] initWithAlfrescoNode:node session:session controller:self];
}

#pragma mark - NSNotification Handlers

- (void)localDocumentWasRenamed:(NSNotification *)notification
{
    self.documentContentFilePath = [notification.userInfo objectForKey:kAlfrescoLocalDocumentNewName];
}

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    self.ratingService = [[AlfrescoRatingService alloc] initWithSession:self.session];
}

@end

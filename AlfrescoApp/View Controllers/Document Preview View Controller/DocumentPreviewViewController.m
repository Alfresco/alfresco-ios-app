//
//  DocumentPreviewViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "DocumentPreviewViewController.h"
#import "ActionCollectionView.h"
#import "ThumbnailImageView.h"
#import "ThumbnailDownloader.h"
#import "PreviewViewController.h"
#import "MBProgressHUD.h"
#import "Utility.h"
#import "ErrorDescriptions.h"
#import "UniversalDevice.h"
#import "MetaDataViewController.h"
#import "VersionHistoryViewController.h"
#import "PagedScrollView.h"
#import "CommentViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AlfrescoRatingService.h"
#import "FavouriteManager.h"
#import <MessageUI/MessageUI.h>
#import "ThemeUtil.h"

typedef NS_ENUM(NSUInteger, PagingScrollViewSegmentType)
{
    PagingScrollViewSegmentTypePreview = 0,
    PagingScrollViewSegmentTypeMetadata,
    PagingScrollViewSegmentTypeVersionHistory,
    PagingScrollViewSegmentTypeComments
};

@interface DocumentPreviewViewController () <ActionCollectionViewDelegate, PagedScrollViewDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong, readwrite) AlfrescoDocument *document;
@property (nonatomic, strong, readwrite) AlfrescoPermissions *documentPermissions;
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong, readwrite) AlfrescoRatingService *ratingService;
@property (nonatomic, strong, readwrite) MBProgressHUD *progressHUD;
@property (nonatomic, strong, readwrite) NSString *previewImageFolderURLString;
@property (nonatomic, weak, readwrite) IBOutlet ThumbnailImageView *documentThumbnail;
@property (nonatomic, weak, readwrite) IBOutlet UIView *shareMenuContainer;
@property (nonatomic, weak, readwrite) IBOutlet PagedScrollView *pagingScrollView;
@property (nonatomic, weak, readwrite) IBOutlet UISegmentedControl *pagingSegmentControl;
@property (nonatomic, strong, readwrite) NSMutableArray *pagingControllers;

@end

@implementation DocumentPreviewViewController

- (instancetype)initWithAlfrescoDocument:(AlfrescoDocument *)document permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session;
{
    self = [super init];
    if (self)
    {
        self.document = document;
        self.documentPermissions = permissions;
        self.session = session;
        self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
        self.ratingService = [[AlfrescoRatingService alloc] initWithSession:session];
        self.previewImageFolderURLString = [[AlfrescoFileManager sharedManager] thumbnailsImgPreviewFolderPath];
        self.pagingControllers = [NSMutableArray array];
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
    
    self.title = self.document.name;
    
    UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewDocument:)];
    imageTap.numberOfTapsRequired = 1;
    [self.documentThumbnail addGestureRecognizer:imageTap];
    
    // collection menu
    ActionCollectionRow *alfrescoActions = [[ActionCollectionRow alloc] initWithItems:@[[ActionCollectionItem favouriteItem], [ActionCollectionItem likeItem]]];
    ActionCollectionRow *shareRow = [[ActionCollectionRow alloc] initWithItems:@[[ActionCollectionItem emailItem],
                                                                                 [ActionCollectionItem openInItem]]];
    ActionCollectionView *actionView = [[ActionCollectionView alloc] initWithRows:@[alfrescoActions, shareRow] delegate:self];
    
    CGRect actionViewFrame = self.shareMenuContainer.frame;
    actionViewFrame.origin.y = self.view.frame.size.height - actionView.frame.size.height;
    actionViewFrame.size.height = actionView.frame.size.height;
    self.shareMenuContainer.frame = actionViewFrame;
    [self.shareMenuContainer addSubview:actionView];
    
    // setup the paging view
    [self setupPagingScrollView];
    
    // setup the preview image
    NSString *uniqueIdentifier = uniqueFileNameForNode(self.document);
    NSString *filePath = [[self.previewImageFolderURLString stringByAppendingPathComponent:uniqueIdentifier] stringByAppendingPathExtension:@"png"];
    
    if ([[AlfrescoFileManager sharedManager] fileExistsAtPath:filePath])
    {
        UIImage *documentPreviewImage = [UIImage imageWithContentsOfFile:filePath];
        self.documentThumbnail.image = documentPreviewImage;
    }
    else
    {
        UIImage *placeholderImage = imageForType([self.document.name pathExtension]);
        self.documentThumbnail.image = placeholderImage;
        
        __weak typeof(self) weakSelf = self;
        [[ThumbnailDownloader sharedManager] retrieveImageForDocument:self.document toFolderAtPath:self.previewImageFolderURLString renditionType:@"imgpreview" session:self.session completionBlock:^(NSString *savedFileName, NSError *error) {
            if (savedFileName)
            {
                [weakSelf.documentThumbnail setImageAtPath:savedFileName withFade:YES];
            }
        }];
    }
    
    // localise the UI
    [self localiseUI];
    
    [self updateActionButtons];
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (!IS_IPAD)
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private Functions

- (void)showHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.progressHUD)
        {
            self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:self.progressHUD];
        }
        [self.progressHUD show:YES];
    });
}

- (void)hideHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hide:YES];
    });
}

- (void)previewDocument:(id)sender
{
    NSString *downloadDestinationPath = [[[AlfrescoFileManager sharedManager] documentPreviewDocumentFolderPath] stringByAppendingPathComponent:self.document.name];
    
    [self downloadContentOfDocumentToLocation:downloadDestinationPath completionBlock:^(NSString *fileLocation) {
        PreviewViewController *previewController = [[PreviewViewController alloc] initWithDocument:self.document documentPermissions:self.documentPermissions contentFilePath:fileLocation session:self.session displayOverlayCloseButton:YES];
        
        previewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [self addChildViewController:previewController];
        [self.view addSubview:previewController.view];
        [previewController didMoveToParentViewController:self];
    }];
}

- (void)downloadContentOfDocumentToLocation:(NSString *)outputLocation completionBlock:(void (^)(NSString *fileLocation))completionBlock
{
    if (completionBlock != NULL)
    {
        NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:outputLocation append:NO];
        
        [self showHUD];
        [self.documentService retrieveContentOfDocument:self.document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
            [self hideHUD];
            if (succeeded)
            {
                completionBlock(outputLocation);
            }
            else
            {
                // display an error
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
            }
        } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
            // progress indicator update
        }];
    }
}

- (void)setupPagingScrollView
{
    MetaDataViewController *metaDataController = [[MetaDataViewController alloc] initWithAlfrescoNode:self.document session:self.session];
    VersionHistoryViewController *versionHistoryController = [[VersionHistoryViewController alloc] initWithDocument:self.document session:self.session];
    CommentViewController *commentViewController = [[CommentViewController alloc] initWithAlfrescoNode:self.document permissions:self.documentPermissions session:self.session];
    [self.pagingControllers addObject:metaDataController];
    [self.pagingControllers addObject:versionHistoryController];
    [self.pagingControllers addObject:commentViewController];
    
    [self.pagingScrollView addSubview:self.documentThumbnail];
    for (int i = 0; i < self.pagingControllers.count; i++)
    {
        UIViewController *currentController = self.pagingControllers[i];
        [self.pagingScrollView addSubview:currentController.view];
    }
}

- (void)localiseUI
{
    [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.preview.title", @"Preview Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypePreview];
    [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.metadata.title", @"Metadata Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeMetadata];
    [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.version.history.title", @"Version Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeVersionHistory];
    [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.comments.title", @"Comments Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeComments];
}

- (void)updateActionButtons
{
    // check node is favourited
    [[FavouriteManager sharedManager] isNodeFavorite:self.document session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        if (isFavorite)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnfavourite,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unfavourite", @"Unfavourite Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"repository.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierFavourite userInfo:userInfo];
        }
    }];
    
    // check and update the like node
    [self.ratingService isNodeLiked:self.document completionBlock:^(BOOL succeeded, BOOL isLiked, NSError *error) {
        if (succeeded && isLiked)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnlike,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unlike", @"Unlike Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"repository.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierLike userInfo:userInfo];
        }
    }];
}

#pragma mark - IBActions

- (IBAction)segmentValueChanged:(id)sender
{
    PagingScrollViewSegmentType selectedSegment = self.pagingSegmentControl.selectedSegmentIndex;
    [self.pagingScrollView scrollToDisplayViewAtIndex:selectedSegment animated:YES];
}

#pragma mark - ActionCollectionViewDelegate Functions

- (void)didPressActionItem:(ActionCollectionItem *)actionItem
{
    // handle the action
    if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierLike])
    {
        [self.ratingService likeNode:self.document completionBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
            {
                NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnlike,
                                           kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unlike", @"Unlike Action"),
                                           kActionCollectionItemUpdateItemImageKey : @"repository.png"};
                [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierLike userInfo:userInfo];
            }
        }];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierUnlike])
    {
        [self.ratingService unlikeNode:self.document completionBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
            {
                NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierLike,
                                           kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.like", @"Like Action"),
                                           kActionCollectionItemUpdateItemImageKey : @"sync-status-success.png"};
                [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierUnlike userInfo:userInfo];
            }
        }];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierFavourite])
    {
        [[FavouriteManager sharedManager] addFavorite:self.document session:self.session completionBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
            {
                NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnfavourite,
                                           kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unfavourite", @"Unfavourite Action"),
                                           kActionCollectionItemUpdateItemImageKey : @"repository.png"};
                [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierFavourite userInfo:userInfo];
            }
        }];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierUnfavourite])
    {
        [[FavouriteManager sharedManager] removeFavorite:self.document session:self.session completionBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
            {
                NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierFavourite,
                                           kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.favourite", @"Favourite Action"),
                                           kActionCollectionItemUpdateItemImageKey : @"sync-status-success.png"};
                [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierUnfavourite userInfo:userInfo];
            }
        }];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierEmail])
    {
        if ([MFMailComposeViewController canSendMail])
        {
            NSString *downloadDestinationPath = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:self.document.name];
            
            __weak typeof(self) weakSelf = self;
            [self downloadContentOfDocumentToLocation:downloadDestinationPath completionBlock:^(NSString *fileLocation) {
                MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
                emailController.mailComposeDelegate = weakSelf;
                [emailController setSubject:self.document.name];
                
                // attachment
                NSString *mimeType = [Utility mimeTypeForFileExtension:self.document.name];;
                if (!mimeType)
                {
                    mimeType = @"application/octet-stream";
                }
                NSData *documentData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:[NSURL fileURLWithPath:fileLocation]];
                [emailController addAttachmentData:documentData mimeType:mimeType fileName:self.document.name];
                
                // content body template
                NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"emailTemplate" ofType:@"html" inDirectory:@"Email Template"];
                NSString *htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
                [emailController setMessageBody:htmlString isHTML:YES];
                [ThemeUtil applyThemeToNavigationController:emailController];
                
                [UniversalDevice displayModalViewController:emailController onController:self withCompletionBlock:nil];
            }];
        }
        else
        {
            // discussion on the UI if the email hasn't been setup on the device
        }
    }
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

#pragma mark - MFMailComposeViewControllerDelegate Functions

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (result != MFMailComposeResultFailed)
    {
        [controller dismissViewControllerAnimated:YES completion:nil];
    }
}

@end

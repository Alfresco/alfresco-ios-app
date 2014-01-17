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
#import "DownloadManager.h"
#import "UIAlertView+ALF.h"

typedef NS_ENUM(NSUInteger, PagingScrollViewSegmentType)
{
    PagingScrollViewSegmentTypePreview = 0,
    PagingScrollViewSegmentTypeMetadata,
    PagingScrollViewSegmentTypeVersionHistory,
    PagingScrollViewSegmentTypeComments,
    PagingScrollViewSegmentType_MAX
};

@interface DocumentPreviewViewController () <ActionCollectionViewDelegate, PagedScrollViewDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, UIDocumentInteractionControllerDelegate>

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
//@property (nonatomic, strong, readwrite) PreviewViewController *hiddenPreviewController;
@property (nonatomic, strong, readwrite) UIDocumentInteractionController *documentInteractionController;

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
    
    // collection view
    [self createAndAddActionCollectionView];
    
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
    [self retrieveContentOfDocument:self.document completionBlock:^(NSString *fileLocation) {
        PreviewViewController *previewController = [[PreviewViewController alloc] initWithDocument:self.document documentPermissions:self.documentPermissions contentFilePath:fileLocation session:self.session displayOverlayCloseButton:YES];
        
        previewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [self addChildViewController:previewController];
        [self.view addSubview:previewController.view];
        [previewController didMoveToParentViewController:self];
    }];
}

- (void)retrieveContentOfDocument:(AlfrescoDocument *)document completionBlock:(void (^)(NSString *fileLocation))completionBlock
{
    if (completionBlock != NULL)
    {
        AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
        NSString *downloadPath = [[fileManager documentPreviewDocumentFolderPath] stringByAppendingPathComponent:filenameAppendedWithDateModififed(document.name, document)];
        
        if ([fileManager fileExistsAtPath:downloadPath])
        {
            completionBlock(downloadPath);
        }
        else
        {
            NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:downloadPath append:NO];
            
            [self showHUD];
            [self.documentService retrieveContentOfDocument:document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                [self hideHUD];
                if (succeeded)
                {
                    completionBlock(downloadPath);
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
}

- (void)setupPagingScrollView
{
    MetaDataViewController *metaDataController = [[MetaDataViewController alloc] initWithAlfrescoNode:self.document session:self.session];
    VersionHistoryViewController *versionHistoryController = [[VersionHistoryViewController alloc] initWithDocument:self.document session:self.session];
    CommentViewController *commentViewController = [[CommentViewController alloc] initWithAlfrescoNode:self.document permissions:self.documentPermissions session:self.session];

    for (int i = 0; i < PagingScrollViewSegmentType_MAX; i++)
    {
        [self.pagingControllers addObject:[NSNull null]];
    }
    
    [self.pagingControllers insertObject:metaDataController atIndex:PagingScrollViewSegmentTypeMetadata];
    [self.pagingControllers insertObject:versionHistoryController atIndex:PagingScrollViewSegmentTypeVersionHistory];
    [self.pagingControllers insertObject:commentViewController atIndex:PagingScrollViewSegmentTypeComments];
    
    [self.pagingScrollView addSubview:self.documentThumbnail];
    for (int i = 0; i < self.pagingControllers.count; i++)
    {
        if (![self.pagingControllers[i] isKindOfClass:[NSNull class]])
        {
            UIViewController *currentController = self.pagingControllers[i];
            [self.pagingScrollView addSubview:currentController.view];
        }
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

- (void)createAndAddActionCollectionView
{
    NSMutableArray *firstRowItems = [NSMutableArray arrayWithObjects:[ActionCollectionItem favouriteItem],
                                     [ActionCollectionItem likeItem],
                                     [ActionCollectionItem downloadItem],
                                     nil];
    NSMutableArray *secondRowItems = [NSMutableArray arrayWithObjects:[ActionCollectionItem openInItem], nil];
    
    if (self.documentPermissions.canComment)
    {
        [firstRowItems addObject:[ActionCollectionItem commentItem]];
    }
    
    if (self.documentPermissions.canDelete)
    {
        [firstRowItems addObject:[ActionCollectionItem deleteItem]];
    }
    
    if ([MFMailComposeViewController canSendMail])
    {
        [secondRowItems addObject:[ActionCollectionItem emailItem]];
    }
    
    if (![Utility isAudioOrVideo:self.document.name])
    {
        [secondRowItems addObject:[ActionCollectionItem printItem]];
    }
    
    ActionCollectionRow *alfrescoActions = [[ActionCollectionRow alloc] initWithItems:firstRowItems];
    ActionCollectionRow *shareRow = [[ActionCollectionRow alloc] initWithItems:secondRowItems];
    ActionCollectionView *actionView = [[ActionCollectionView alloc] initWithRows:@[alfrescoActions, shareRow] delegate:self];
    
    [self.shareMenuContainer addSubview:actionView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(actionView);
    [self.shareMenuContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[actionView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
    [self.shareMenuContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionView]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
}

#pragma mark - IBActions

- (IBAction)segmentValueChanged:(id)sender
{
    PagingScrollViewSegmentType selectedSegment = self.pagingSegmentControl.selectedSegmentIndex;
    [self.pagingScrollView scrollToDisplayViewAtIndex:selectedSegment animated:YES];
}

#pragma mark - ActionCollectionViewDelegate Functions

- (void)didPressActionItem:(ActionCollectionItem *)actionItem cell:(UICollectionViewCell *)cell inView:(UICollectionView *)view
{
    if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierLike])
    {
        [self handlePressedLikeWithActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierUnlike])
    {
        [self handlePressedUnlikeWithActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierFavourite])
    {
        [self handlePressedFavouriteWithActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierUnfavourite])
    {
        [self handlePressedUnfavouriteWithActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierEmail])
    {
        [self handlePressedEmailWithActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierDownload])
    {
        [self handlePressedDownloadWithActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierComment])
    {
        [self handlePressedCommentWithActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierPrint])
    {
        [self handlePressedPrintWithActionItem:actionItem cell:cell inView:view];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierOpenIn])
    {
        [self handlePressedOpenInActionItem:actionItem cell:cell inView:view];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierDelete])
    {
        [self handlePressedDeleteActionItem:actionItem];
    }
}

#pragma mark - Action Handler Functions

- (void)handlePressedLikeWithActionItem:(ActionCollectionItem *)actionItem
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

- (void)handlePressedUnlikeWithActionItem:(ActionCollectionItem *)actionItem
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

- (void)handlePressedFavouriteWithActionItem:(ActionCollectionItem *)actionItem
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

- (void)handlePressedUnfavouriteWithActionItem:(ActionCollectionItem *)actionItem
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

- (void)handlePressedEmailWithActionItem:(ActionCollectionItem *)actionItem
{
    if ([MFMailComposeViewController canSendMail])
    {
        __weak typeof(self) weakSelf = self;
        
        [self retrieveContentOfDocument:self.document completionBlock:^(NSString *fileLocation) {
            if (fileLocation)
            {
                MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
                emailController.mailComposeDelegate = weakSelf;
                [emailController setSubject:weakSelf.document.name];
                
                // attachment
                NSString *mimeType = [Utility mimeTypeForFileExtension:weakSelf.document.name];;
                if (!mimeType)
                {
                    mimeType = @"application/octet-stream";
                }
                NSData *documentData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:[NSURL fileURLWithPath:fileLocation]];
                [emailController addAttachmentData:documentData mimeType:mimeType fileName:weakSelf.document.name];
                
                // content body template
                NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"emailTemplate" ofType:@"html" inDirectory:@"Email Template"];
                NSString *htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
                [emailController setMessageBody:htmlString isHTML:YES];
                
                [UniversalDevice displayModalViewController:emailController onController:weakSelf withCompletionBlock:nil];
            }
        }];
    }
}

- (void)handlePressedDownloadWithActionItem:(ActionCollectionItem *)actionItem
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *downloadPath = [[fileManager documentPreviewDocumentFolderPath] stringByAppendingPathComponent:filenameAppendedWithDateModififed(self.document.name, self.document)];
    
    if ([fileManager fileExistsAtPath:downloadPath])
    {
        // rename the file to remove the date modified suffix, and then copy it to downloads
        NSString *tempPath = [[fileManager documentPreviewDocumentFolderPath] stringByAppendingPathComponent:self.document.name];
        
        NSError *tempFileError = nil;
        [fileManager copyItemAtPath:downloadPath toPath:tempPath error:&tempFileError];
        
        if (tempFileError)
        {
            AlfrescoLogError(@"Unable to copy file from path: %@ to path: %@", downloadPath, tempPath);
        }
        else
        {
            [[DownloadManager sharedManager] downloadDocument:self.document contentPath:tempPath session:self.session];
            
            NSError *deleteError = nil;
            [fileManager removeItemAtPath:tempPath error:&deleteError];
            
            if (deleteError)
            {
                AlfrescoLogError(@"Unable to delete file at path: %@", tempPath);
            }
        }
    }
    else
    {
        [[DownloadManager sharedManager] downloadDocument:self.document contentPath:nil session:self.session];
    }
}

- (void)handlePressedCommentWithActionItem:(ActionCollectionItem *)actionItem
{
    self.pagingSegmentControl.selectedSegmentIndex = PagingScrollViewSegmentTypeComments;
    [self.pagingScrollView scrollToDisplayViewAtIndex:PagingScrollViewSegmentTypeComments animated:YES];
    CommentViewController *commentsViewController = [self.pagingControllers objectAtIndex:PagingScrollViewSegmentTypeComments];
    [commentsViewController focusCommentEntry];
}

- (void)handlePressedPrintWithActionItem:(ActionCollectionItem *)actionItem cell:(UICollectionViewCell *)cell inView:(UICollectionView *)view
{
    [self retrieveContentOfDocument:self.document completionBlock:^(NSString *fileLocation) {
        if (fileLocation)
        {
            PreviewViewController *hiddenPreviewController = [[PreviewViewController alloc] initWithFilePath:fileLocation finishedLoadingCompletionBlock:^(UIWebView *webView, BOOL loadedIntoWebView) {
                if (loadedIntoWebView)
                {
                    NSURL *fileURL = [NSURL fileURLWithPath:fileLocation];
                    
                    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
                    
                    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
                    printInfo.outputType = UIPrintInfoOutputGeneral;
                    printInfo.jobName = self.document.name;
                    
                    printController.printInfo = printInfo;
                    printController.printFormatter = [webView viewPrintFormatter];
                    printController.showsPageRange = YES;
                    
                    UIPrintInteractionCompletionHandler printCompletionHandler = ^(UIPrintInteractionController *printController, BOOL completed, NSError *printError) {
                        if (!completed && printError)
                        {
                            AlfrescoLogError(@"Unable to print document %@ with error: %@", fileURL.path, printError.localizedDescription);
                        }
                    };
                    
                    if (IS_IPAD)
                    {
                        [printController presentFromRect:cell.frame inView:view animated:YES completionHandler:printCompletionHandler];
                    }
                    else
                    {
                        [printController presentAnimated:YES completionHandler:printCompletionHandler];
                    }
                }
            }];
            hiddenPreviewController.view.hidden = YES;
            [self addChildViewController:hiddenPreviewController];
            [self.view addSubview:hiddenPreviewController.view];
            [hiddenPreviewController didMoveToParentViewController:self];
        }
    }];
}

- (void)handlePressedOpenInActionItem:(ActionCollectionItem *)actionItem cell:(UICollectionViewCell *)cell inView:(UICollectionView *)view
{
    [self retrieveContentOfDocument:self.document completionBlock:^(NSString *fileLocation) {
        if (fileLocation)
        {
            NSURL *fileURL = [NSURL fileURLWithPath:fileLocation];
            
            if (!self.documentInteractionController)
            {
                UIDocumentInteractionController *docController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
                docController.delegate = self;
                self.documentInteractionController = docController;
            }
            
            if (IS_IPAD)
            {
                [self.documentInteractionController presentOpenInMenuFromRect:cell.frame inView:view animated:YES];
            }
            else
            {
                [self.documentInteractionController presentPreviewAnimated:YES];
            }
        }
    }];
}

- (void)handlePressedDeleteActionItem:(ActionCollectionItem *)actionItem
{
    UIAlertView *confirmDeletion = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"action.delete.confirmation.title", @"Delete Confirmation Title")
                                                              message:NSLocalizedString(@"action.delete.confirmation.message", @"Delete Confirmation Message")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                    otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    [confirmDeletion showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
        if (!isCancelButton)
        {
            [self showHUD];
            __weak typeof(self) weakSelf = self;
            [self.documentService deleteNode:self.document completionBlock:^(BOOL succeeded, NSError *error) {
                [self hideHUD];
                if (succeeded)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDocumentDeletedOnServerNotification object:weakSelf.document];
                    [UniversalDevice clearDetailViewController];
                    NSString *successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message", @"Delete Success Message"), weakSelf.document.name];
                    displayInformationMessageWithTitle(successMessage, NSLocalizedString(@"action.delete.success.title", @"Delete Success Title"));
                }
                else
                {
                    NSString *failedMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.failed.message", @"Delete Failed Message"), weakSelf.document.name];
                    displayErrorMessageWithTitle(failedMessage, NSLocalizedString(@"action.delete.failed.title", @"Delete Failed Title"));
                    [Notifier notifyWithAlfrescoError:error];
                }
            }];
        }
    }];
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

#pragma mark - UIDocumentInteractionControllerDelegate Functions

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    return self;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    // TODO: Saveback API's
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    self.documentInteractionController = nil;
}

@end

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
#import "FavouriteManager.h"
#import <MessageUI/MessageUI.h>
#import "DownloadManager.h"
#import "SyncManager.h"
#import "UIAlertView+ALF.h"
#import <MobileCoreServices/MobileCoreServices.h>

typedef NS_ENUM(NSUInteger, PagingScrollViewSegmentType)
{
    PagingScrollViewSegmentTypePreview = 0,
    PagingScrollViewSegmentTypeMetadata,
    PagingScrollViewSegmentTypeVersionHistory,
    PagingScrollViewSegmentTypeComments,
    PagingScrollViewSegmentType_MAX
};

@interface DocumentPreviewViewController () <ActionCollectionViewDelegate, PagedScrollViewDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, UIDocumentInteractionControllerDelegate, CommentViewControllerDelegate>

@property (nonatomic, strong, readwrite) AlfrescoDocument *document;
@property (nonatomic, strong, readwrite) AlfrescoPermissions *documentPermissions;
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong, readwrite) NSString *documentContentFilePath;
@property (nonatomic, strong, readwrite) AlfrescoRatingService *ratingService;
@property (nonatomic, strong, readwrite) MBProgressHUD *progressHUD;
@property (nonatomic, strong, readwrite) NSString *previewImageFolderURLString;
@property (nonatomic, weak, readwrite) IBOutlet ThumbnailImageView *documentThumbnail;
@property (nonatomic, weak, readwrite) IBOutlet ActionCollectionView *actionMenuView;
@property (nonatomic, weak, readwrite) IBOutlet PagedScrollView *pagingScrollView;
@property (nonatomic, weak, readwrite) IBOutlet UISegmentedControl *pagingSegmentControl;
@property (nonatomic, strong, readwrite) NSMutableArray *pagingControllers;
@property (nonatomic, strong, readwrite) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic, assign, readwrite) InAppDocumentLocation documentLocation;

@end

@implementation DocumentPreviewViewController

- (instancetype)initWithAlfrescoDocument:(AlfrescoDocument *)document
                             permissions:(AlfrescoPermissions *)permissions
                         contentFilePath:(NSString *)contentFilePath
                        documentLocation:(InAppDocumentLocation)documentLocation
                                 session:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.document = document;
        self.documentPermissions = permissions;
        self.session = session;
        self.documentContentFilePath = contentFilePath;
        self.documentLocation = documentLocation;
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
    
    if (self.documentLocation == InAppDocumentLocationLocalFiles)
    {
        self.title = self.documentContentFilePath.lastPathComponent;
    }
    else
    {
        self.title = self.document.name;
    }
    
    UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewDocument:)];
    imageTap.numberOfTapsRequired = 1;
    [self.documentThumbnail addGestureRecognizer:imageTap];
    
    // collection view
    [self setupActionCollectionView];
    
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
    void (^preparePreviewController)(PreviewViewController *) = ^(PreviewViewController *previewController)
    {
        previewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [self addChildViewController:previewController];
        [self.view addSubview:previewController.view];
        [previewController didMoveToParentViewController:self];
    };
    
    if (self.documentContentFilePath)
    {
        PreviewViewController *previewController = [[PreviewViewController alloc] initWithDocument:self.document
                                                                               documentPermissions:self.documentPermissions
                                                                                   contentFilePath:self.documentContentFilePath
                                                                                           session:self.session
                                                                         displayOverlayCloseButton:YES];
        preparePreviewController(previewController);
    }
    else
    {
        [self retrieveContentOfDocument:self.document completionBlock:^(NSString *fileLocation) {
            PreviewViewController *previewController = [[PreviewViewController alloc] initWithDocument:self.document
                                                                                   documentPermissions:self.documentPermissions
                                                                                       contentFilePath:fileLocation
                                                                                               session:self.session
                                                                             displayOverlayCloseButton:YES];
            preparePreviewController(previewController);
        }];
    }
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
    CommentViewController *commentViewController = [[CommentViewController alloc] initWithAlfrescoNode:self.document permissions:self.documentPermissions session:self.session delegate:self];
    
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
    [self.pagingSegmentControl setTitle:NSLocalizedString(@"document.segment.nocomments.title", @"Comments Segment Title") forSegmentAtIndex:PagingScrollViewSegmentTypeComments];
}

- (void)updateActionButtons
{
    // check node is favourited
    [[FavouriteManager sharedManager] isNodeFavorite:self.document session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        if (isFavorite)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnfavourite,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unfavourite", @"Unfavourite Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-favourited.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierFavourite userInfo:userInfo];
        }
    }];
    
    // check and update the like node
    [self.ratingService isNodeLiked:self.document completionBlock:^(BOOL succeeded, BOOL isLiked, NSError *error) {
        if (succeeded && isLiked)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnlike,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unlike", @"Unlike Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-liked.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierLike userInfo:userInfo];
        }
    }];
}

- (void)setupActionCollectionView
{
    BOOL isRestricted = NO;
    
    NSMutableArray *items = [NSMutableArray array];
    
    if (self.documentLocation == InAppDocumentLocationLocalFiles)
    {
        [items addObject:[ActionCollectionItem renameItem]];
    }
    else
    {
        [items addObject:[ActionCollectionItem favouriteItem]];
        [items addObject:[ActionCollectionItem likeItem]];
        [items addObject:[ActionCollectionItem downloadItem]];
        
        if (self.documentPermissions.canComment)
        {
            [items addObject:[ActionCollectionItem commentItem]];
        }
    }
    
    if (!isRestricted)
    {
        if ([MFMailComposeViewController canSendMail])
        {
            [items addObject:[ActionCollectionItem emailItem]];
        }
        
        if (![Utility isAudioOrVideo:self.document.name])
        {
            [items addObject:[ActionCollectionItem printItem]];
        }
        
        [items addObject:[ActionCollectionItem openInItem]];
    }
    
    if (self.documentLocation == InAppDocumentLocationLocalFiles || self.documentPermissions.canDelete)
    {
        [items addObject:[ActionCollectionItem deleteItem]];
    }
    
    self.actionMenuView.items = items;
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
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierRename])
    {
        [self handlePressedRenameActionItem:actionItem];
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
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-liked.png"};
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
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-unliked.png"};
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
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-favourited.png"};
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
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-unfavourited.png"};
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
                NSString *mimeType = [Utility mimeTypeForFileExtension:weakSelf.document.name];
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
            // define a print block
            void (^printBlock)(UIWebView *webView) = ^(UIWebView *webView) {
                NSURL *fileURL = [NSURL fileURLWithPath:fileLocation];
                
                UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
                
                UIPrintInfo *printInfo = [UIPrintInfo printInfo];
                printInfo.outputType = UIPrintInfoOutputGeneral;
                printInfo.jobName = self.document.name;
                
                printController.printInfo = printInfo;
                if (webView)
                {
                    printController.printFormatter = [webView viewPrintFormatter];
                }
                else
                {
                    printController.printingItem = fileURL;
                }
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
            };
            
            // determine whether to use defult OS printing
            NSSet *printableUTIs = [UIPrintInteractionController printableUTIs];
            CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileLocation.pathExtension, NULL);
            __block BOOL useNativePrinting = NO;
            [printableUTIs enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                if (UTTypeConformsTo(UTI, (__bridge CFStringRef)obj))
                {
                    useNativePrinting = YES;
                    *stop = YES;
                }
            }];
            CFRelease(UTI);
            
            if (useNativePrinting)
            {
                printBlock(nil);
            }
            else
            {
                PreviewViewController *hiddenPreviewController = [[PreviewViewController alloc] initWithFilePath:fileLocation finishedLoadingCompletionBlock:^(UIWebView *webView, BOOL loadedIntoWebView) {
                    if (loadedIntoWebView)
                    {
                        printBlock(webView);
                    }
                }];
                hiddenPreviewController.view.hidden = YES;
                [self addChildViewController:hiddenPreviewController];
                [self.view addSubview:hiddenPreviewController.view];
                [hiddenPreviewController didMoveToParentViewController:self];
            }
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
            
            BOOL canOpenIn = [self.documentInteractionController presentOpenInMenuFromRect:cell.frame inView:view animated:YES];
            
            if (!canOpenIn)
            {
                NSString *cantOpenMessage = NSLocalizedString(@"document.open-in.noapps.message", @"No Apps Message");
                NSString *cantOpenTitle = NSLocalizedString(@"document.open-in.noapps.title", @"No Apps Title");
                displayInformationMessageWithTitle(cantOpenMessage, cantOpenTitle);
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
            if (self.documentLocation == InAppDocumentLocationLocalFiles)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDeleteLocalDocumentNotification object:self.documentContentFilePath];
                [UniversalDevice clearDetailViewController];
                NSString *successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message", @"Delete Success Message"), self.documentContentFilePath.lastPathComponent];
                displayInformationMessageWithTitle(successMessage, NSLocalizedString(@"action.delete.success.title", @"Delete Success Title"));
            }
            else
            {
                [self showHUD];
                __weak typeof(self) weakSelf = self;
                [self.documentService deleteNode:self.document completionBlock:^(BOOL succeeded, NSError *error) {
                    [self hideHUD];
                    if (succeeded)
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDocumentDeletedOnServerNotification object:weakSelf.document];
                        [UniversalDevice clearDetailViewController];
                        
                        SyncManager *syncManager = [SyncManager sharedManager];
                        if ([syncManager isNodeInSyncList:self.document])
                        {
                            [syncManager deleteNodeFromSync:self.document withCompletionBlock:^(BOOL savedLocally) {
                                
                                NSString *successMessage = @"";
                                if (savedLocally)
                                {
                                    successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message.sync", @"Delete Success Message"), weakSelf.document.name];
                                }
                                else
                                {
                                    successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message", @"Delete Success Message"), weakSelf.document.name];
                                }
                                displayInformationMessageWithTitle(successMessage, NSLocalizedString(@"action.delete.success.title", @"Delete Success Title"));
                            }];
                        }
                        else
                        {
                            NSString *successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message", @"Delete Success Message"), weakSelf.document.name];
                            displayInformationMessageWithTitle(successMessage, NSLocalizedString(@"action.delete.success.title", @"Delete Success Title"));
                        }
                    }
                    else
                    {
                        NSString *failedMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.failed.message", @"Delete Failed Message"), weakSelf.document.name];
                        displayErrorMessageWithTitle(failedMessage, NSLocalizedString(@"action.delete.failed.title", @"Delete Failed Title"));
                        [Notifier notifyWithAlfrescoError:error];
                    }
                }];
            }
        }
    }];
}

- (void)handlePressedRenameActionItem:(ActionCollectionItem *)actionItem
{
    UIAlertView *renameAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"action.rename.alert.title", @"Rename")
                                                          message:NSLocalizedString(@"action.rename.alert.message", @"Rename document to, message")
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    renameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [renameAlert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
        if (!isCancelButton)
        {
            NSString *newName = [[renameAlert textFieldAtIndex:0] text];
            
            if (newName)
            {
                newName = [newName stringByAppendingPathExtension:self.documentContentFilePath.pathExtension];
                NSString *newPath = [[self.documentContentFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newName];
                
                [[DownloadManager sharedManager] renameLocalDocument:self.documentContentFilePath.lastPathComponent toName:newName];
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoLocalDocumentRenamedNotification object:self.documentContentFilePath userInfo:@{kAlfrescoLocalDocumentNewName : newPath}];
                
                NSString *successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.rename.success.message", @"Rename Success Message"), self.documentContentFilePath.lastPathComponent, newName];
                displayInformationMessageWithTitle(successMessage, NSLocalizedString(@"action.rename.success.title", @"Rename Success Title"));
                self.title = newName;
                self.documentContentFilePath = newPath;
            }
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

#pragma mark - CommentViewControllerDelegate Functions

- (void)commentViewController:(CommentViewController *)controller didUpdateCommentCount:(NSUInteger)commentDisplayedCount hasMoreComments:(BOOL)hasMoreComments
{
    NSString *segmentCommentText = nil;
    
    if (hasMoreComments && commentDisplayedCount >= kMaxItemsPerListingRetrieve)
    {
        segmentCommentText = [NSString stringWithFormat:NSLocalizedString(@"document.segment.comments.hasmore.title", @"Comments Segment Title - Has More"), kMaxItemsPerListingRetrieve];
    }
    else if (commentDisplayedCount > 0)
    {
        segmentCommentText = [NSString stringWithFormat:NSLocalizedString(@"document.segment.comments.title", @"Comments Segment Title - Count"), commentDisplayedCount];
    }
    else
    {
        segmentCommentText = [self.pagingSegmentControl titleForSegmentAtIndex:PagingScrollViewSegmentTypeComments];
    }
    
    [self.pagingSegmentControl setTitle:segmentCommentText forSegmentAtIndex:PagingScrollViewSegmentTypeComments];
}

@end

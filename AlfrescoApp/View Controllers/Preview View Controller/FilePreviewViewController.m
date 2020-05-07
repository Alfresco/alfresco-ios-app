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

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "FilePreviewViewController.h"
#import "ThumbnailImageView.h"
#import "ThumbnailManager.h"
#import "ErrorDescriptions.h"
#import "NavigationViewController.h"
#import "DocumentPreviewManager.h"
#import "FullScreenAnimationController.h"
#import "ALFPreviewController.h"
#import "AlfrescoNode+Sync.h"
#import "RealmSyncCore.h"
#import "AccountManager.h"

static CGFloat const kAnimationFadeSpeed = 0.5f;
static CGFloat const kAnimationDelayTime = 1.0f;
static CGFloat const kPlaceholderToProcessVerticalOffset = 30.0f;
static CGFloat sDownloadProgressHeight;

@interface FilePreviewViewController () <ALFPreviewControllerDelegate,
                                         QLPreviewControllerDataSource,
                                         UIViewControllerTransitioningDelegate>

// Constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightForDownloadContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYAlignmentForProgressContainer;

// Data Models
@property (nonatomic, strong) AlfrescoDocument *document;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoRequest *downloadRequest;
@property (nonatomic, strong) AVPlayerViewController *playerViewController;
@property (nonatomic, strong) FullScreenAnimationController *animationController;
// Used for the file path initialiser
@property (nonatomic, strong) NSString *filePathForFileToLoad;

// IBOutlets
@property (nonatomic, weak) IBOutlet ThumbnailImageView *previewThumbnailImageView;
@property (nonatomic, weak) IBOutlet UIProgressView *downloadProgressView;
@property (nonatomic, weak) IBOutlet UIView *downloadProgressContainer;
@property (nonatomic, weak) IBOutlet UIView *moviePlayerContainer;
@property (nonatomic, weak) IBOutlet UIImageView *moviePlayerPreviewImageView;
// Views
@property (nonatomic, strong) ALFPreviewController *previewController;

@property (nonatomic, strong) UIGestureRecognizer *previewThumbnailSingleTapRecognizer;

@end

@implementation FilePreviewViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.animationController = [FullScreenAnimationController new];
        self.animationController.presentationSpeed = 0.5f;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDocumentCompleted:) name:kAlfrescoDocumentEditedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarting:) name:kDocumentPreviewManagerWillStartDownloadNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgress:) name:kDocumentPreviewManagerProgressNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete:) name:kDocumentPreviewManagerDocumentDownloadCompletedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileLocallyUpdated:) name:kAlfrescoSaveBackLocalComplete object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    }
    return self;
}

- (instancetype)initWithDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session
{
    self = [self init];
    if (self)
    {
        self.document = document;
        self.session = session;
    }
    return self;
}

- (instancetype)initWithFilePath:(NSString *)filePath document:(AlfrescoDocument *)document
{
    self = [self init];
    if (self)
    {
        self.filePathForFileToLoad = filePath;
        self.document = document;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setAccessibilityIdentifiers];
    sDownloadProgressHeight = self.heightForDownloadContainer.constant;
    
    [self refreshViewController];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - IBOutlets

- (IBAction)didPressCancelDownload:(id)sender
{
    [self.downloadRequest cancel];
    [self hideProgressViewAnimated:YES];
    self.downloadProgressView.progress = 0.0f;
    
    // Add single tap "re-download" action to thumbnail view
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleThumbnailSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    self.previewThumbnailSingleTapRecognizer = singleTap;
    self.previewThumbnailImageView.userInteractionEnabled = YES;
    [self.previewThumbnailImageView addGestureRecognizer:singleTap];
}

#pragma mark - IBActions

- (IBAction)playButtonPressed:(id)sender
{
    [self.playerViewController.player play];
    [self presentViewController:self.playerViewController animated:YES completion:nil];
}

#pragma mark - Private Functions

- (void)refreshViewController
{
    self.downloadProgressView.progress = 0.0f;
    
    if (self.filePathForFileToLoad)
    {
        [self displayFileAtPath:self.filePathForFileToLoad];
    }
    else if ([[DocumentPreviewManager sharedManager] hasLocalContentOfDocument:self.document])
    {
        [self displayFileAtPath:[[DocumentPreviewManager sharedManager] filePathForDocument:self.document]];
    }
    else
    {
        // Display a static placeholder image
        [self.previewThumbnailImageView setImage:largeImageForType(self.document.name.pathExtension) withFade:NO];
        
        if ([[DocumentPreviewManager sharedManager] isCurrentlyDownloadingDocument:self.document])
        {
            self.previewThumbnailImageView.alpha = 1.0f;
            self.previewThumbnailImageView.hidden = NO;
        }
        else
        {
            // Request the document download
            self.downloadRequest = [[DocumentPreviewManager sharedManager] downloadDocument:self.document session:self.session];
        }
    }
}

- (void)handleThumbnailSingleTap:(UIGestureRecognizer *)gesture
{
    [self.previewThumbnailImageView removeGestureRecognizer:gesture];
    
    // Restart the document download
    self.downloadRequest = [[DocumentPreviewManager sharedManager] downloadDocument:self.document session:self.session];
}

- (void)dismiss:(UIBarButtonItem *)sender
{
    if (!IS_IPAD)
    {
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 * Create or destroy an ALFPreviewController
 */

- (void)createPreviewerForFilePath:(NSString *)filePath animated:(BOOL)animated
{
    self.filePathForFileToLoad = filePath;

    ALFPreviewController *previewVC = [ALFPreviewController new];
    
    if (self.filePathForFileToLoad)
    {
        previewVC.previewController.dataSource = self;
    }
    
    previewVC.gestureDelegate = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        previewVC.view.hidden = YES;
        previewVC.previewController.currentPreviewItemIndex = 1;
        previewVC.view.frame = self.view.bounds;
        [self.view addSubview:previewVC.view];
        
        self.previewController = previewVC;
        
        [self.previewController changeButtonImageIsFullscreen:self.fullScreenMode];
        if(self.fullScreenMode)
        {
            [self.previewController hideButton:YES];
        }
        
        if (animated)
        {
            previewVC.view.alpha = 0.0f;
            previewVC.view.hidden = NO;
            [UIView animateWithDuration:kAnimationFadeSpeed animations:^{
                self.previewThumbnailImageView.alpha = 0.0f;
                previewVC.view.alpha = 1.0f;
            }];
        }
        else
        {
            previewVC.view.hidden = NO;
            previewVC.view.alpha = 1.0;
        }
    });
}

- (void)destroyPreviewerAnimated:(BOOL)animated
{
    if(self.previewController)
    {
        if (animated)
        {
            [UIView animateWithDuration:kAnimationFadeSpeed animations:^{
                self.previewController.view.alpha = 0.0f;
            } completion:^(BOOL finished) {
                [self.previewController.view removeFromSuperview];
                self.previewController = nil;
            }];
        }
        else
        {
            [self.previewController.view removeFromSuperview];
            self.previewController = nil;
        }
    }
}

/**
 * Create or destroy an AVPlayerViewController
 */

- (void)createMediaPlayerForFilePath:(NSString *)filePath animated:(BOOL)animated
{
    self.moviePlayerContainer.hidden = YES;
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = [AVPlayer playerWithURL:fileURL];
    self.playerViewController = playerViewController;
    
    // Generate a movie preview
    // Synchronously generates a preview
    AVAsset *fileAsset = [AVURLAsset assetWithURL:fileURL];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:fileAsset];
    generator.appliesPreferredTrackTransform = YES;
    
    int frameTimeStart = 1;
    int frameLocation = 1;
    
    CGImageRef frameImageRef = [generator copyCGImageAtTime:CMTimeMake(frameTimeStart, frameLocation) actualTime:nil error:nil];
    
    if (frameImageRef != NULL)
    {
        self.moviePlayerPreviewImageView.image = [UIImage imageWithCGImage:frameImageRef scale:1.0 orientation:UIImageOrientationUp];
        CGImageRelease(frameImageRef);
    }
    // End synchronous preview generation
    
    if (animated)
    {
        self.moviePlayerContainer.alpha = 0.0f;
        self.moviePlayerContainer.hidden = NO;
        self.moviePlayerPreviewImageView.alpha = 0.0f;

        [UIView animateWithDuration:kAnimationFadeSpeed animations:^{
            self.previewThumbnailImageView.alpha = 0.0f;
            self.moviePlayerContainer.alpha = 1.0f;
            self.moviePlayerPreviewImageView.alpha = 1.0f;
        }];
    }
    else
    {
        self.previewThumbnailImageView.alpha = 0.0f;
        self.moviePlayerContainer.hidden = NO;
        self.moviePlayerContainer.alpha = 1.0f;
    }
}

- (void)destroyMediaPlayerAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:kAnimationFadeSpeed animations:^{
            self.moviePlayerContainer.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.moviePlayerContainer.hidden = YES;
            self.moviePlayerPreviewImageView.image = nil;
            self.playerViewController = nil;
        }];
    }
    else
    {
        self.moviePlayerContainer.alpha = 0.0f;
        self.moviePlayerPreviewImageView.image = nil;
        self.playerViewController = nil;
        self.moviePlayerContainer.hidden = YES;
    }
}

- (void)requestThumbnailForDocument:(AlfrescoDocument *)document completionBlock:(ImageCompletionBlock)completionBlock
{
    [[ThumbnailManager sharedManager] retrieveImageForDocument:self.document renditionType:kRenditionImageImagePreview session:self.session completionBlock:^(UIImage *image, NSError *error) {
        if (completionBlock != NULL)
        {
            completionBlock(image, error);
        }
    }];
}

- (void)showProgressViewAnimated:(BOOL)animated
{
    if (animated)
    {
        [self.downloadProgressContainer layoutIfNeeded];
        [UIView animateWithDuration:kAnimationFadeSpeed delay:kAnimationDelayTime options:0 animations:^{
            self.heightForDownloadContainer.constant = sDownloadProgressHeight;
            self.centerYAlignmentForProgressContainer.constant = (self.previewThumbnailImageView.image.size.height / 2) + kPlaceholderToProcessVerticalOffset;
            self.downloadProgressContainer.hidden = NO;
            [self.downloadProgressContainer layoutIfNeeded];
        } completion:nil];
    }
    else
    {
        self.heightForDownloadContainer.constant = sDownloadProgressHeight;
        self.centerYAlignmentForProgressContainer.constant = (self.previewThumbnailImageView.image.size.height / 2) + kPlaceholderToProcessVerticalOffset;
        self.downloadProgressContainer.hidden = NO;
        [self.downloadProgressContainer layoutIfNeeded];
    }
}

- (void)hideProgressViewAnimated:(BOOL)animated
{
    if (animated)
    {
        [self.downloadProgressContainer layoutIfNeeded];
        [UIView animateWithDuration:kAnimationFadeSpeed animations:^{
            self.heightForDownloadContainer.constant = 0;
            [self.downloadProgressContainer layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.downloadProgressContainer.hidden = YES;
        }];
    }
    else
    {
        self.heightForDownloadContainer.constant = 0;
        [self.downloadProgressContainer layoutIfNeeded];
        self.downloadProgressContainer.hidden = YES;
    }
}

- (void)displayFileAtPath:(NSString *)filePathToDisplay
{
    [self hideProgressViewAnimated:YES];
    
    if ([Utility isAudioOrVideo:filePathToDisplay])
    {
        [self createMediaPlayerForFilePath:filePathToDisplay animated:YES];
    }
    else
    {
        [self destroyPreviewerAnimated:NO];
        [self createPreviewerForFilePath:filePathToDisplay animated:YES];
    }
}

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
}

- (void)setAccessibilityIdentifiers
{
    self.view.accessibilityIdentifier = kFilePreviewVCViewIdentifier;
}

#pragma mark - DocumentPreviewManager Notification Callbacks

- (void)downloadStarting:(NSNotification *)notification
{
    NSString *displayedDocumentIdentifier = [[DocumentPreviewManager sharedManager] documentIdentifierForDocument:self.document];
    NSString *notificationDocumentIdentifier = notification.userInfo[kDocumentPreviewManagerDocumentIdentifierNotificationKey];
    
    if ([displayedDocumentIdentifier isEqualToString:notificationDocumentIdentifier])
    {
        self.previewThumbnailImageView.alpha = 1.0f;
        [self showProgressViewAnimated:YES];
    }
}

- (void)downloadProgress:(NSNotification *)notification
{
    NSString *displayedDocumentIdentifier = [[DocumentPreviewManager sharedManager] documentIdentifierForDocument:self.document];
    NSString *notificationDocumentIdentifier = notification.userInfo[kDocumentPreviewManagerDocumentIdentifierNotificationKey];
    
    if ([displayedDocumentIdentifier isEqualToString:notificationDocumentIdentifier])
    {
        if (self.downloadProgressContainer.hidden)
        {
            [self showProgressViewAnimated:YES];
        }
        
        unsigned long long bytesTransferred = [notification.userInfo[kDocumentPreviewManagerProgressBytesRecievedNotificationKey] unsignedLongLongValue];
        unsigned long long bytesTotal = [notification.userInfo[kDocumentPreviewManagerProgressBytesTotalNotificationKey] unsignedLongLongValue];
        
        [self.downloadProgressView setProgress:(float)bytesTransferred/(float)bytesTotal];
    }
}

- (void)downloadComplete:(NSNotification *)notification
{
    NSString *displayedDocumentIdentifier = [[DocumentPreviewManager sharedManager] documentIdentifierForDocument:self.document];
    NSString *notificationDocumentIdentifier = notification.userInfo[kDocumentPreviewManagerDocumentIdentifierNotificationKey];
    
    if ([displayedDocumentIdentifier isEqualToString:notificationDocumentIdentifier])
    {
        [self hideProgressViewAnimated:YES];
        [self displayFileAtPath:[[DocumentPreviewManager sharedManager] filePathForDocument:self.document]];
    }
}

- (void)fileLocallyUpdated:(NSNotification *)notification
{
    NSString *nodeRefUpdated = notification.object;
    
    if ([nodeRefUpdated isEqualToString:self.document.identifier] || self.document == nil)
    {
        [self.previewController.previewController reloadData];
    }
}

#pragma mark - Document Editing Notification

- (void)editingDocumentCompleted:(NSNotification *)notification
{
    self.document = notification.object;
    
    if ([self.document isNodeInSyncList])
    {
        NSString *contentPath = [[RealmSyncCore sharedSyncCore] contentPathForNode:self.document forAccountIdentifier:[AccountManager sharedManager].selectedAccount.accountIdentifier];;
        BOOL isDirectory = NO;
        if (![[AlfrescoFileManager sharedManager] fileExistsAtPath:contentPath isDirectory:&isDirectory])
        {
            contentPath = nil;
        }
        
        self.filePathForFileToLoad = contentPath;
    }
    
    [self refreshViewController];
}

#pragma mark - UIViewControllerAnimatedTransitioning Functions

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    self.animationController.isGoingIntoFullscreenMode = YES;
    return self.animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.animationController.isGoingIntoFullscreenMode = NO;
    return self.animationController;
}

#pragma mark - NodeUpdatableProtocol Functions

- (void)updateToAlfrescoDocument:(AlfrescoDocument *)node permissions:(AlfrescoPermissions *)permissions contentFilePath:(NSString *)contentFilePath documentLocation:(InAppDocumentLocation)documentLocation session:(id<AlfrescoSession>)session
{
    self.document = (AlfrescoDocument *)node;
    self.filePathForFileToLoad = contentFilePath;
    self.session = session;
    
    [self destroyPreviewerAnimated:NO];
    [self destroyMediaPlayerAnimated:NO];
    [self showProgressViewAnimated:YES];
    
    [self refreshViewController];
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return self.filePathForFileToLoad ? 1 : 0;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    return [NSURL fileURLWithPath:self.filePathForFileToLoad];
}

#pragma mark - ALFPreviewControllerDelegate

- (void)previewControllerWasTapped:(ALFPreviewController *)controller
{
    if(self.presentingViewController)
    {
        [self dismiss:nil];
    }
    else
    {
        FilePreviewViewController *presentationViewController = nil;
        if ([self.document isNodeInSyncList])
        {
            NSString *filePath = [[RealmSyncCore sharedSyncCore] contentPathForNode:self.document forAccountIdentifier:[AccountManager sharedManager].selectedAccount.accountIdentifier];;
            presentationViewController = [[FilePreviewViewController alloc] initWithFilePath:filePath document:self.document];
        }
        else
        {
            if (self.document)
            {
                presentationViewController = [[FilePreviewViewController alloc] initWithDocument:self.document session:self.session];
            }
            else
            {
                presentationViewController = [[FilePreviewViewController alloc] initWithFilePath:self.filePathForFileToLoad document:nil];
            }
        }
        
        presentationViewController.fullScreenMode = YES;
        NavigationViewController *navigationPresentationViewController = [[NavigationViewController alloc] initWithRootViewController:presentationViewController];
        
        navigationPresentationViewController.transitioningDelegate  = self;
        navigationPresentationViewController.modalPresentationStyle = UIModalPresentationCustom;
        navigationPresentationViewController.modalPresentationCapturesStatusBarAppearance = YES;
        [navigationPresentationViewController setNavigationBarHidden:YES];
        
        [self presentViewController:navigationPresentationViewController animated:YES completion:^{
            [presentationViewController.previewController hideButton:NO];
        }];
        
        NSString *mimeType = nil;
        
        if (self.document)
        {
            mimeType = self.document.contentMimeType;
        }
        else if (self.filePathForFileToLoad)
        {
            mimeType = [Utility mimeTypeForFileExtension:self.filePathForFileToLoad.pathExtension];
        }

        [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                          action:kAnalyticsEventActionFullScreenView
                                                           label:mimeType
                                                           value:@1];
    }
}

@end

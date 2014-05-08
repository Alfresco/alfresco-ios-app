//
//  FilePreviewViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 03/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "FilePreviewViewController.h"
#import "ThumbnailImageView.h"
#import "ThumbnailManager.h"
#import "Utility.h"
#import "ErrorDescriptions.h"
#import <MediaPlayer/MediaPlayer.h>
#import "NavigationViewController.h"
#import "DocumentPreviewManager.h"

#import "FullScreenAnimationController.h"

static CGFloat const kAnimationSpeed = 0.2f;
static CGFloat const kAnimationFadeSpeed = 0.5f;
static CGFloat downloadProgressHeight;

@interface FilePreviewViewController () <UIWebViewDelegate, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate>

// Constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightForDownloadContainer;

// Data Models
@property (nonatomic, strong) AlfrescoDocument *document;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, weak) AlfrescoRequest *downloadRequest;
@property (nonatomic, strong) MPMoviePlayerController *mediaPlayerController;
@property (nonatomic, strong) FullScreenAnimationController *animationController;
// Used for the file path initialiser
@property (nonatomic, assign) BOOL shouldLoadFromFileAndRunCompletionBlock;
@property (nonatomic, strong) NSString *filePathForFileToLoad;
@property (nonatomic, copy) void (^loadingCompleteBlock)(UIWebView *webView, BOOL loadedIntoWebView);

// IBOutlets
@property (nonatomic, weak) IBOutlet ThumbnailImageView *previewThumbnailImageView;
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIProgressView *downloadProgressView;
@property (nonatomic, weak) IBOutlet UIView *downloadProgressContainer;
@property (nonatomic, weak) IBOutlet UIView *moviePlayerContainer;

@end

@implementation FilePreviewViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDocumentCompleted:) name:kAlfrescoDocumentEditedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarting:) name:kDocumentPreviewManagerWillStartDownloadNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgress:) name:kDocumentPreviewManagerProgressNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete:) name:kDocumentPreviewManagerDocumentDownloadCompletedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileLocallyUpdated:) name:kAlfrescoSaveBackLocalComplete object:nil];
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
        self.animationController = [[FullScreenAnimationController alloc] init];
    }
    return self;
}

- (instancetype)initWithFilePath:(NSString *)filePath document:(AlfrescoDocument *)document loadingCompletionBlock:(void (^)(UIWebView *, BOOL))loadingCompleteBlock
{
    self = [self init];
    if (self)
    {
        self.shouldLoadFromFileAndRunCompletionBlock = YES;
        self.filePathForFileToLoad = filePath;
        self.document = document;
        self.animationController = [[FullScreenAnimationController alloc] init];
        self.loadingCompleteBlock = loadingCompleteBlock;
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
    
    [self configureWebView];
    [self configureMediaPlayer];
    
    downloadProgressHeight = self.heightForDownloadContainer.constant;
    self.downloadProgressView.progress = 0.0f;
    [self hideProgressViewAnimated:NO];
    
    if (self.shouldLoadFromFileAndRunCompletionBlock)
    {
        [self displayFileAtPath:self.filePathForFileToLoad];
    }
    else
    {
        if ([[DocumentPreviewManager sharedManager] hasLocalContentOfDocument:self.document])
        {
            NSString *filePathToLoad = [[DocumentPreviewManager sharedManager] filePathForDocument:self.document];
            [self displayFileAtPath:filePathToLoad];
        }
        else
        {
            // Try and obtain the document thumbnail from the cache
            UIImage *placeholderImage = [[ThumbnailManager sharedManager] thumbnailForDocument:self.document renditionType:kRenditionImageImagePreview];;
            
            __weak typeof(self) weakSelf = self;
            if (!placeholderImage)
            {
                // set a placeholder image
                placeholderImage = largeImageForType(self.document.name.pathExtension);
                [self.previewThumbnailImageView setImage:placeholderImage withFade:NO];
                
                // request thumbnail
                [self requestThumbnailForDocument:self.document completionBlock:^(UIImage *image, NSError *error) {
                    // update the image with a fade
                    [weakSelf.previewThumbnailImageView setImage:image withFade:YES];
                    
                    // request the document download
                    weakSelf.downloadRequest = [[DocumentPreviewManager sharedManager] downloadDocument:self.document session:self.session];
                }];
            }
            else
            {
                [self.previewThumbnailImageView setImage:placeholderImage withFade:NO];
                
                // request the document download
                self.downloadRequest = [[DocumentPreviewManager sharedManager] downloadDocument:self.document session:self.session];
            }
        }
    }
}

#pragma mark - IBOutlets

- (IBAction)didPressCancelDownload:(id)sender
{
    [self.downloadRequest cancel];
    [self hideProgressViewAnimated:YES];
    self.downloadProgressView.progress = 0.0f;
}

#pragma mark - Private Functions

- (void)configureWebView
{
    self.webView.scalesPageToFit = YES;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor whiteColor];
    
    // Tap gestures
    // Single
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    singleTap.delegate = self;
    [self.webView addGestureRecognizer:singleTap];
    // Double
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.numberOfTouchesRequired = 1;
    doubleTap.delegate = self;
    [self.webView addGestureRecognizer:doubleTap];
}

- (void)configureMediaPlayer
{
    MPMoviePlayerController *mediaPlayer = [[MPMoviePlayerController alloc] init];
    mediaPlayer.view.translatesAutoresizingMaskIntoConstraints = NO;
    mediaPlayer.view.backgroundColor = [UIColor clearColor];
    mediaPlayer.controlStyle = MPMovieControlStyleDefault;
    mediaPlayer.allowsAirPlay = YES;
    mediaPlayer.shouldAutoplay = NO;
    [mediaPlayer prepareToPlay];
    [self.moviePlayerContainer addSubview:mediaPlayer.view];
    
    // constraints
    NSDictionary *views = @{@"moviePlayerView" : mediaPlayer.view};
    [self.moviePlayerContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[moviePlayerView]|"
                                                                                      options:NSLayoutFormatAlignAllBaseline
                                                                                      metrics:nil
                                                                                        views:views]];
    [self.moviePlayerContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[moviePlayerView]|"
                                                                                      options:NSLayoutFormatAlignAllCenterX
                                                                                      metrics:nil
                                                                                        views:views]];
    self.mediaPlayerController = mediaPlayer;
}

- (void)handleSingleTap:(UIGestureRecognizer *)gesture
{
    if (self.presentingViewController)
    {
        if (self.navigationController.navigationBarHidden)
        {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        }
        else
        {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
    }
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gesture
{
    if (!self.presentingViewController)
    {
        FilePreviewViewController *presentationViewController = nil;
        
        if (!self.shouldLoadFromFileAndRunCompletionBlock)
        {
            presentationViewController = [[FilePreviewViewController alloc] initWithDocument:self.document session:self.session];
        }
        else
        {
            presentationViewController = [[FilePreviewViewController alloc] initWithFilePath:self.filePathForFileToLoad document:nil loadingCompletionBlock:nil];
        }
        
        NavigationViewController *navigationPresentationViewController = [[NavigationViewController alloc] initWithRootViewController:presentationViewController];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done")
                                                                       style:UIBarButtonItemStyleDone
                                                                      target:self
                                                                      action:@selector(dismiss:)];
        [presentationViewController.navigationItem setRightBarButtonItem:doneButton];
        presentationViewController.title = (self.document) ? self.document.name : self.filePathForFileToLoad.lastPathComponent;
        
        navigationPresentationViewController.transitioningDelegate  = self;
        navigationPresentationViewController.modalPresentationStyle = UIModalPresentationCustom;
        
        [self presentViewController:navigationPresentationViewController animated:YES completion:^{
            [presentationViewController.navigationController setNavigationBarHidden:YES animated:YES];
        }];
    }
}

- (void)dismiss:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showWebViewAnimated:(BOOL)animated
{
    if (animated)
    {
        self.webView.alpha = 0.0f;
        self.webView.hidden = NO;
        [UIView animateWithDuration:kAnimationFadeSpeed animations:^{
            self.previewThumbnailImageView.alpha = 0.0f;
            self.webView.alpha = 1.0f;
        }];
    }
    else
    {
        self.webView.hidden = NO;
    }
}

- (void)showMediaPlayerAnimated:(BOOL)animated
{
    if (animated)
    {
        self.moviePlayerContainer.alpha = 0.0f;
        self.moviePlayerContainer.hidden = NO;
        [UIView animateWithDuration:kAnimationFadeSpeed animations:^{
            self.previewThumbnailImageView.alpha = 0.0f;
            self.moviePlayerContainer.alpha = 1.0f;
        }];
    }
    else
    {
        self.moviePlayerContainer.hidden = NO;
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
        [UIView animateWithDuration:kAnimationSpeed delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.heightForDownloadContainer.constant = downloadProgressHeight;
            [self.downloadProgressContainer layoutIfNeeded];
        } completion:nil];
    }
    else
    {
        self.heightForDownloadContainer.constant = downloadProgressHeight;
    }
    self.downloadProgressContainer.hidden = NO;
}

- (void)hideProgressViewAnimated:(BOOL)animated
{
    if (animated)
    {
        [self.downloadProgressContainer layoutIfNeeded];
        [UIView animateWithDuration:kAnimationSpeed delay:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.heightForDownloadContainer.constant = 0;
            [self.downloadProgressContainer layoutIfNeeded];
        } completion:nil];
    }
    else
    {
        self.heightForDownloadContainer.constant = 0;
    }
    self.downloadProgressContainer.hidden = YES;
}

- (void)displayFileAtPath:(NSString *)filePathToDisplay
{
    if ([Utility isAudioOrVideo:filePathToDisplay])
    {
        self.mediaPlayerController.contentURL = [NSURL fileURLWithPath:filePathToDisplay];
        
        [self.mediaPlayerController prepareToPlay];
        
        [self showMediaPlayerAnimated:YES];
        
        [self hideProgressViewAnimated:YES];
    }
    else
    {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePathToDisplay]]];
    }
}

#pragma mark - DocumentPreviewManager Notification Callbacks

- (void)downloadStarting:(NSNotification *)notification
{
    NSString *displayedDocumentIdentifier = [[DocumentPreviewManager sharedManager] documentIdentifierForDocument:self.document];
    NSString *notificationDocumentIdentifier = notification.userInfo[kDocumentPreviewManagerDocumentIdentifierNotificationKey];
    
    if ([displayedDocumentIdentifier isEqualToString:notificationDocumentIdentifier])
    {
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
        [self displayFileAtPath:[[DocumentPreviewManager sharedManager] filePathForDocument:self.document]];
    }
}

- (void)fileLocallyUpdated:(NSNotification *)notification
{
    NSString *nodeRefUpdated = notification.object;
    
    if ([nodeRefUpdated isEqualToString:self.document.identifier] || self.document == nil)
    {
        [self.webView reload];
    }
}

#pragma mark - Document Editing Notification

- (void)editingDocumentCompleted:(NSNotification *)notification
{
    [self.webView reload];
}

#pragma mark - UIWebViewDelegate Functions

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self showWebViewAnimated:YES];
    [self hideProgressViewAnimated:YES];
    
    if (self.shouldLoadFromFileAndRunCompletionBlock && self.loadingCompleteBlock != NULL)
    {
        self.loadingCompleteBlock(webView, YES);
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (self.shouldLoadFromFileAndRunCompletionBlock && self.loadingCompleteBlock != NULL)
    {
        self.loadingCompleteBlock(nil, NO);
    }
}

#pragma mark - UIGestureRecognizerDelegate Functions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
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

@end

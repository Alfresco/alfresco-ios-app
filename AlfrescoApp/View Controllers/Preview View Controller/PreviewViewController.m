//
//  PreviewViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "PreviewViewController.h"
#import "DownloadManager.h"
#import "AlfrescoDocument+ALF.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CommentViewController.h"
#import "Utility.h"
#import <MediaPlayer/MediaPlayer.h>
#import "DocumentOverlayView.h"

static CGFloat const kToolbarButtonPadding = 5.0f;
static NSUInteger const kRandomStringLength = 32;
static CGFloat const kAnimationSpeed = 0.3f;

typedef NS_ENUM(NSUInteger, PreviewStateType)
{
    PreviewStateTypeNone,
    PreviewStateTypeDocument,
    PreviewStateTypeAudioVideoEnabled,
    PreviewStateTypeAudioVideoDisabled
};

@interface PreviewViewController () <UIGestureRecognizerDelegate, DocumentOverlayDelegate>

@property (nonatomic, strong, readwrite) AlfrescoDocument *document;
@property (nonatomic, strong) AlfrescoPermissions *permissions;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSString *contentFilePath;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UILabel *videoSupportedLabel;
@property (nonatomic, strong) NSURL *documentUrl;
@property (nonatomic, assign) BOOL shouldDisplayActions;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIImageView *alfrescoLogoImageView;
@property (nonatomic, strong) UIDocumentInteractionController *documentInterationController;
@property (nonatomic, strong) NSString *randomTemporaryFileName;
@property (nonatomic, strong) MPMoviePlayerViewController *moviePlayerViewController;
@property (nonatomic, weak) DocumentOverlayView *overlayView;
@property (nonatomic, assign) BOOL displayOverlayCloseButton;
@property (nonatomic, assign) BOOL fullScreenMode;

@end

@implementation PreviewViewController

- (id)initWithDocument:(AlfrescoDocument *)document documentPermissions:(AlfrescoPermissions *)permissions contentFilePath:(NSString *)contentFilePath session:(id<AlfrescoSession>)session displayOverlayCloseButton:(BOOL)displaycloseButton
{
    self = [super init];
    if (self)
    {
        self.document = document;
        self.permissions = permissions;
        self.session = session;
        self.contentFilePath = contentFilePath;
        self.documentUrl = [NSURL fileURLWithPath:self.contentFilePath];
        self.shouldDisplayActions = (nil != document);
        self.displayOverlayCloseButton = displaycloseButton;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleUpdatedApplicationPolicyUpdated:)
                                                     name:kAlfrescoApplicationPolicyUpdatedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentUpdated:)
                                                     name:kAlfrescoDocumentUpdatedOnServerNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentUpdated:)
                                                     name:kAlfrescoDocumentUpdatedLocallyNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithBundleDocument:(NSString *)document
{
    self = [super init];
    if (self)
    {
        self.contentFilePath = [[NSBundle mainBundle] pathForResource:[document stringByDeletingPathExtension] ofType:[document pathExtension]];
        self.documentUrl = [NSURL fileURLWithPath:self.contentFilePath];
        self.shouldDisplayActions = NO;
    }
    return self;
}

- (void)loadView
{
    CGFloat logoWidthHeight = 300.0;
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = view.bounds;
    self.gradientLayer.colors = @[
                                  (id)[[UIColor whiteColor] CGColor],
                                  (id)[[UIColor colorWithWhite:0.9f alpha:1.0f] CGColor]
                                  ];
    [view.layer addSublayer:self.gradientLayer];
    
    UIImage *alfrescoLogo = [UIImage imageNamed:@"alfresco.png"];
    UIImageView *alfrescoLogoImageView = [[UIImageView alloc] initWithImage:alfrescoLogo];
    alfrescoLogoImageView.frame = CGRectMake(0, 0, logoWidthHeight, logoWidthHeight);
    alfrescoLogoImageView.contentMode = UIViewContentModeScaleAspectFit;
    alfrescoLogoImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    alfrescoLogoImageView.center = view.center;
    [view addSubview:alfrescoLogoImageView];
    self.alfrescoLogoImageView = alfrescoLogoImageView;
    
    CGFloat imageTextPadding = 20.0f; // space between logo and the text to be displayed
    CGFloat textLabelPadding = 40.0f;
    UILabel *videoPlaybackLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,
                                                                            view.frame.size.width - textLabelPadding,
                                                                            30.0f)];
    videoPlaybackLabel.center = CGPointMake(alfrescoLogoImageView.center.x,
                                            alfrescoLogoImageView.center.y + (logoWidthHeight/2) + imageTextPadding);
    videoPlaybackLabel.backgroundColor = [UIColor clearColor];
    videoPlaybackLabel.text = NSLocalizedString(@"document.video.not.supported", @"Video Not Supported");
    videoPlaybackLabel.minimumScaleFactor = 0.5f;
    videoPlaybackLabel.adjustsFontSizeToFitWidth = YES;
    videoPlaybackLabel.font = [UIFont boldSystemFontOfSize:22.0f];
    videoPlaybackLabel.textColor = [UIColor darkGrayColor];
    videoPlaybackLabel.textAlignment = NSTextAlignmentCenter;
    videoPlaybackLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    videoPlaybackLabel.hidden = YES;
    [view addSubview:videoPlaybackLabel];
    self.videoSupportedLabel = videoPlaybackLabel;
    
    UIWebView *webview = [[UIWebView alloc] initWithFrame:view.frame];
    webview.delegate = self;
    webview.scalesPageToFit = YES;
    webview.opaque = NO;
    webview.backgroundColor = [UIColor whiteColor];
    webview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [view addSubview:webview];
    self.webView = webview;
    
    // playbutton size
    CGFloat playButtonWidthHeight = 72.0f;
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton.frame = CGRectMake(0, 0, playButtonWidthHeight, playButtonWidthHeight);
    playButton.center = view.center;
    [playButton setImage:[UIImage imageNamed:@"play-media.png"] forState:UIControlStateNormal];
    [playButton addTarget:self action:@selector(playAudioOrVideo) forControlEvents:UIControlEventTouchUpInside];
    playButton.hidden = YES;
    playButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [view addSubview:playButton];
    self.playButton = playButton;
    
    // overlay
    // dont display expand button for audio
    BOOL displayExpandButton = ![Utility isAudioOrVideo:self.contentFilePath];
    DocumentOverlayView *overlay = [[DocumentOverlayView alloc] initWithFrame:view.frame delegate:self displayCloseButton:self.displayOverlayCloseButton displayExpandButton:displayExpandButton];
    [overlay show];
    self.overlayView = overlay;
    UITapGestureRecognizer *displayOverlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    displayOverlayTap.delegate = self;
    displayOverlayTap.numberOfTapsRequired = 1;
    displayOverlayTap.numberOfTouchesRequired = 1;
    
    // if viewing a document, add the tap to the webview, otherwise add it to the main view
    if ([Utility isAudioOrVideo:self.contentFilePath])
    {
        [view addSubview:overlay];
        [view addGestureRecognizer:displayOverlayTap];
    }
    else
    {
        [webview addSubview:overlay];
        [webview addGestureRecognizer:displayOverlayTap];
    }
    
    view.autoresizesSubviews = YES;
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view = view;
}

- (void)viewDidLayoutSubviews
{
    self.gradientLayer.frame = self.view.bounds;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if (!self.contentFilePath)
    {
        self.webView.hidden = YES;
        [self updatePreviewState:PreviewStateTypeNone];
    }
    else
    {
        // set title to the document being displayed
        self.title = self.document.name ? self.document.name : [self.contentFilePath lastPathComponent];
        
        if ([Utility isAudioOrVideo:self.contentFilePath])
        {
            // update the state
            [self updatePreviewState:PreviewStateTypeAudioVideoEnabled];
        }
        else
        {
            [self.webView loadRequest:[NSURLRequest requestWithURL:self.documentUrl]];
            
            // update state
            [self updatePreviewState:PreviewStateTypeDocument];
        }
    }
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.view.alpha = 0.0f;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:kAnimationSpeed animations:^{
        self.view.alpha = 1.0f;
    }];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (parent && [Utility isAudioOrVideo:self.contentFilePath])
    {
        [self playAudioOrVideo];
    }
}

#pragma mark - Private Functions

- (void)playAudioOrVideo
{
    NSURL *urlToFile = [NSURL fileURLWithPath:self.contentFilePath];
    MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:urlToFile];
    self.moviePlayerViewController = moviePlayer;
    [self presentMoviePlayerViewControllerAnimated:moviePlayer];
}

- (void)updatePreviewState:(PreviewStateType)previewType
{
    switch (previewType)
    {
        case PreviewStateTypeNone:
        {
            self.navigationItem.title = nil;
            
            self.document = nil;
            self.contentFilePath = nil;
            self.webView.hidden = YES;
            self.videoSupportedLabel.hidden = YES;
            self.playButton.hidden = YES;
            self.alfrescoLogoImageView.hidden = NO;
            
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
        break;
            
        case PreviewStateTypeDocument:
        {
            self.webView.hidden = NO;
            self.playButton.hidden = YES;
            self.videoSupportedLabel.hidden = YES;
            self.alfrescoLogoImageView.hidden = YES;
        }
        break;
            
        case PreviewStateTypeAudioVideoEnabled:
        {
            self.webView.hidden = YES;
            self.alfrescoLogoImageView.hidden = YES;
            self.videoSupportedLabel.hidden = YES;
            self.playButton.hidden = NO;
        }
        break;
            
        case PreviewStateTypeAudioVideoDisabled:
        {
            self.webView.hidden = YES;
            self.alfrescoLogoImageView.hidden = NO;
            self.videoSupportedLabel.hidden = NO;
            self.playButton.hidden = YES;
            self.shouldDisplayActions = NO;
        }
        break;
            
        default:
            break;
    }
}

- (void)displayDocumentInteractionController:(id)sender
{
    self.randomTemporaryFileName = [[Utility randomAlphaNumericStringOfLength:kRandomStringLength] stringByAppendingPathExtension:[self.documentUrl pathExtension]];
        
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:self.randomTemporaryFileName];
    BOOL fileCreatedSuccessfully = [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    
    if (!fileCreatedSuccessfully)
    {
        AlfrescoLogError(@"Error creating temporary empty file");
    }
    
    if (!self.documentInterationController)
    {
        self.documentInterationController = [[UIDocumentInteractionController alloc] init];
        self.documentInterationController.delegate = self;
    }
    
    self.documentInterationController.URL = [NSURL fileURLWithPath:filePath];
    
    CGRect senderFrame = [(UIButton *)sender frame];
    [self.documentInterationController presentOpenInMenuFromRect:senderFrame inView:self.navigationController.view animated:YES];
}

- (void)setRandomTemporaryFileName:(NSString *)randomTemporaryFileName
{
    // remove the old temp file before setting the new string
    [self removeTemporaryFileAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:self.randomTemporaryFileName]];
    
    _randomTemporaryFileName = randomTemporaryFileName;
}

- (void)removeTemporaryFileAtPath:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDirectory;
    BOOL fileExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    
    if (fileExists && !isDirectory)
    {
        NSError *deleteTempFileError = nil;
        [fileManager removeItemAtPath:filePath error:&deleteTempFileError];
        
        if (deleteTempFileError)
        {
            AlfrescoLogError(@"Error removing temporary empty file: %@, at path: %@", [deleteTempFileError localizedDescription], filePath);
        }
    }
}

- (void)documentUpdated:(NSNotification *)notification
{
    NSDictionary *updatedDocumentDetails = (NSDictionary *)notification.object;
    
    id documentNodeObject = [updatedDocumentDetails valueForKey:kAlfrescoDocumentUpdatedDocumentParameterKey];
    NSString *contentPath = [updatedDocumentDetails valueForKey:kAlfrescoDocumentUpdatedFilenameParameterKey];
    
    if ([self.contentFilePath isEqualToString:contentPath])
    {
        if ([documentNodeObject isKindOfClass:[AlfrescoDocument class]])
        {
            self.document = (AlfrescoDocument *)documentNodeObject;
        }
        [self.webView reload];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)tapGesture
{
    if (self.overlayView.isShowing)
    {
        [self.overlayView hide];
    }
    else
    {
        [self.overlayView show];
    }
}

#pragma mark - Public Functions

- (void)clearDisplayedDocument
{
    [self updatePreviewState:PreviewStateTypeNone];
}

#pragma mark - DocumentInDetailView Protocol functions

- (NSString *)detailViewItemIdentifier
{
    return (self.document) ? self.document.identifier : self.contentFilePath;
}

#pragma mark - UIDocumentInteractionControllerDelegate Functions

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    return self;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    // use the default file system
    controller.URL = [NSURL fileURLWithPath:self.contentFilePath];
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    [self removeTemporaryFileAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:self.randomTemporaryFileName]];
}

#pragma mark - UIGestureRecognizerDelegate Functions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - DocumentOverlayViewDelegate Functions

- (void)documentOverlay:(DocumentOverlayView *)documentOverlayView didPressExpandCollapseButton:(UIButton *)expandCollapseButton
{
    if (self.fullScreenMode)
    {
        CGRect convertedRect = [self.webView convertRect:self.webView.frame fromView:self.view];
        
        [UIView animateWithDuration:kAnimationSpeed animations:^{
            self.webView.frame = convertedRect;
        } completion:^(BOOL finished) {
            [self.view addSubview:self.webView];
            self.webView.frame = self.view.bounds;
            self.fullScreenMode = NO;
            [documentOverlayView toggleCloseButtonVisibility];
        }];
    }
    else
    {
        UIView *rootView =  [[[[[UIApplication sharedApplication] delegate] window] rootViewController] view];
        CGRect convertedRect = [self.view convertRect:self.view.bounds toView:rootView];
        self.webView.frame = convertedRect;
        [rootView addSubview:self.webView];
        
        [UIView animateWithDuration:kAnimationSpeed animations:^{
            self.webView.frame = rootView.bounds;
        } completion:^(BOOL finished) {
            [documentOverlayView hide];
            self.fullScreenMode = YES;
            [documentOverlayView toggleCloseButtonVisibility];
        }];
    }
}

- (void)documentOverlay:(DocumentOverlayView *)documentOverlayView didPressCloseDocumentButton:(UIButton *)closeButton
{
    [UIView animateWithDuration:kAnimationSpeed animations:^{
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}

@end

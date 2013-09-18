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

static CGFloat const kToolbarButtonPadding = 5.0f;
static NSUInteger const kRandomStringLength = 32;

typedef NS_ENUM(NSUInteger, PreviewStateType)
{
    PreviewStateTypeNone,
    PreviewStateTypeDocument,
    PreviewStateTypeAudioVideoEnabled,
    PreviewStateTypeAudioVideoDisabled
};

@interface PreviewViewController ()

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

@end

@implementation PreviewViewController

- (id)initWithDocument:(AlfrescoDocument *)document documentPermissions:(AlfrescoPermissions *)permissions contentFilePath:(NSString *)contentFilePath session:(id<AlfrescoSession>)session
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackDidFinish:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:nil];
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
    
    [self updateActionButtonsWithAnimation:NO];
	
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
            // play the video
            [self playAudioOrVideo];
                
            // update the state
            [self updatePreviewState:PreviewStateTypeAudioVideoEnabled];
        }
        else
        {
            // load the file
            [self.webView loadRequest:[NSURLRequest requestWithURL:self.documentUrl]];
            
            // update state
            [self updatePreviewState:PreviewStateTypeDocument];
        }
    }
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

#pragma mark - Private Functions

- (void)updateActionButtonsWithAnimation:(BOOL)animated
{
    // Navigation buttons populated in array order from right to left
    NSMutableArray *rightBarButtonItems = [NSMutableArray array];
    if (self.shouldDisplayActions && self.contentFilePath)
    {
        /**
         * Download button: Only if the current document is not flagged as downloaded
         */
        if (!self.document.isDownloaded)
        {
            [rightBarButtonItems addObject:[self barButtonItemFromImageNamed:@"download.png" action:@selector(saveToDownloads:)]];
        }
        
        /**
         * Comment button: Always show, as comments are serialised
         */
        [rightBarButtonItems addObject:[self barButtonItemFromImageNamed:@"comments.png" action:@selector(displayComments)]];
    }
    
    [rightBarButtonItems addObject:[self barButtonItemFromImageNamed:@"actionButton.png" action:@selector(displayDocumentInteractionController:)]];
    
    [self.navigationItem setRightBarButtonItems:rightBarButtonItems animated:animated];
}

- (void)playAudioOrVideo
{
    NSURL *urlToFile = [NSURL fileURLWithPath:self.contentFilePath];
    MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:urlToFile];
    self.moviePlayerViewController = moviePlayer;
    [self presentMoviePlayerViewControllerAnimated:moviePlayer];
}

- (void)playbackDidFinish:(NSNotification *)notification
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *downloadDestinationPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.contentFilePath lastPathComponent]];
    self.moviePlayerViewController = nil;
    
    if ([fileManager fileExistsAtPath:downloadDestinationPath])
    {
        NSError *removalError = nil;
        [fileManager removeItemAtPath:downloadDestinationPath error:&removalError];
        
        if (removalError)
        {
            AlfrescoLogError([removalError localizedDescription]);
        }
    }
}

- (void)saveToDownloads:(id)sender
{
    if (self.document)
    {
        [[DownloadManager sharedManager] downloadDocument:self.document contentPath:self.contentFilePath session:self.session];
    }
}

- (UIBarButtonItem *)barButtonItemFromImageNamed:(NSString *)imageName action:(SEL)action
{
    UIImage *image = [UIImage imageNamed:imageName];
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width + 2 * kToolbarButtonPadding, image.size.height);
    UIButton *customButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [customButton setImage:image forState:UIControlStateNormal];
    [customButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    customButton.showsTouchWhenHighlighted = YES;
    
    return [[UIBarButtonItem alloc] initWithCustomView:customButton];
}

- (void)displayComments
{
    CommentViewController *commentViewController = [[CommentViewController alloc] initWithAlfrescoNode:self.document permissions:self.permissions session:self.session];
    
    [self.navigationController pushViewController:commentViewController animated:YES];
}

- (void)removeActionButtons
{
    self.navigationItem.rightBarButtonItems = nil;
}

- (void)updatePreviewState:(PreviewStateType)previewType
{
    switch (previewType)
    {
        case PreviewStateTypeNone:
        {
            self.navigationItem.title = nil;
            [self removeActionButtons];
            
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

@end

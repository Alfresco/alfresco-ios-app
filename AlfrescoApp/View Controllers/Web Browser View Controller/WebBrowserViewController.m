//
//  HelpViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "WebBrowserViewController.h"
#import "ConnectivityManager.h"

static CGFloat const kSpacingBetweenButtons = 5.0f;

@interface WebBrowserViewController () <UIWebViewDelegate>

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *errorURL;
@property (nonatomic, strong) NSString *initalTitle;
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolBar;
@property (nonatomic, weak) UIBarButtonItem *backButton;
@property (nonatomic, weak) UIBarButtonItem *forwardButton;

@end

@implementation WebBrowserViewController

- (instancetype)initWithURLString:(NSString *)urlString initialTitle:(NSString *)initialTitle errorLoadingURLString:(NSString *)errorURLString
{
    return [self initWithURL:[NSURL URLWithString:urlString] initialTitle:initialTitle errorLoadingURL:[NSURL fileURLWithPath:errorURLString]];
}

- (instancetype)initWithURL:(NSURL *)url initialTitle:(NSString *)initialTitle errorLoadingURL:(NSURL *)errorURL
{
    self = [self init];
    if (self)
    {
        self.url = url;
        self.initalTitle = initialTitle;
        self.errorURL = errorURL;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ButtonBarArrowLeft.png"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    backButton.enabled = NO;
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = kSpacingBetweenButtons;
    UIBarButtonItem *forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ButtonBarArrowRight.png"] style:UIBarButtonItemStylePlain target:self action:@selector(forwardButtonPressed:)];
    forwardButton.enabled = NO;

    NSArray *webViewButtons = @[backButton, fixedSpace, forwardButton];
    
    self.title = self.initalTitle;
    
    if (self.toolBar)
    {
        self.toolBar.items = webViewButtons;
        
        self.backButton = self.toolBar.items[0];
        self.forwardButton = self.toolBar.items[2];
    }
    else
    {
        self.navigationItem.leftBarButtonItems = webViewButtons;
        
        self.backButton = self.navigationItem.leftBarButtonItems[0];
        self.forwardButton = self.navigationItem.leftBarButtonItems[2];
    }
    
    // dismiss button
//    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"green_selected_circle.png"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissHelp:)];
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(dismissHelp:)];
    self.navigationItem.rightBarButtonItem = closeButton;
    
    // make inital request
    [self makeInitialRequest];
}

#pragma mark - Private Functions

- (void)makeInitialRequest
{
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
        [self.webView loadRequest:request];
    }
    else
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:self.errorURL];
        [self.webView loadRequest:request];
    }
}

- (void)backButtonPressed:(UIBarButtonItem *)buttonItem
{
    [self.webView goBack];
}

- (void)forwardButtonPressed:(UIBarButtonItem *)buttonItem
{
    [self.webView goForward];
}

- (void)dismissHelp:(UIBarButtonItem *)buttonItem
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateButtons
{
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
}

#pragma mark - UIWebViewDelegate Functions

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.navigationItem.title = title;
    
    [self updateButtons];
}

@end

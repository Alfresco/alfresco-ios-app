/*******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile SDK.
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

#import "AlfrescoOAuthLoginViewController.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoErrors.h"
#import "AlfrescoOAuthHelper.h"
#import "AlfrescoLog.h"
#import <Availability.h>

static NSString * const kOAuthRequestDenyAction = @"action=Deny";

@interface AlfrescoOAuthLoginViewController ()
@property (nonatomic, strong, readwrite) NSURLConnection    * connection;
@property (nonatomic, strong, readwrite) NSMutableData      * receivedData;
@property (nonatomic, copy, readwrite) AlfrescoOAuthCompletionBlock completionBlock;
@property (nonatomic, strong, readwrite) AlfrescoOAuthData  * oauthData;
@property (nonatomic, strong, readwrite) NSString *baseURL;
@property (nonatomic, strong, readwrite) NSDictionary *parameters;
@property BOOL isLoginScreenLoad;
@property BOOL hasValidAuthenticationCode;
- (void)loadWebView;
- (NSString *)authorizationCodeFromURL:(NSURL *)url;
- (void)createActivityView;
- (void)reloadAndReset;
@end

@implementation AlfrescoOAuthLoginViewController


- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
     completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:apiKey argumentName:@"apiKey"];
    [AlfrescoErrors assertArgumentNotNil:secretKey argumentName:@"secretKey"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    return [self initWithAPIKey:apiKey
                      secretKey:secretKey
                    redirectURI:kAlfrescoCloudDefaultRedirectURI
                     parameters:nil
                completionBlock:completionBlock];
}

/**
 apiKey, secretKey and completionBlock are mandatory. redirectURI isn't. Hence we do the assertArgument check only on 3 parameters
 */
- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
         redirectURI:(NSString *)redirectURI
     completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:apiKey argumentName:@"apiKey"];
    [AlfrescoErrors assertArgumentNotNil:secretKey argumentName:@"secretKey"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    return [self initWithAPIKey:apiKey
                      secretKey:secretKey
                    redirectURI:redirectURI
                     parameters:nil
                completionBlock:completionBlock];
}

/**
 apiKey, secretKey and completionBlock are mandatory. parameters isn't. Hence we do the assertArgument check only on 3 parameters
 */
- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
          parameters:(NSDictionary *)parameters
     completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:apiKey argumentName:@"apiKey"];
    [AlfrescoErrors assertArgumentNotNil:secretKey argumentName:@"secretKey"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    return [self initWithAPIKey:apiKey
                      secretKey:secretKey
                    redirectURI:kAlfrescoCloudDefaultRedirectURI
                     parameters:parameters
                completionBlock:completionBlock];
}

/**
 apiKey, secretKey and completionBlock are mandatory. redirectURI and/or parameters aren't. Hence we do the assertArgument check only on 3 parameters
 */
- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
         redirectURI:(NSString *)redirectURI
          parameters:(NSDictionary *)parameters
     completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:apiKey argumentName:@"apiKey"];
    [AlfrescoErrors assertArgumentNotNil:secretKey argumentName:@"secretKey"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    self = [super init];
    if (nil != self)
    {
        [AlfrescoErrors assertStringArgumentNotNilOrEmpty:apiKey argumentName:@"apiKey"];
        [AlfrescoErrors assertStringArgumentNotNilOrEmpty:secretKey argumentName:@"secretKey"];
        //        [AlfrescoErrors assertStringArgumentNotNilOrEmpty:redirectURI argumentName:@"redirectURI"];
        [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
        
        self.oauthData = [[AlfrescoOAuthData alloc] initWithAPIKey:apiKey secretKey:secretKey redirectURI:redirectURI];
        self.completionBlock = completionBlock;
        self.baseURL = [NSString stringWithFormat:@"%@%@", kAlfrescoCloudURL, kAlfrescoOAuthAuthorize];
        if (nil != parameters)
        {
            self.parameters = parameters;
            if ([[parameters allKeys] containsObject:kAlfrescoSessionCloudURL])
            {
                NSString *supplementedURL = [parameters valueForKey:kAlfrescoSessionCloudURL];
                self.baseURL = [NSString stringWithFormat:@"%@%@",supplementedURL,kAlfrescoOAuthAuthorize];
            }
        }
        
        
    }
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    NSNotificationCenter *notificationCentre = [NSNotificationCenter defaultCenter];
    [notificationCentre addObserver:self selector:@selector(reloadAndReset) name:UIDeviceOrientationDidChangeNotification object:device];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isLoginScreenLoad = YES;
    [self loadWebView];
    [self createActivityView];
}

#ifdef __IPHONE_6_0
- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}
#endif


#if defined(__IPHONE_5_0) || defined (__IPHONE_5_1)
- (void)viewDidUnload
{
    self.oauthData = nil;
    self.connection = nil;
    self.receivedData = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}
#endif

- (void)viewWillDisappear:(BOOL)animated
{
    [self.activityIndicator stopAnimating];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    self.oauthData = nil;
    self.connection = nil;
    self.receivedData = nil;
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma private methods
- (void)loadWebView
{
    if (nil != self.webView)
    {
        self.webView = nil;
    }
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
        
    NSMutableString *authURLString = [NSMutableString string];
    [authURLString appendString:self.baseURL];
    [authURLString appendString:@"?"];
    [authURLString appendString:[kAlfrescoOAuthClientID stringByReplacingOccurrencesOfString:kAlfrescoClientID withString:self.oauthData.apiKey]];
    [authURLString appendString:@"&"];
    [authURLString appendString:[kAlfrescoOAuthRedirectURI stringByReplacingOccurrencesOfString:kAlfrescoRedirectURI withString:self.oauthData.redirectURI]];
    [authURLString appendString:@"&"];
    [authURLString appendString:kAlfrescoOAuthScope];
    [authURLString appendString:@"&"];
    [authURLString appendString:kAlfrescoOAuthResponseType];
    
    // load the authorization URL in the web view
    NSURL *authURL = [NSURL URLWithString:authURLString];
    AlfrescoLogDebug(@"UIWebviewDelegate loadWebView: just before loading request with %@",authURLString);
    [self.webView loadRequest:[NSURLRequest requestWithURL:authURL]];
}


- (NSString *)authorizationCodeFromURL:(NSURL *)url
{
    
    if (nil == url)
    {
        return nil;
    }
    
    NSArray *components = [[url absoluteString] componentsSeparatedByString:@"code="];
    if (2 == components.count)
    {
        self.receivedData = [NSMutableData data];
        NSString *codeString = [components objectAtIndex:1];
        NSArray *codeComponents = [codeString componentsSeparatedByString:@"&"];
        if (codeComponents.count > 0)
        {
            return [codeComponents objectAtIndex:0];
        }
        
    }
    return nil;
}


- (void)createActivityView
{
    CGSize size = self.view.bounds.size;
    CGFloat xOffset = size.width/2 - 50;
    CGFloat yOffset = size.height/2 - 50;
    CGRect viewFrame = CGRectMake(xOffset, yOffset, 100, 100);
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    self.activityIndicator.frame = viewFrame;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view insertSubview:self.activityIndicator aboveSubview:self.webView];
}

- (void)reloadAndReset
{
    if (nil != self.connection)
    {
        [self.connection cancel];
        self.connection = nil;
    }
    if ([self.activityIndicator isAnimating])
    {
        [self.activityIndicator stopAnimating];
    }
    [self.activityIndicator removeFromSuperview];
    self.activityIndicator = nil;

    self.isLoginScreenLoad = YES;
}

#pragma WebViewDelegate methods

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    
    if (self.webView.loading)
    {
        [self.webView stopLoading];
    }
    
    if (self.isLoginScreenLoad)
    {
        self.isLoginScreenLoad = NO;
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    switch (navigationType)
    {
        case UIWebViewNavigationTypeFormSubmitted:
            self.isLoginScreenLoad = NO;
            break;
        case UIWebViewNavigationTypeFormResubmitted:
            self.isLoginScreenLoad = NO;
            break;
            
        default:
            break;
    }
    
    if (!self.isLoginScreenLoad)
    {
        NSArray *requestComponents = [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"&"];
        
        if ([requestComponents containsObject:kOAuthRequestDenyAction])
        {
            if ([self.oauthDelegate respondsToSelector:@selector(oauthLoginDidCancel)])
            {
                [self.oauthDelegate oauthLoginDidCancel];
            }
            else if ([self.oauthDelegate respondsToSelector:@selector(oauthLoginDidFailWithError:)])
            {
                NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeNetworkRequestCancelled];
                [self.oauthDelegate oauthLoginDidFailWithError:error];
            }
        }
        else
        {
            [self.activityIndicator startAnimating];
            self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        }
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    AlfrescoLogDebug(@"UIWebviewDelegate webViewDidStartLoad");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    AlfrescoLogError(@"UIWebviewDelegate didFailLoadWithError");
    AlfrescoLogError(@"Error occurred while loading page: %@ with code %d and reason %@", [error localizedDescription], [error code], [error localizedFailureReason]);
    if (nil != self.oauthDelegate)
    {
        if ([self.oauthDelegate respondsToSelector:@selector(oauthLoginDidFailWithError:)])
        {
            [self.oauthDelegate oauthLoginDidFailWithError:error];
        }
    }
    else
    {
        [self reloadAndReset];        
    }
}

#pragma NSURLConnection Delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
}

/**
 this method is used for extracting the authentication code we receive back from the server when we
 first submit username/password
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    AlfrescoLogDebug(@"LoginViewController:didReceiveResponse");
    NSString *code = [self authorizationCodeFromURL:response.URL];
    AlfrescoLogDebug(@"Extracted auth code: %@", code);
    
    if (nil != code)
    {
        self.hasValidAuthenticationCode = YES;
        AlfrescoOAuthHelper *helper = nil;
        if (nil != self.parameters)
        {
            helper = [[AlfrescoOAuthHelper alloc] initWithParameters:self.parameters delegate:self.oauthDelegate];
        }
        else
        {
            helper = [[AlfrescoOAuthHelper alloc] initWithParameters:nil delegate:self.oauthDelegate];
        }
        [helper retrieveOAuthDataForAuthorizationCode:code oauthData:self.oauthData completionBlock:self.completionBlock];
    }
    else
    {
        AlfrescoLogDebug(@"We don't have a valid authentication code");
        [self.activityIndicator stopAnimating];
        self.hasValidAuthenticationCode = NO;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    AlfrescoLogDebug(@"LoginViewController:connection error with message %@ and code %d", [error localizedDescription], [error code]);
    [self.activityIndicator stopAnimating];
    if (nil != self.oauthDelegate)
    {
        if ([self.oauthDelegate respondsToSelector:@selector(oauthLoginDidFailWithError:)])
        {
            [self.oauthDelegate oauthLoginDidFailWithError:error];
        }
    }
    self.completionBlock(nil, error);
    [self reloadAndReset];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    AlfrescoLogDebug(@"LoginViewController:connectionDidFinishLoading");
    if (!self.hasValidAuthenticationCode)
    {
        NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeHTTPResponse];
        BOOL showAlert = NO;
        AlfrescoLogDebug(@"We don't have a valid authentication code");
        if (nil != self.oauthDelegate)
        {
            if ([self.oauthDelegate respondsToSelector:@selector(oauthLoginDidFailWithError:)])
            {
                [self.oauthDelegate oauthLoginDidFailWithError:error];
            }
            else
            {
                showAlert = YES;
            }
        }
        else
        {
            showAlert = YES;
        }
        if (showAlert)
        {
            UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not obtain authentication code from server. Possibly incorrect password/username" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alertview show];            
        }
        
    }
}

@end

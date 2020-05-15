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

#import "PrintingWebView.h"

@interface PrintingWebView () <WKNavigationDelegate>
@property (nonatomic, strong) UIView *owningView;
@property (nonatomic, copy) AlfrescoBOOLCompletionBlock completionBlock;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, assign) BOOL userCancelledLoading;
@end

@implementation PrintingWebView

- (id)initWithOwningView:(UIView *)view
{
    self = [super init];
    if (self)
    {
        self.owningView = view;
        self.navigationDelegate = self;
    }
    return self;
}

- (void)printFileURL:(NSURL *)fileURL completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    self.completionBlock = completionBlock;
    self.userCancelledLoading = NO;

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.owningView];
    hud.label.text = NSLocalizedString(@"action.print", @"Print");
    hud.detailsLabel.text = NSLocalizedString(@"login.hud.cancel.label", @"Tap To Cancel");
    hud.graceTime = 1.0;
    hud.mode = MBProgressHUDModeDeterminate;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleProgressTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [hud addGestureRecognizer:tap];

    [self.owningView addSubview:hud];
    [hud showAnimated:YES];
    self.hud = hud;

    self.progress = 0.0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerCallback) userInfo:nil repeats:YES];

    [self loadRequest:[NSURLRequest requestWithURL:fileURL]];
}

- (void)cleanup
{
    [self.timer invalidate];
    self.hud.progress = 1.0;
    [self.hud hideAnimated:YES];
}

#pragma mark - WKWebViewDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (!self.isLoading)
    {
        [self cleanup];
        if (self.completionBlock)
        {
            self.completionBlock(!self.userCancelledLoading, nil);
            self.completionBlock = nil;
        }
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    
}

-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self cleanup];
    
    if (self.completionBlock)
    {
        self.completionBlock(NO, self.userCancelledLoading ? nil : error);
        self.completionBlock = nil;
    }
}

#pragma mark - NSTimer

- (void)timerCallback
{
    self.progress = MIN(self.progress + 0.005, 0.95);
    self.hud.progress = self.progress;
}

#pragma mark - UIGestureRecognizer

- (void)handleProgressTap:(UIGestureRecognizer *)gesture
{
    self.userCancelledLoading = YES;
    [self stopLoading];
}

@end

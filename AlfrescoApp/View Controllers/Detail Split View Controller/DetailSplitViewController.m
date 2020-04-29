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
 
#import "DetailSplitViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AccountManager.h"
#import "UniversalDevice.h"

static const CGFloat kStatusBarHeight = 20.0f;
static const CGFloat kAnimationSpeed = 0.2f;

@interface DetailSplitViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIViewController *masterViewController;
@property (nonatomic, strong, readwrite) UIViewController *detailViewController;
@property (nonatomic, strong) UIView *masterViewContainer;
@property (nonatomic, strong) UIView *detailViewContainer;
@property (nonatomic, assign) BOOL isExpanded;

@end

@implementation DetailSplitViewController

- (instancetype)initWithMasterViewController:(UIViewController *)masterViewController detailViewController:(UIViewController *)detailViewController
{
    self = [super init];
    if (self)
    {
        self.masterViewController = masterViewController;
        self.detailViewController = detailViewController;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allAccountsRemoved:) name:kAlfrescoAccountsListEmptyNotification object:nil];
    }
    return self;
}

- (void)loadView
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIView *view = [[UIView alloc] initWithFrame:screenBounds];
    
    UIView *masterViewContainer = [[UIView alloc] initWithFrame:CGRectMake(screenBounds.origin.x,
                                                                           screenBounds.origin.y + kStatusBarHeight,
                                                                           kRevealControllerMasterViewWidth,
                                                                           screenBounds.size.height - kStatusBarHeight)];
    masterViewContainer.autoresizesSubviews = YES;
    masterViewContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [view addSubview:masterViewContainer];
    self.masterViewContainer = masterViewContainer;
    
    UIView *detailViewContainer = [[UIView alloc] initWithFrame:CGRectMake(screenBounds.origin.x,
                                                                           screenBounds.origin.y + kStatusBarHeight,
                                                                           screenBounds.size.width,
                                                                           screenBounds.size.height - kStatusBarHeight)];
    detailViewContainer.autoresizesSubviews = YES;
    detailViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    detailViewContainer.backgroundColor = [UIColor lightGrayColor];
    [view addSubview:detailViewContainer];
    self.detailViewContainer = detailViewContainer;
    
    [view bringSubviewToFront:detailViewContainer];
    view.backgroundColor = [UIColor lightGrayColor];
    
    view.autoresizesSubviews = YES;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.masterViewController)
    {
        self.masterViewController.view.frame = self.masterViewContainer.bounds;
        [self addChildViewController:self.masterViewController];
        [self.masterViewContainer addSubview:self.masterViewController.view];
        [self didMoveToParentViewController:self];
    }
    
    if (self.detailViewController)
    {
        self.detailViewController.view.frame = self.detailViewContainer.bounds;
        [self addChildViewController:self.detailViewController];
        [self.detailViewContainer addSubview:self.detailViewController.view];
        [self.detailViewController didMoveToParentViewController:self];
    }
    
    [self positionViewsWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
    
    [self addShadowToView:self.detailViewContainer];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self fixShadowHeightOfContainerViewForSize:size];
    
    // The device has already rotated, that's why this method is being called.
    UIInterfaceOrientation toOrientation   = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    
    // Fixes orientation mismatch (between UIDeviceOrientation and UIInterfaceOrientation)
    if (toOrientation == UIInterfaceOrientationLandscapeRight)
    {
        toOrientation = UIInterfaceOrientationLandscapeLeft;
    }
    else if (toOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        toOrientation = UIInterfaceOrientationLandscapeRight;
    }
    
    [self legacy_willRotateToInterfaceOrientation:toOrientation duration:0.0];
}

- (void)legacy_willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation) && self.isExpanded)
    {
        [self collapseViewController];
    }
    else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && !self.isExpanded)
    {
        [self expandViewController];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Functions

- (void)expandOrCollapse
{
    if (self.isExpanded)
    {
        [self collapseViewController];
    }
    else
    {
        [self expandViewController];
    }
}

- (void)expandViewController
{
    if (!self.isExpanded)
    {
        [UIView animateWithDuration:kAnimationSpeed animations:^{
            CGRect detailFrame = self.detailViewContainer.frame;
            detailFrame.origin.x = kRevealControllerMasterViewWidth;
            detailFrame.size.width = detailFrame.size.width - kRevealControllerMasterViewWidth;
            self.detailViewContainer.frame = detailFrame;
        } completion:^(BOOL finished) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoPagedScrollViewLayoutSubviewsNotification object:nil];
            self.isExpanded = YES;
        }];
    }
}

- (void)collapseViewController
{
    if (self.isExpanded)
    {
        [UIView animateWithDuration:kAnimationSpeed animations:^{
            CGRect detailFrame = self.detailViewContainer.frame;
            detailFrame.size.width = detailFrame.size.width + detailFrame.origin.x;
            detailFrame.origin.x = 0;
            self.detailViewContainer.frame = detailFrame;
        } completion:^(BOOL finished) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoPagedScrollViewLayoutSubviewsNotification object:nil];
            self.isExpanded = NO;
        }];
    }
}

#pragma mark - Private Functions

- (void)positionViewsWithOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        CGRect detailFrame = self.detailViewContainer.frame;
        detailFrame.origin.x = kRevealControllerMasterViewWidth;
        detailFrame.size.width -= kRevealControllerMasterViewWidth;
        self.detailViewContainer.frame = detailFrame;
        self.isExpanded = YES;
    }
    else
    {
        CGRect detailFrame = self.detailViewContainer.frame;
        detailFrame.origin.x = 0;
        self.detailViewContainer.frame = detailFrame;
        self.isExpanded = NO;
    }
}

- (UIBarButtonItem *)barButtonItemFromImageNamed:(NSString *)imageName action:(SEL)action
{
    UIImage *image = [UIImage imageNamed:imageName];
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width + 2, image.size.height);
    UIButton *customButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [customButton setImage:image forState:UIControlStateNormal];
    [customButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    customButton.showsTouchWhenHighlighted = YES;
    
    return [[UIBarButtonItem alloc] initWithCustomView:customButton];
}

- (void)addShadowToView:(UIView *)view
{
    CGPathRef path = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
    [view.layer setShadowPath:path];
    [view.layer setShadowColor:[UIColor grayColor].CGColor];
    [view.layer setShadowOpacity:0.5];
    [view.layer setShadowRadius:2.0];
    [view.layer setShadowOffset:CGSizeMake(-0.5, 0.0)];
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)accountRemoved:(NSNotification *)notification
{
    UserAccount *removedAccount = notification.object;
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    
    if ([removedAccount.accountIdentifier isEqualToString:selectedAccount.accountIdentifier])
    {
        [UniversalDevice clearDetailViewController];
    }
}

- (void)allAccountsRemoved:(NSNotification *)notification
{
    [UniversalDevice clearDetailViewController];
}

- (void)fixShadowHeightOfContainerViewForSize:(CGSize)size
{
    CGRect frame = self.detailViewContainer.layer.bounds;
    frame.size.height = size.height-20;
    
    CGPathRef path = [UIBezierPath bezierPathWithRect:frame].CGPath;
    [self.detailViewContainer.layer setShadowPath:path];
}

@end

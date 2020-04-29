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
 
#import "RootRevealViewController.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat kDeviceSpecificRevealWidth;
static const CGFloat kPadRevealWidth = 48.0f;
static const CGFloat kPhoneRevealWidth = 0.0f;
static const CGFloat kMasterViewWidth = 250.0f;
static const CGFloat kAnimationSpeed = 0.2f;

@interface RootRevealViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, assign, readwrite) BOOL hasOverlayController;
@property (nonatomic, strong) UIView *masterViewContainer;
@property (nonatomic, strong) UIView *detailViewContainer;
@property (nonatomic, assign, readwrite) BOOL isExpanded;

@property (nonatomic, assign) CGRect dragStartRect;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, assign) BOOL shouldExpandOrCollapse;

@property (nonatomic, strong, readwrite) UIViewController *overlayedViewController;

@end

@implementation RootRevealViewController

- (instancetype)initWithMasterViewController:(UIViewController *)masterViewController detailViewController:(UIViewController *)detailViewController
{
    self = [super init];
    if (self)
    {
        self.masterViewController = masterViewController;
        self.detailViewController = detailViewController;
        kDeviceSpecificRevealWidth = (IS_IPAD) ? kPadRevealWidth : kPhoneRevealWidth;
    }
    return self;
}

- (void)loadView
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIView *view = [[UIView alloc] initWithFrame:screenBounds];
    
    UIView *masterViewContainer = [[UIView alloc] initWithFrame:CGRectMake(screenBounds.origin.x,
                                                                           screenBounds.origin.y,
                                                                           kMasterViewWidth,
                                                                           screenBounds.size.height)];
    masterViewContainer.autoresizesSubviews = YES;
    masterViewContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [view addSubview:masterViewContainer];
    self.masterViewContainer = masterViewContainer;
    
    UIView *detailViewContainer = [[UIView alloc] initWithFrame:screenBounds];
    detailViewContainer.autoresizesSubviews = YES;
    detailViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    detailViewContainer.backgroundColor = [UIColor lightGrayColor];
    [view addSubview:detailViewContainer];
    self.detailViewContainer = detailViewContainer;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.delegate = self;
    self.tapGesture = tapGesture;
    [self.detailViewContainer addGestureRecognizer:tapGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    self.panGesture = panGesture;
    [view addGestureRecognizer:panGesture];
    
    [view bringSubviewToFront:detailViewContainer];
    view.backgroundColor = [UIColor lightGrayColor];
    
    view.autoresizesSubviews = YES;
    view.clipsToBounds = YES;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self positionViews];
    
    if (self.masterViewController)
    {
        self.masterViewController.view.frame = self.masterViewContainer.frame;
        [self addChildViewController:self.masterViewController];
        [self.masterViewContainer addSubview:self.masterViewController.view];
        [self.masterViewController didMoveToParentViewController:self];
    }
    
    if (self.detailViewController)
    {
        self.detailViewController.view.frame = self.detailViewContainer.bounds;
        [self addChildViewController:self.detailViewController];
        [self.detailViewContainer addSubview:self.detailViewController.view];
        [self.detailViewController didMoveToParentViewController:self];
    }
    
    [self addShadowToView:self.detailViewContainer];
}

#pragma mark - Custom Getters and Setters

- (BOOL)hasOverlayController
{
    return (self.overlayedViewController != nil);
}

#pragma mark - Public Functions

- (void)expandViewController
{
    if (!self.isExpanded)
    {
        if ([self.delegate respondsToSelector:@selector(controllerWillExpandToDisplayMasterViewController:)])
        {
            [self.delegate controllerWillExpandToDisplayMasterViewController:self];
        }
        [UIView animateWithDuration:kAnimationSpeed delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect detailFrame = self.detailViewContainer.frame;
            detailFrame.origin.x = kMasterViewWidth;
            self.detailViewContainer.frame = detailFrame;
        } completion:^(BOOL finished) {
            self.isExpanded = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoEnableMainMenuAutoItemSelection object:nil];
            self.detailViewController.view.userInteractionEnabled = NO;
            if ([self.delegate respondsToSelector:@selector(controllerDidExpandToDisplayMasterViewController:)])
            {
                [self.delegate controllerDidExpandToDisplayMasterViewController:self];
            }
        }];
    }
}

- (void)collapseViewController
{
    if (self.isExpanded)
    {
        if ([self.delegate respondsToSelector:@selector(controllerWillCollapseToHideMasterViewController:)])
        {
            [self.delegate controllerWillCollapseToHideMasterViewController:self];
        }
        [UIView animateWithDuration:kAnimationSpeed delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect detailFrame = self.detailViewContainer.frame;
            if (IS_IPAD)
            {
                detailFrame.origin.x = kDeviceSpecificRevealWidth;
            }
            else
            {
                detailFrame.origin.x = 0;
            }
            self.detailViewContainer.frame = detailFrame;
        } completion:^(BOOL finished) {
            self.isExpanded = NO;
            self.detailViewController.view.userInteractionEnabled = YES;
            if ([self.delegate respondsToSelector:@selector(controllerDidCollapseToHideMasterViewController:)])
            {
                [self.delegate controllerDidCollapseToHideMasterViewController:self];
            }
        }];
    }
}

- (void)addOverlayedViewController:(UIViewController *)overlayViewController
{
    overlayViewController.view.frame = self.view.frame;
    [self addChildViewController:overlayViewController];
    [self.view addSubview:overlayViewController.view];
    [overlayViewController didMoveToParentViewController:self];
    
    self.overlayedViewController = overlayViewController;
}

- (void)removeOverlayedViewControllerWithAnimation:(BOOL)animated
{
    void (^removeOverlayController)(void) = ^ {
        [self willMoveToParentViewController:nil];
        [self.overlayedViewController.view removeFromSuperview];
        [self.overlayedViewController removeFromParentViewController];
    };
    
    if (animated)
    {
        [UIView animateWithDuration:0.3f animations:^{
            self.overlayedViewController.view.alpha = 0.0f;
        } completion:^(BOOL finished) {
            removeOverlayController();
        }];
    }
    else
    {
        removeOverlayController();
    }
}

#pragma mark - Private Functions

- (void)positionViews
{
    if (IS_IPAD)
    {
        CGRect detailFrame = self.detailViewContainer.frame;
        detailFrame.origin.x = kDeviceSpecificRevealWidth;
        detailFrame.size.width -= kDeviceSpecificRevealWidth;
        self.detailViewContainer.frame = detailFrame;
    }
    else
    {
        CGRect detailFrame = self.detailViewContainer.frame;
        detailFrame.origin.x = 0;
        self.detailViewContainer.frame = detailFrame;
    }
    self.isExpanded = NO;
}

- (void)handlePan:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state == UIGestureRecognizerStateBegan)
    {
        self.dragStartRect = self.detailViewContainer.frame;
    }
    else if (panGesture.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [panGesture translationInView:self.view];
        
        if (translation.x > 0)
        {
            self.detailViewContainer.frame = CGRectMake(MIN(self.dragStartRect.origin.x + translation.x, kMasterViewWidth),
                                                            self.dragStartRect.origin.y,
                                                            self.detailViewContainer.frame.size.width,
                                                            self.detailViewContainer.frame.size.height);
            self.shouldExpandOrCollapse = translation.x > (kMasterViewWidth / 3);
        }
        else
        {
            self.detailViewContainer.frame = CGRectMake(MAX(self.dragStartRect.origin.x + translation.x, kDeviceSpecificRevealWidth),
                                                            self.dragStartRect.origin.y,
                                                            self.detailViewContainer.frame.size.width,
                                                            self.detailViewContainer.frame.size.height);
            self.shouldExpandOrCollapse = (translation.x * -1) > (kMasterViewWidth / 3);
        }
    }
    else if (panGesture.state == UIGestureRecognizerStateEnded)
    {
        if (self.shouldExpandOrCollapse)
        {
            if (!self.isExpanded)
            {
                [self expandViewController];
            }
            else if (self.isExpanded)
            {
                [self collapseViewController];
            }
        }
        else
        {
            [UIView animateWithDuration:kAnimationSpeed delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.detailViewContainer.frame = self.dragStartRect;
            } completion:^(BOOL finished) {}];
        }
    }
}

- (void)handleTap:(UITapGestureRecognizer *)tapGesture
{
    [self collapseViewController];
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

#pragma mark - UIPanGestureRecognizerDelegate Functions

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL shouldBegin = NO;
    if (gestureRecognizer == self.tapGesture)
    {
        if (self.isExpanded)
        {
            shouldBegin = YES;
        }
    }
    else if (gestureRecognizer == self.panGesture)
    {
        UIPanGestureRecognizer *localPanGesture = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint translation = [localPanGesture translationInView:[self.detailViewContainer superview]];
        if ((translation.x > 0 && !self.isExpanded) || (translation.x < 0 && self.isExpanded))
        {
            shouldBegin = YES;
        }
    }
    return shouldBegin;
}

@end

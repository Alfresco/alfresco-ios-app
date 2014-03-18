//
//  DetailSplitViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 01/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "DetailSplitViewController.h"
#import <QuartzCore/QuartzCore.h>

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
    }
    return self;
}

- (void)loadView
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIView *view = [[UIView alloc] initWithFrame:screenBounds];
    
    UIView *masterViewContainer = [[UIView alloc] initWithFrame:CGRectMake(screenBounds.origin.x,
                                                                           screenBounds.origin.y,
                                                                           kRevealControllerMasterViewWidth,
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
    
    [self positionViewsWithOrientation:self.interfaceOrientation];
    
    [self addShadowToView:self.detailViewContainer];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
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
            detailFrame.origin.x = 0;
            detailFrame.size.width = detailFrame.size.width + kRevealControllerMasterViewWidth;
            self.detailViewContainer.frame = detailFrame;
        } completion:^(BOOL finished) {
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

@end

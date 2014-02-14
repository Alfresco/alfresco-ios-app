//
//  ContainerViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 26/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ContainerViewController.h"
#import "UIColor+Custom.h"

static NSUInteger const kStatusBarViewHeight = 20.0f;
static CGFloat const kStatusBarTransparency = 0.9f;

@interface ContainerViewController ()

@property (nonatomic, weak, readwrite) UIView *statusBarBackgroundView;
@property (nonatomic, strong, readwrite) UIViewController *rootViewController;

@end

@implementation ContainerViewController

- (instancetype)initWithController:(UIViewController *)controller
{
    self = [super init];
    if (self)
    {
        self.rootViewController = controller;
    }
    return self;
}

- (void)loadView
{
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    UIView *view = [[UIView alloc] initWithFrame:screenFrame];
    
    // DECISION STILL TO BE MADE
//    UIView *statusBarBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenFrame.size.width, kStatusBarViewHeight)];
//    statusBarBackgroundView.backgroundColor = [UIColor whiteColor];
//    statusBarBackgroundView.alpha = kStatusBarTransparency;
//    statusBarBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//    
//    UIColor *startColour = [UIColor colorWithRed:0 green:0 blue:0 alpha:kStatusBarTransparency];
//    UIColor *endColour = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
//    
//    CAGradientLayer *gradiantLayer = [CAGradientLayer layer];
//    gradiantLayer.frame = statusBarBackgroundView.bounds;
//    gradiantLayer.colors = [NSArray arrayWithObjects: (id)startColour.CGColor, (id)endColour.CGColor, nil];
//    statusBarBackgroundView.layer.mask = gradiantLayer;
//    
//    [view addSubview:statusBarBackgroundView];
//    self.statusBarBackgroundView = statusBarBackgroundView;
    
    UIView *statusBarBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenFrame.size.width, kStatusBarViewHeight)];
    statusBarBackgroundView.backgroundColor = [UIColor mainMenuBackgroundColor];
    statusBarBackgroundView.alpha = kStatusBarTransparency;
    statusBarBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [view addSubview:statusBarBackgroundView];
    self.statusBarBackgroundView = statusBarBackgroundView;
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.rootViewController.view.frame = self.view.frame;
    [self addChildViewController:self.rootViewController];
    [self.view addSubview:self.rootViewController.view];
    [self.rootViewController didMoveToParentViewController:self];
    
    [self.view bringSubviewToFront:self.statusBarBackgroundView];
}

@end

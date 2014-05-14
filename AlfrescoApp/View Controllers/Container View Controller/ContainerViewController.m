//
//  ContainerViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 26/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ContainerViewController.h"
#import "FullScreenAnimationController.h"

static NSUInteger const kStatusBarViewHeight = 20.0f;

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
    
    UIView *statusBarBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenFrame.size.width, kStatusBarViewHeight)];
    statusBarBackgroundView.backgroundColor = [UIColor blackColor];
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

- (BOOL)prefersStatusBarHidden
{
    BOOL displayStatusBar = NO;
    
    UIViewController *presentedController = self.presentedViewController;
    if ([self.presentedViewController isKindOfClass:[UINavigationController class]])
    {
        presentedController = [[(UINavigationController *)presentedController viewControllers] lastObject];
    }
    
    if ([presentedController conformsToProtocol:@protocol(FullScreenAnimationControllerProtocol)])
    {
        UIViewController<FullScreenAnimationControllerProtocol> *controller = (UIViewController<FullScreenAnimationControllerProtocol> *)presentedController;
        if (controller.useControllersPreferStatusBarHidden)
        {
            displayStatusBar = controller.prefersStatusBarHidden;
        }
    }
    
    return displayStatusBar;
}

@end

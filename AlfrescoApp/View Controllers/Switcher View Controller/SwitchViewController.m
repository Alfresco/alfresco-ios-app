//
//  MainMenuViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SwitchViewController.h"
#import "RootRevealControllerViewController.h"
#import "UniversalDevice.h"

@interface SwitchViewController ()

@property (nonatomic, strong, readwrite) UIViewController *displayedViewController;

@end

@implementation SwitchViewController

- (instancetype)initWithInitialViewController:(UIViewController *)viewController
{
    self = [super init];
    if (self)
    {
        self.displayedViewController = viewController;
    }
    return self;
}

- (void)loadView
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIView *view = [[UIView alloc] initWithFrame:screenBounds];
    
    view.autoresizesSubviews = YES;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.displayedViewController)
    {
        [self displayViewController:self.displayedViewController];
    }
}

#pragma mark - Private Functions

- (void)displayViewController:(UIViewController *)controller
{
    if (self.displayedViewController)
    {
        [self.displayedViewController willMoveToParentViewController:nil];
        [self.displayedViewController.view removeFromSuperview];
        [self.displayedViewController removeFromParentViewController];
    }
    
    [self addChildViewController:controller];
    controller.view.frame = self.view.frame;
    [self.view addSubview:controller.view];
    [controller didMoveToParentViewController:self];
    
    self.displayedViewController = controller;
}

#pragma mark - MainMenuViewControllerDelegate Functions

- (void)didSelectMenuItem:(MainMenuItem *)mainMenuItem
{
    if (IS_IPAD && mainMenuItem.shouldDisplayInDetailView)
    {
        [UniversalDevice pushToDisplayViewController:mainMenuItem.viewController usingNavigationController:(UINavigationController *)self.displayedViewController animated:YES];
    }
    else
    {
        [self displayViewController:mainMenuItem.viewController];
    }
    RootRevealControllerViewController *rootViewController = (RootRevealControllerViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    [rootViewController collapseViewController];
}

@end

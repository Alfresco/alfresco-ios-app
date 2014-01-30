//
//  NavigationViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "NavigationViewController.h"

@interface NavigationViewController ()

@property (nonatomic, strong) UIBarButtonItem *expandButton;
@property (nonatomic, assign) BOOL viewShownBefore;

@end

@implementation NavigationViewController

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self)
    {
        _rootViewController = rootViewController;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationBar.translucent = NO;
    
    self.expandButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(expandOrCollapseDetailView:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // only do this the first time the navigation view is to be shown
    if (!self.viewShownBefore)
    {
        [self updateView];
        self.viewShownBefore = YES;
    }
}

- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}

- (BOOL)isDetailViewController
{
    if ([self.parentViewController isKindOfClass:[DetailSplitViewController class]])
    {
        DetailSplitViewController *splitViewController = (DetailSplitViewController *)self.parentViewController;
        UIViewController *detailViewController = splitViewController.detailViewController;
        return detailViewController == self;
    }
    return NO;
}

#pragma mark - Public Functions

- (void)resetRootViewControllerWithViewController:(UIViewController *)viewController
{
    self.rootViewController = viewController;
    self.viewControllers = @[viewController];
    [self updateView];
    [self dismissMasterPopoverIfVisible];
}

- (void)dismissMasterPopoverIfVisible
{
    if (self.masterPopoverController.popoverVisible)
    {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)expandOrCollapseDetailView:(id)sender
{
    [(DetailSplitViewController *)self.parentViewController expandOrCollapse];
}

- (void)updateView
{
    if ([self isDetailViewController])
    {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        {
            [self.rootViewController.navigationItem setLeftBarButtonItem:nil animated:YES];
        }
        else
        {
            [self.rootViewController.navigationItem setLeftBarButtonItem:self.expandButton animated:YES];
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self updateView];
}

#pragma mark - DetailSplitViewControllerDelegate

- (void)didPressExpandCollapseButton:(DetailSplitViewController *)detailSplitViewController button:(UIBarButtonItem *)button
{
    [detailSplitViewController expandOrCollapse];
}

@end

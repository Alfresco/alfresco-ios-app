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
@property (nonatomic, strong) UIBarButtonItem *showMasterButton;
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
    
    self.navigationBar.barStyle = UIBarStyleBlack;
    
    self.expandButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"expand.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(expandOrCollapseDetailView:)];
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
    if ([self.parentViewController isKindOfClass:[UISplitViewController class]])
    {
        UISplitViewController *splitViewController = (UISplitViewController *)self.parentViewController;
        UIViewController *detailViewController = [splitViewController.viewControllers objectAtIndex:1];
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
    UISplitViewController *splitViewController = (UISplitViewController *)[self parentViewController];
    
    UIViewController *masterViewController = [splitViewController.viewControllers objectAtIndex:0];
    UIViewController *detailViewController = [splitViewController.viewControllers objectAtIndex:1];
    
    float masterViewWidth = 320.0f;
    
    float delta = (self.isCurrentlyExpanded) ? -masterViewWidth : masterViewWidth;
    
    CGRect existingSplitFrame = splitViewController.view.frame;
    CGRect existingMasterFrame = masterViewController.view.frame;
    CGRect existingDetailFrame = detailViewController.view.frame;
    
    if (self.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
    {
        existingSplitFrame.origin.y -= delta;
    }
    
    existingSplitFrame.size.height += delta;
    existingMasterFrame.origin.x -= delta;
    existingDetailFrame.size.width += delta;
    
    [UIView animateWithDuration:0.3f animations:^{
        splitViewController.view.frame = existingSplitFrame;
        masterViewController.view.frame = existingMasterFrame;
        detailViewController.view.frame = existingDetailFrame;
    }
    completion:^(BOOL finished) {
        if (finished)
        {
            self.isCurrentlyExpanded = !self.isCurrentlyExpanded;
            // these should be images, using text for now
            self.expandButton.image = (self.isCurrentlyExpanded) ? [UIImage imageNamed:@"collapse.png"] : [UIImage imageNamed:@"expand.png"];;
        }
    }];
}

- (void)updateView
{
    if ([self isDetailViewController])
    {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        {
            [self.rootViewController.navigationItem setLeftBarButtonItem:self.expandButton animated:NO];
        }
        else
        {
            [self.rootViewController.navigationItem setLeftBarButtonItem:self.showMasterButton animated:NO];
        }
    }
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"splitviewcontroller.showmasterbutton", @"Show Master Button");
    [self.rootViewController.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
    self.showMasterButton = barButtonItem;
    self.isCurrentlyExpanded = NO;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.expandButton.image = [UIImage imageNamed:@"expand.png"];;
    [self.rootViewController.navigationItem setLeftBarButtonItem:self.expandButton animated:YES];
    self.masterPopoverController = nil;
    self.isCurrentlyExpanded = NO;
}

@end

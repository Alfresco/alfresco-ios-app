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
 
#import "NavigationViewController.h"
#import "UIBarButtonItem+MainMenu.h"

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
    
    self.expandButton = [UIBarButtonItem setupMainMenuButtonOnViewController:self withHandler:@selector(expandOrCollapseDetailView:)];
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
}

- (void)expandOrCollapseDetailView:(id)sender
{
    [(DetailSplitViewController *)self.parentViewController expandOrCollapse];
}

- (void)updateView
{
    if ([self isDetailViewController])
    {
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        {
            [self.rootViewController.navigationItem setLeftBarButtonItem:nil animated:YES];
        }
        else
        {
            [self.rootViewController.navigationItem setLeftBarButtonItem:self.expandButton animated:YES];
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateView];
    } completion:nil];
    [super viewWillTransitionToSize: size withTransitionCoordinator:coordinator];
}

#pragma mark - DetailSplitViewControllerDelegate

- (void)didPressExpandCollapseButton:(DetailSplitViewController *)detailSplitViewController button:(UIBarButtonItem *)button
{
    [detailSplitViewController expandOrCollapse];
}

@end

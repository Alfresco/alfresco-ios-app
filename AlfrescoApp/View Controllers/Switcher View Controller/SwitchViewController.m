/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
    RootRevealControllerViewController *rootViewController = (RootRevealControllerViewController *)[UniversalDevice revealViewController];
    [rootViewController collapseViewController];
}

- (UIViewController *)currentlyDisplayedController
{
    return self.displayedViewController;
}

@end

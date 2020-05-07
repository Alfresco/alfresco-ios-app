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
 
#import "SwitchViewController.h"
#import "RootRevealViewController.h"
#import "UniversalDevice.h"
#import "DismissCompletionProtocol.h"
#import "NavigationViewController.h"

@interface SwitchViewController ()
@property (nonatomic, strong, readwrite) UIViewController *displayedViewController;
@property (nonatomic, weak, readwrite) MainMenuItem *previouslySelectedItem;
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

#pragma mark - Public Functions
- (void)displayURLViewController:(UIViewController *)controller
{
    [self displayViewController:controller];
}

#pragma mark - Private Functions

- (void)displayViewController:(UIViewController *)controller
{
    // The controller is already added as a child and it's currrently displayed. No need to remove it and add it again.
    if ([self.childViewControllers containsObject:controller] && self.displayedViewController == controller)
    {
        return;
    }
    
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

- (void)mainMenuViewController:(MainMenuViewController *)controller didDeselectItem:(MainMenuItem *)menuItem inSectionItem:(MainMenuSection *)sectionItem
{
    if (menuItem.displayType != MainMenuDisplayTypeModal)
    {
        self.previouslySelectedItem = menuItem;
    }
}

- (void)mainMenuViewController:(MainMenuViewController *)controller didSelectItem:(MainMenuItem *)menuItem inSectionItem:(MainMenuSection *)sectionItem
{
    // Need to set a dismiss block to ensure the menu controller reselects the previous item that was selected
    id conformanceObject = nil;
    
    // If the associated object is a navigation controller, check the root view controller for conformance, else check the object itself
    if ([menuItem.associatedObject isKindOfClass:[NavigationViewController class]])
    {
        conformanceObject = ((NavigationViewController *)menuItem.associatedObject).rootViewController;
    }
    else if ([menuItem.associatedObject isKindOfClass:[UIViewController class]])
    {
        conformanceObject = menuItem.associatedObject;
    }
    
    // If the associated object conforms to this DismissCompletionProtocol, then set the block to reselect the previously selected item
    if ([conformanceObject conformsToProtocol:@protocol(DismissCompletionProtocol)])
    {
        id<DismissCompletionProtocol> dismissBlockConformingObject = conformanceObject;
        dismissBlockConformingObject.dismissCompletionBlock = ^{
            if (self.previouslySelectedItem)
            {
                [controller selectMenuItemWithIdentifier:self.previouslySelectedItem.itemIdentifier fallbackIdentifier:kAlfrescoMainMenuItemAccountsIdentifier];
            }
        };
    }
    
    // Continue with display the newly selected controller
    if (IS_IPAD && menuItem.displayType == MainMenuDisplayTypeDetail)
    {
        [UniversalDevice pushToDisplayViewController:menuItem.associatedObject usingNavigationController:(UINavigationController *)self.displayedViewController animated:YES];
    }
    else if (menuItem.displayType == MainMenuDisplayTypeModal && self.displayedViewController.presentedViewController == nil)
    {
        [UniversalDevice displayModalViewController:menuItem.associatedObject onController:self.displayedViewController withCompletionBlock:nil];
    }
    else
    {
        [self displayViewController:menuItem.associatedObject];
    }
    
    // Collapse the menu controller
    RootRevealViewController *rootViewController = (RootRevealViewController *)[UniversalDevice revealViewController];
    [rootViewController collapseViewController];
}

- (UIViewController *)currentlyDisplayedController
{
    return self.displayedViewController;
}

@end

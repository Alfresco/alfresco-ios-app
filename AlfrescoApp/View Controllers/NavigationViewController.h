//
//  NavigationViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NavigationViewController : UINavigationController <UISplitViewControllerDelegate>

@property (nonatomic, weak) UIViewController *rootViewController;
@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@property (nonatomic, assign) BOOL isCurrentlyExpanded;

- (void)resetRootViewControllerWithViewController:(UIViewController *)viewController;

@end

//
//  UniversalDevice.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "UniversalDevice.h"
#import "RootRevealControllerViewController.h"
#import "DetailSplitViewController.h"
#import "NavigationViewController.h"
#import "ItemInDetailViewProtocol.h"
#import "PlaceholderViewController.h"

@implementation UniversalDevice

+ (void)pushToDisplayViewController:(UIViewController *)viewController usingNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated;
{
    if (IS_IPAD)
    {
        UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        
        if ([rootViewController isKindOfClass:[RootRevealControllerViewController class]])
        {
            RootRevealControllerViewController *splitViewController = (RootRevealControllerViewController *)rootViewController;
            UIViewController *rootDetailController = splitViewController.detailViewController;
            if ([rootDetailController isKindOfClass:[DetailSplitViewController class]])
            {
                DetailSplitViewController *rootDetailSplitViewController = (DetailSplitViewController *)rootDetailController;
                UIViewController *controllerInRootDetailSplitViewController = rootDetailSplitViewController.detailViewController;
                
                if ([controllerInRootDetailSplitViewController isKindOfClass:[NavigationViewController class]])
                {
                    NavigationViewController *detailNavigationViewController = (NavigationViewController *)controllerInRootDetailSplitViewController;
                    
                    if ([viewController isKindOfClass:[NavigationViewController class]])
                    {
                        viewController = [(NavigationViewController *)viewController rootViewController];
                    }
                    
                    [detailNavigationViewController resetRootViewControllerWithViewController:viewController];
                    
                    [self addExpandCollapseButtonToViewController:viewController];
                }
            }
        }
        else
        {
            [navigationController pushViewController:viewController animated:animated];
        }
    }
    else
    {
        [navigationController pushViewController:viewController animated:animated];
    }
}

+ (void)displayModalViewController:(UIViewController *)viewController onController:(UIViewController *)controller withCompletionBlock:(void (^)(void))completionBlock
{
    if (IS_IPAD)
    {
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [controller presentViewController:viewController animated:YES completion:^{
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}

+ (void)clearDetailViewController
{
    PlaceholderViewController *viewController = [[PlaceholderViewController alloc] init];
    [UniversalDevice pushToDisplayViewController:viewController usingNavigationController:nil animated:NO];
}

+ (UIViewController *)controllerDisplayedInDetailNavigationController
{
    UIViewController *returnController = nil;
    
    if (IS_IPAD)
    {
        UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        
        if ([rootViewController isKindOfClass:[RootRevealControllerViewController class]])
        {
            RootRevealControllerViewController *splitViewController = (RootRevealControllerViewController *)rootViewController;
            UIViewController *rootDetailController = splitViewController.detailViewController;
            if ([rootDetailController isKindOfClass:[DetailSplitViewController class]])
            {
                DetailSplitViewController *rootDetailSplitViewController = (DetailSplitViewController *)rootDetailController;
                UIViewController *controllerInRootDetailSplitViewController = rootDetailSplitViewController.detailViewController;
                
                if ([controllerInRootDetailSplitViewController isKindOfClass:[NavigationViewController class]])
                {
                    NavigationViewController *detailNavigationViewController = (NavigationViewController *)controllerInRootDetailSplitViewController;
                    returnController = [detailNavigationViewController.viewControllers lastObject];
                }
            }
        }
    }
    
    return returnController;
}

+ (NSString *)detailViewItemIdentifier
{
    id detailViewController = [self controllerDisplayedInDetailNavigationController];
    
    if ([detailViewController conformsToProtocol:@protocol(ItemInDetailViewProtocol)])
    {
        return [detailViewController detailViewItemIdentifier];
    }
    
    return nil;
}

+ (void)addExpandCollapseButtonToViewController:(UIViewController *)viewController
{
//    UIImage *image = [UIImage imageNamed:@"download"];
//    CGRect buttonFrame = CGRectMake(0, 0, image.size.width + 2, image.size.height);
//    UIButton *customButton = [[UIButton alloc] initWithFrame:buttonFrame];
//    [customButton setImage:image forState:UIControlStateNormal];
//    [customButton addTarget:self action:@selector(expandCollapseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
//    
//    customButton.showsTouchWhenHighlighted = YES;
//    
//    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"≡" style:UIBarButtonItemStylePlain target:self action:@selector(expandCollapseButtonAction:)];
    
    [viewController.navigationItem setLeftBarButtonItem:button];
}

+ (void)expandCollapseButtonAction:(UIBarButtonItem *)button
{
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    if ([rootViewController isKindOfClass:[RootRevealControllerViewController class]])
    {
        RootRevealControllerViewController *splitViewController = (RootRevealControllerViewController *)rootViewController;
        UIViewController *rootDetailController = splitViewController.detailViewController;
        if ([rootDetailController isKindOfClass:[DetailSplitViewController class]])
        {
            DetailSplitViewController *rootDetailSplitViewController = (DetailSplitViewController *)rootDetailController;
            [rootDetailSplitViewController.delegate didPressExpandCollapseButton:rootDetailSplitViewController button:button];
        }
    }
}

@end

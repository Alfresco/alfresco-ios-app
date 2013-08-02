//
//  UniversalDevice.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "UniversalDevice.h"
#import "NavigationViewController.h"
#import "ItemInDetailViewProtocol.h"
#import "PlaceholderViewController.h"

@implementation UniversalDevice

+ (void)pushToDisplayViewController:(UIViewController *)viewController usingNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated;
{
    if (IS_IPAD)
    {
        UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        
        if ([rootViewController isKindOfClass:[UISplitViewController class]])
        {
            UISplitViewController *splitViewController = (UISplitViewController *)rootViewController;
            NavigationViewController *detailNavigationViewController = [splitViewController.viewControllers objectAtIndex:1];
            [detailNavigationViewController resetRootViewControllerWithViewController:viewController];
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
        
        if ([rootViewController isKindOfClass:[UISplitViewController class]])
        {
            UISplitViewController *splitViewController = (UISplitViewController *)rootViewController;
            NavigationViewController *detailNavigationViewController = [splitViewController.viewControllers objectAtIndex:1];
            returnController = [detailNavigationViewController.viewControllers lastObject];
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

@end

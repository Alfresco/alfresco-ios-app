//
//  UniversalDevice.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UniversalDevice : NSObject

+ (void)pushToDisplayViewController:(UIViewController *)viewController usingNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated;
+ (void)displayModalViewController:(UIViewController *)viewController onController:(UIViewController *)controller withCompletionBlock:(void (^)(void))completionBlock;
+ (UIViewController *)controllerDisplayedInDetailNavigationController;
+ (NSString *)detailViewItemIdentifier;
+ (void)clearDetailViewController;
+ (void)addExpandCollapseButtonToViewController:(UIViewController *)viewController;
+ (UIViewController *)rootMasterViewController;
+ (UIViewController *)rootDetailViewController;

@end

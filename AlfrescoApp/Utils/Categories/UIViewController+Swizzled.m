//
//  UIViewController+Swizzed.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "UIViewController+Swizzled.h"
#import <objc/objc-runtime.h>

@implementation UIViewController (Swizzled)

- (void)presentViewController_swizzled:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    [self presentViewController_swizzled:viewControllerToPresent animated:flag completion:completion];
    
    if (!IS_IPAD || viewControllerToPresent.modalPresentationStyle == UIModalPresentationFullScreen)
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
}

- (void)dismissViewControllerAnimated_swizzled:(BOOL)flag completion:(void (^)(void))completion
{
    [self dismissViewControllerAnimated_swizzled:flag completion:completion];
    
    if (!IS_IPAD || self.modalPresentationStyle == UIModalPresentationFullScreen)
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    }
}

+ (void)load
{
    Method defaultPresentViewControllerMethod = class_getInstanceMethod(self, @selector(presentViewController:animated:completion:));
    Method swizzedPresentViewControllerMethod = class_getInstanceMethod(self, @selector(presentViewController_swizzled:animated:completion:));
    method_exchangeImplementations(defaultPresentViewControllerMethod, swizzedPresentViewControllerMethod);
    
    Method defaultDismissViewControllerAnimatedMethod = class_getInstanceMethod(self, @selector(dismissViewControllerAnimated:completion:));
    Method swizzledDismissViewControllerAnimatedMethod = class_getInstanceMethod(self, @selector(dismissViewControllerAnimated_swizzled:completion:));
    method_exchangeImplementations(defaultDismissViewControllerAnimatedMethod, swizzledDismissViewControllerAnimatedMethod);
}

@end

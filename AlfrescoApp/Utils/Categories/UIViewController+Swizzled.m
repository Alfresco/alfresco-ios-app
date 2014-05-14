//
//  UIViewController+Swizzled.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "UIViewController+Swizzled.h"
#import <objc/runtime.h>

@implementation UIViewController (Swizzled)

+ (void)load
{
    Method defaultPreferredStatusBarStyleMethod = class_getInstanceMethod(self, @selector(preferredStatusBarStyle));
    Method swizzledPreferredStatusBarStyleMethod = class_getInstanceMethod(self, @selector(preferredStatusBarStyle_swizzled));
    method_exchangeImplementations(defaultPreferredStatusBarStyleMethod, swizzledPreferredStatusBarStyleMethod);
}

- (UIStatusBarStyle)preferredStatusBarStyle_swizzled
{
    UIStatusBarStyle statusBarStyle = UIStatusBarStyleLightContent;
    
    if (self.presentedViewController == self && (!IS_IPAD || self.modalPresentationStyle == UIModalPresentationFullScreen))
    {
        statusBarStyle = UIStatusBarStyleDefault;
    }
    return statusBarStyle;
}

@end

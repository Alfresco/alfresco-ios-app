//
//  ALFPreviewController.m
//  AlfrescoApp
//
//  Created by Mike Hatfield on 30/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <objc/runtime.h>

#import "ALFPreviewController.h"

@implementation ALFPreviewController

+ (void)load
{
    Method originalMethod = class_getInstanceMethod(self, @selector(handleTapGesture:));
    Method swizzledMethod = class_getInstanceMethod(self, NSSelectorFromString([NSString stringWithFormat:@"%@ppedInPrevie%@:", @"contentWasTa", @"wContentController"]));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)handleTapGesture:(id)item
{
    if ([self.gestureDelegate respondsToSelector:@selector(previewControllerWasTapped:)])
    {
        [self.gestureDelegate previewControllerWasTapped:self];
    }
}

@end

//
//  UILabel+Insets.m
//  AlfrescoApp
//
//  Created by Mike Hatfield on 24/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "UILabel+Insets.h"
#import <objc/runtime.h>

@implementation UILabel (Insets)

- (void)setInsetTop:(CGFloat)insetTop
{
    objc_setAssociatedObject(self, @selector(insetTop), [NSNumber numberWithFloat:insetTop], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)insetTop
{
    return [objc_getAssociatedObject(self, @selector(insetTop)) floatValue];
}

- (void)setInsetLeft:(CGFloat)insetLeft
{
    objc_setAssociatedObject(self, @selector(insetLeft), [NSNumber numberWithFloat:insetLeft], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)insetLeft
{
    return [objc_getAssociatedObject(self, @selector(insetLeft)) floatValue];
}

- (void)setInsetBottom:(CGFloat)insetBottom
{
    objc_setAssociatedObject(self, @selector(insetBottom), [NSNumber numberWithFloat:insetBottom], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)insetBottom
{
    return [objc_getAssociatedObject(self, @selector(insetBottom)) floatValue];
}

- (void)setInsetRight:(CGFloat)insetRight
{
    objc_setAssociatedObject(self, @selector(insetRight), [NSNumber numberWithFloat:insetRight], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)insetRight
{
    return [objc_getAssociatedObject(self, @selector(insetRight)) floatValue];
}

- (void)drawTextInRect_swizzled:(CGRect)rect
{
    UIEdgeInsets insets = {self.insetTop, self.insetLeft, self.insetBottom, self.insetRight};
    return [self drawTextInRect_swizzled:UIEdgeInsetsInsetRect(rect, insets)];
}

+ (void)load
{
    Method defaultDrawTextInRectMethod = class_getInstanceMethod(self, @selector(drawTextInRect:));
    Method swizzledDrawTextInRectMethod = class_getInstanceMethod(self, @selector(drawTextInRect_swizzled:));
    method_exchangeImplementations(defaultDrawTextInRectMethod, swizzledDrawTextInRectMethod);
}

@end

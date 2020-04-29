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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method defaultDrawTextInRectMethod = class_getInstanceMethod(self, @selector(drawTextInRect:));
        Method swizzledDrawTextInRectMethod = class_getInstanceMethod(self, @selector(drawTextInRect_swizzled:));
        method_exchangeImplementations(defaultDrawTextInRectMethod, swizzledDrawTextInRectMethod);
    });
}

@end

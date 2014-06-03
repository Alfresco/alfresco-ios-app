/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

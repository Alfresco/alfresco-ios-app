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

#import "UITextField+RightAlignmentSpacingFix.h"
#import <objc/runtime.h>

static NSString * const kNormalSpaceString = @" ";
static NSString * const kNonBreakingSpaceString = @"\u00a0";

@implementation UITextField (RightAlignmentSpacingFix)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalInitWithFrameMethod = class_getInstanceMethod(self, @selector(initWithFrame:));
        Method swizzledInitWithFrameMethod = class_getInstanceMethod(self, @selector(initWithFrame_swizzled:));
        
        method_exchangeImplementations(originalInitWithFrameMethod, swizzledInitWithFrameMethod);
        
        Method originalInitWithCoderMethod = class_getInstanceMethod(self, @selector(initWithCoder:));
        Method swizzledInitWithCoderMethod = class_getInstanceMethod(self, @selector(initWithCoder_swizzled:));
        
        method_exchangeImplementations(originalInitWithCoderMethod, swizzledInitWithCoderMethod);
    });
}

- (instancetype)initWithCoder_swizzled:(NSCoder *)aDecoder
{
    self = [self initWithCoder_swizzled:aDecoder];
    if (self)
    {
        [self addSpacingFix];
    }
    return self;
}

- (instancetype)initWithFrame_swizzled:(CGRect)frame
{
    self = [self initWithFrame_swizzled:frame];
    if (self)
    {
        [self addSpacingFix];
    }
    return self;
}

- (void)addSpacingFix
{
    [self addTarget:self action:@selector(replaceNormalSpacesWithNonBreakingSpaces) forControlEvents:UIControlEventEditingDidBegin];
    
    [self addTarget:self action:@selector(replaceNormalSpacesWithNonBreakingSpaces) forControlEvents:UIControlEventEditingChanged];
    
    [self addTarget:self action:@selector(replaceNonBreakingSpacesWithNormalSpaces) forControlEvents:UIControlEventEditingDidEnd];
}

- (void)replaceNormalSpacesWithNonBreakingSpaces
{
    self.text = [self.text stringByReplacingOccurrencesOfString:kNormalSpaceString withString:kNonBreakingSpaceString];
}

- (void)replaceNonBreakingSpacesWithNormalSpaces
{
    self.text = [self.text stringByReplacingOccurrencesOfString:kNonBreakingSpaceString withString:kNormalSpaceString];
}

@end

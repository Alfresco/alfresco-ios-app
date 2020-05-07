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

#import "MultiSelectContainerView.h"

static CGFloat const kMultiSelectAnimationDuration = 0.2f;

@interface MultiSelectContainerView()

@end

@implementation MultiSelectContainerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self createToolbar];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        [self createToolbar];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if(!self.toolbar.superview)
    {
        self.toolbar.frame = CGRectMake(0, 0, self.frame.size.width, kPickerMultiSelectToolBarHeight);
        [self addSubview:self.toolbar];
    }
}

- (void)show
{
    [self.toolbar enterMultiSelectMode];
    if(self.bottomConstraint)
    {
        [UIView animateWithDuration:kMultiSelectAnimationDuration animations:^{
            self.bottomConstraint.constant = 0.0f;
            self.alpha = 1.0f;
            [self layoutIfNeeded];
        }];
    }
}

- (void)hide
{
    [self.toolbar leaveMultiSelectMode];
    if(self.bottomConstraint)
    {
        [UIView animateWithDuration:kMultiSelectAnimationDuration animations:^{
            self.bottomConstraint.constant = -self.frame.size.height;
            self.alpha = 0.0f;
            [self layoutIfNeeded];
        }];
    }
}

- (void)createToolbar
{
    self.toolbar = [[MultiSelectActionsToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, kPickerMultiSelectToolBarHeight)];
}

@end

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

#import "BulletView.h"

#define BULLET_BORDER_COLOR [UIColor colorWithWhite: 0.4 alpha: 1.0]
#define BULLET_BLANK_COLOR  [UIColor whiteColor]
#define BULLET_FULL_COLOR   [UIColor colorWithWhite: 0.76 alpha: 1.0]
#define BULLET_BORDER_WIDTH 1

@implementation BulletView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self commonSetup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self commonSetup];
    }
    
    return self;
}

- (void)commonSetup
{
    self.layer.cornerRadius = MIN(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))/2;
    self.layer.borderColor = BULLET_BORDER_COLOR.CGColor;
    self.layer.borderWidth = BULLET_BORDER_WIDTH;
    self.blank = YES;
}

#pragma mark - Custom Accessors

- (void) setBlank:(BOOL)blank
{
    _blank = blank;
    self.backgroundColor = _blank ? BULLET_BLANK_COLOR : BULLET_FULL_COLOR;
}

@end

/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

#define kColorBulletBorder  [UIColor colorWithWhite: 0.4 alpha: 1.0]
#define kColorBulletBlank   [UIColor whiteColor]
#define kColorBulletFull    [UIColor colorWithWhite: 0.76 alpha: 1.0]
#define kBulletBorderWidth  1

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
    self.layer.borderColor = kColorBulletBorder.CGColor;
    self.layer.borderWidth = kBulletBorderWidth;
    self.blank = YES;
}

#pragma mark - Custom Accessors

- (void) setBlank:(BOOL)blank
{
    _blank = blank;
    self.backgroundColor = _blank ? kColorBulletBlank : kColorBulletFull;
}

@end
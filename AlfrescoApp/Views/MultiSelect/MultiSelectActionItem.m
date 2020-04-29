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
 
#import "MultiSelectActionItem.h"

static NSInteger const kMinCounterValue = 0;
static NSInteger const kMaxCounterValue = 100;

static CGFloat const kDestructiveButtonHueValue = 0.0f;
static CGFloat const kDestructiveButtonSaturationValue = 0.80f;
static CGFloat const kDestructiveButtonBrightnessValue = 0.71f;
static CGFloat const kDestructiveButtonAlphaValue = 1.0f;

@interface MultiSelectActionItem ()

@property (nonatomic, strong) NSString *barButtonTitleKey;
@property (nonatomic, strong) NSString *barButtonTitleWithCounterKey;
@property (nonatomic, assign) BOOL isDestructive;

@end

@implementation MultiSelectActionItem

- (id)initWithTitle:(NSString *)titleLocalizationKey style:(UIBarButtonItemStyle)style actionId:(NSString *)actionId isDestructive:(BOOL)isDestructive target:(id)target action:(SEL)action
{
    self = [super initWithTitle:NSLocalizedString(titleLocalizationKey, @"Button title") style:style target:target action:action];
    
    if (self)
    {
        self.enabled = NO;
        self.actionId = actionId;
        self.isDestructive = isDestructive;
        self.barButtonTitleKey = titleLocalizationKey;
        [self setPossibleTitles:[NSSet setWithObjects:[self labelTitleWithCounterValue:kMinCounterValue], [self labelTitleWithCounterValue:kMaxCounterValue], nil]];
    }
    return self;
}

- (void)setBarButtonTitleKey:(NSString *)value
{
    _barButtonTitleKey = value;
    self.barButtonTitleWithCounterKey = [_barButtonTitleKey stringByAppendingString:@".counter"];
}

- (void)setIsDestructive:(BOOL)isDestructive
{
    _isDestructive = isDestructive;
    
    if (isDestructive)
    {
        UIColor *actionColor = [UIColor colorWithHue:kDestructiveButtonHueValue saturation:kDestructiveButtonSaturationValue brightness:kDestructiveButtonBrightnessValue alpha:kDestructiveButtonAlphaValue];
        [self setTintColor:actionColor];
    }
}

- (NSString *)labelTitleWithCounterValue:(NSUInteger)counter
{
    NSString *labelValue;
    
    if (counter == 0)
    {
        labelValue = NSLocalizedString(self.barButtonTitleKey, self.labelKey);
    }
    else
    {
        NSString *labelKey = NSLocalizedString(self.barButtonTitleWithCounterKey, self.labelKeyExt);
        labelValue = [NSString stringWithFormat:labelKey, counter];
    }
    
    return labelValue;
}

- (void)setButtonTitleWithCounterValue:(NSUInteger)counter
{
    [self setTitle:[self labelTitleWithCounterValue:counter]];
}

@end

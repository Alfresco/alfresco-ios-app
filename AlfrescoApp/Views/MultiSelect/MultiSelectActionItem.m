//
//  MultiSelectActionItem.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

static NSInteger const kMinCounterValue = 0;
static NSInteger const kMaxCounterValue = 100;

static CGFloat const kDestructiveButtonHueValue = 0.0f;
static CGFloat const kDestructiveButtonSaturationValue = 0.80f;
static CGFloat const kDestructiveButtonBrightnessValue = 0.71f;
static CGFloat const kDestructiveButtonAlphaValue = 0.0f;

#import "MultiSelectActionItem.h"

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

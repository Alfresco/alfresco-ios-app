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

#import "PinBulletsView.h"
#import "BulletView.h"

static NSString * const kShakeAnimationKey = @"shake";
static CGFloat const kShakeAnimationDuration = 0.5f;

@interface PinBulletsView() <CAAnimationDelegate>

@end

@implementation PinBulletsView
{
    IBOutletCollection(BulletView) NSArray *_bullets;
    
    void (^_completionBlock)(void);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        UINib *nib = [UINib nibWithNibName: NSStringFromClass([self class]) bundle:nil];
        UIView *view = [nib instantiateWithOwner:self options:nil][0];
        view.frame = self.bounds;
        [self addSubview:view];
        
        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(view);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:viewBindings]];
    }
    
    return self;
}

- (void)shakeWithCompletionBlock:(void (^)(void))completionBlock
{
    _completionBlock = completionBlock;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.delegate = self;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.duration = kShakeAnimationDuration;
    animation.values = @[@(-20), @(20), @(-20), @(20), @(-10), @(10), @(-5), @(5), @(0)];
    [self.layer addAnimation:animation forKey:kShakeAnimationKey];
}

- (void)fillBullets:(BOOL)fill forPin:(NSString *)pin
{
    [_bullets enumerateObjectsUsingBlock:^(BulletView *bullet, NSUInteger idx, BOOL *stop){
        if (fill == NO || bullet.tag >= pin.length)
        {
            bullet.blank = YES;
        }
        else
        {
            bullet.blank = NO;
        }
    }];
}

#pragma mark - Animations

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag
{
    if (flag)
    {
        [self.layer removeAnimationForKey:kShakeAnimationKey];
    }
    
    if (_completionBlock)
    {
        _completionBlock();
    }
}

@end

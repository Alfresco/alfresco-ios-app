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

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, PinFlow)
{
    PinFlowSet,
    PinFlowUnset,
    PinFlowChange,
    PinFlowEnter,   // Used when launching the app or moving the app into the foreground
    PinFlowVerify,  // Used when deleting the last paid account. Almost similar to PinFlowEnter; the navigation bar is displayed so the user has access to the Cancel button.
    PinFlowAny
};

typedef NS_ENUM(NSUInteger, PinFlowCompletionStatus)
{
    PinFlowCompletionStatusSuccess,
    PinFlowCompletionStatusFailure,
    PinFlowCompletionStatusReset,
    PinFlowCompletionStatusCancel
};

typedef void (^PinFlowCompletionBlock)(PinFlowCompletionStatus status);

#define REMAINING_ATTEMPTS_MAX_VALUE 10

extern NSString * const kShowKeyboardInPinScreenNotification;
extern NSString * const kAppResetedNotification;
static CGFloat const kKeyboardInPinScreenAppearanceDelay = 0.1;

@interface PinViewController : UIViewController <UIKeyInput>

+ (UINavigationController *)pinNavigationViewControllerWithFlow:(PinFlow)pinFlow completionBlock:(PinFlowCompletionBlock)completionBlock;
+ (UINavigationController *)pinNavigationViewControllerWithFlow:(PinFlow)pinFlow inOwnWindow:(BOOL)ownWindow completionBlock:(PinFlowCompletionBlock)completionBlock;
+ (UINavigationController *)pinNavigationViewControllerWithFlow:(PinFlow)pinFlow animatedDismiss:(BOOL)animatedDismiss completionBlock:(PinFlowCompletionBlock)completionBlock;
- (PinFlow)pinFlow;

@end

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
 
#import "UIColor+Custom.h"

@implementation UIColor (Custom)

+ (UIColor *)mainMenuBackgroundColor
{
    return [UIColor colorWithRed:(CGFloat)53.0/255.0 green:(CGFloat)53.0/255.0 blue:(CGFloat)55.0/255.0 alpha:1.0];
}

+ (UIColor *)mainMenuLabelColor
{
    return [UIColor whiteColor];
}

+ (UIColor *)appTintColor
{
    return [UIColor colorWithRed:(CGFloat)56.0/255.0 green:(CGFloat)170.0/255.0 blue:(CGFloat)218.0/255.0 alpha:1.0];
}

+ (UIColor *)noItemsTextColor
{
    return [UIColor colorWithWhite:0.8 alpha:1.0];
}

+ (UIColor *)textDimmedColor
{
    return [UIColor colorWithWhite:0.4 alpha:1.0];
}

+ (UIColor *)textDefaultColor
{
    return [UIColor darkTextColor];
}

+ (UIColor *)documentActionsTintColor
{
    return [UIColor colorWithRed:(CGFloat)53.0/255.0 green:(CGFloat)53.0/255.0 blue:(CGFloat)55.0/255.0 alpha:1.0];
}

+ (UIColor *)documentActionsHighlightColor
{
    return [UIColor appTintColor];
}

+ (UIColor *)syncFailedColor
{
    // Matches status-sync-failed.png
    return [UIColor colorWithRed:0.82 green:0.32 blue:0.34 alpha:1.0];
}

+ (UIColor *)borderGreyColor
{
    return [UIColor colorWithRed:(CGFloat)212.0/255.0 green:(CGFloat)212.0/255.0 blue:212.0/255.0 alpha:1.0f];
}

+ (UIColor *)documentDetailsColor {
    return [UIColor colorWithRed:138/255.0 green:137/255.0 blue:139/255.0 alpha:1.0f];
}

+ (UIColor *)systemNoticeInformationColor
{
    return [UIColor colorWithRed:(CGFloat)56.0/255.0 green:(CGFloat)170.0/255.0 blue:(CGFloat)218.0/255.0 alpha:1.0];
}

+ (UIColor *)systemNoticeErrorColor
{
    return [UIColor colorWithRed:(CGFloat)230.0/255.0 green:(CGFloat)93.0/255.0 blue:(CGFloat)93.0/255.0 alpha:1.0];
}
+ (UIColor *)systemNoticeWarningColor
{
    return [UIColor yellowColor];
}

+ (UIColor *)taskOverdueLabelColor
{
    return [UIColor colorWithRed:(CGFloat)240.0/255.0 green:0.2 blue:0.2 alpha:1.0];
}

+ (UIColor *)taskTransitionApproveColor
{
    return [UIColor colorWithRed:0.27 green:0.85 blue:0.42 alpha:1.0];
}

+ (UIColor *)taskTransitionRejectColor
{
    return [UIColor appTintColor];
}

+ (UIColor *)onboardingOffWhiteColor
{
    return [UIColor colorWithRed:(CGFloat)244.0/255.0 green:(CGFloat)244.0/255.0 blue:(CGFloat)244.0/255.0 alpha:1.0];
}

+ (UIColor *)siteActionsBackgroundColor
{
    return [UIColor colorWithRed:234/255.0f green:235/255.0f blue:237/255.0f alpha:1.0f];
}

+ (UIColor *)addTagButtonTintColor
{
    return [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1.0];
}

+ (UIColor *)selectedCollectionViewCellBackgroundColor
{
    return [UIColor colorWithRed:228/255.0f green:236/255.0f blue:249/255.0f alpha:2.0f];
}

@end

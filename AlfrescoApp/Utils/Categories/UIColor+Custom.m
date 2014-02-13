//
//  UIColor+Custom.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "UIColor+Custom.h"

@implementation UIColor (Custom)

+ (UIColor *)lineSeparatorColor
{
    return [UIColor colorWithRed:(CGFloat)212.0/255.0 green:(CGFloat)212.0/255.0 blue:212.0/255.0 alpha:1.0f];
}

+ (UIColor *)themeBlueColor
{
    return [UIColor colorWithRed:(CGFloat)0.0/255.0 green:(CGFloat)91.0/255.0 blue:(CGFloat)255.0/255.0 alpha:1.0];
}

+ (UIColor *)mainManuBackgroundColor
{
    return [UIColor colorWithRed:(CGFloat)53.0/255.0 green:(CGFloat)53.0/255.0 blue:(CGFloat)55.0/255.0 alpha:1.0];
}

@end

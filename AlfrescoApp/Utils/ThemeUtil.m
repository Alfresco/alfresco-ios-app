//
//  ThemeUtil.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 02/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ThemeUtil.h"

static UIColor *iOS6ThemeColour;

@implementation ThemeUtil

+ (UIColor *)themeColour
{
    UIColor *themeColour = [UIColor whiteColor];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
    {
        themeColour = [self iOS6ThemeColour];
    }
    return themeColour;
}

+ (void)applyThemeToNavigationController:(UINavigationController *)navigationController
{
    if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
    {
        navigationController.navigationBar.barStyle = UIBarStyleBlack;
    }
}

+ (void)applyThemeToTableView:(UITableView *)tableView
{
    if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
    {
        CGRect bounceAreaFrame = tableView.frame;
        bounceAreaFrame.origin.y = tableView.frame.size.height * -1;
        UIView *bounceAreaView = [[UIView alloc] initWithFrame:bounceAreaFrame];
        bounceAreaView.backgroundColor = [self iOS6ThemeColour];
        bounceAreaView.layer.zPosition -= 1;
        [tableView addSubview:bounceAreaView];
    }
}

+ (void)applyThemeToSegmentControl:(UISegmentedControl *)segmentControl
{
    if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
    {
        segmentControl.tintColor = [self iOS6ThemeColour];
    }
}

#pragma mark - Private Functions

+ (UIColor *)iOS6ThemeColour
{
    if (!iOS6ThemeColour)
    {
        iOS6ThemeColour = [UIColor colorWithRed:85.0f/255.0f green:85.0f/255.0f blue:85.0f/255.0f alpha:1.0f];
    }
    return iOS6ThemeColour;
}

@end

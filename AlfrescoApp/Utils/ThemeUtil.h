//
//  ThemeUtil.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 02/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThemeUtil : NSObject

+ (UIColor *)themeColour;
+ (void)applyThemeToNavigationController:(UINavigationController *)navigationController;
+ (void)applyThemeToTableView:(UITableView *)tableView;
+ (void)applyThemeToSegmentControl:(UISegmentedControl *)segmentControl;

@end

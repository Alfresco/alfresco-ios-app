//
//  AppDelegate.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NavigationViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

typedef NS_ENUM(NSUInteger, MainMenuNavigationControllerType)
{
    NavigationControllerTypeAccounts = 0,
    NavigationControllerTypeActivities,
    NavigationControllerTypeRepository,
    NavigationControllerTypeSites,
    NavigationControllerTypeTasks,
    NavigationControllerTypeSync,
    NavigationControllerTypeMyFiles,
    NavigationControllerTypeSharedFiles,
    NavigationControllerTypeDownloads,
    NavigationControllerTypeSettings,
    NavigationControllerTypeAbout,
    NavigationControllerTypeHelp,
    NavigationControllerType_MAX_ENUM    // <-- Ensure this is the last entry
};

@property (strong, nonatomic) UIWindow *window;

@end

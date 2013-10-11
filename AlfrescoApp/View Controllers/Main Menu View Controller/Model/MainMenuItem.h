//
//  MainMenuItem.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface MainMenuItem : NSObject

@property (nonatomic, assign, readonly) MainMenuNavigationControllerType controllerType;
@property (nonatomic, strong, readonly) NSString *imageName;
@property (nonatomic, strong, readonly) NSString *localizedTitleKey;
@property (nonatomic, strong, readonly) UIViewController *viewController;
@property (nonatomic, assign, readonly, getter = shouldDisplayInDetailView) BOOL displayInDetail;

- (instancetype)initWithControllerType:(MainMenuNavigationControllerType)controllerType imageName:(NSString *)imageName localizedTitleKey:(NSString *)localizedKey viewController:(UIViewController *)viewController displayInDetail:(BOOL)displayInDetail;

@end

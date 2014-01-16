//
//  AppConfigurationManager.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 15/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppConfigurationManager : NSObject

@property (nonatomic, assign) BOOL showActivities;
@property (nonatomic, assign) BOOL showRepository;
@property (nonatomic, assign) BOOL showSites;
@property (nonatomic, assign) BOOL showTasks;
@property (nonatomic, assign) BOOL showFavorites;
@property (nonatomic, assign) BOOL showSearch;
@property (nonatomic, assign) BOOL showLocalFiles;
@property (nonatomic, assign) BOOL showNotifications;

+ (instancetype)sharedManager;

@end

//
//  AppConfigurationManager.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 15/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppConfigurationManager : NSObject

@property (nonatomic, strong, readonly) AlfrescoFolder *myFiles;
@property (nonatomic, strong, readonly) AlfrescoFolder *sharedFiles;
@property (nonatomic, assign, readonly) BOOL showRepositorySpecificItems;

- (void)checkIfConfigurationFileExistsLocallyAndUpdateAppConfiguration;
- (BOOL)visibilityForMainMenuItemWithKey:(NSString *)menuItemKey;

+ (AppConfigurationManager *)sharedManager;

@end

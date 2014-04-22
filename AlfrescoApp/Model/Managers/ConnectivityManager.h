//
//  ConnectivityManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConnectivityManager : NSObject

@property (nonatomic, assign, readonly, getter = hasInternetConnection) BOOL hasInternetConnection;
@property (nonatomic, assign, readonly, getter = isOnCellular) BOOL onCellular;
@property (nonatomic, assign, readonly, getter = isOnWifi) BOOL onWifi;

+ (id)sharedManager;

- (BOOL)canReachHostName:(NSString *)hostname;

@end

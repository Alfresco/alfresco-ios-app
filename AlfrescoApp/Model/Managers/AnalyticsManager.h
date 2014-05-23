//
//  AnalyticsManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 02/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

@interface AnalyticsManager : NSObject

@property (nonatomic, assign, readonly) BOOL analyticsAreActive;

+ (AnalyticsManager *)sharedManager;
- (void)startAnalytics;
- (void)stopAnalytics;

@end

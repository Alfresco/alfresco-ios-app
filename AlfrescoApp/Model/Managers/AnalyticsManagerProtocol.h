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

#import <Foundation/Foundation.h>
#import "AnalyticsConstants.h"

typedef NS_ENUM(NSUInteger, AnalyticsType)
{
    AnalyticsTypeFlurry             = 1 << 0,
    AnalyticsTypeGoogleAnalytics    = 1 << 1,
};

@protocol AnalyticsManagerProtocol <NSObject>

- (void)startAnalytics;
- (void)stopAnalytics;
- (void)checkAnalyticsFeature;
- (NSString *)serverTypeStringForSession:(id<AlfrescoSession>)session;

// Tracking methods
- (void)trackScreenWithName:(NSString *)screenName;
- (void)trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value;
- (void)trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value customMetric:(AnalyticsMetric)metric metricValue:(NSNumber *)metricValue;
- (void)trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value customMetric:(AnalyticsMetric)metric metricValue:(NSNumber *)metricValue session:(id<AlfrescoSession>)session;

@end

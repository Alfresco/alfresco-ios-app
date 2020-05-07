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

#import "AnalyticsManager.h"
#import "PreferenceManager.h"
#import "AccountManager.h"
#import "AppConfigurationManager.h"
#import "DownloadManager.h"
#import "SyncManager.h"
#import "SyncHelper.h"
#import "SyncNodeInfo.h"

@import Firebase;

#define kGoogleAnalyticsDefaultDispatchInterval 120

@interface AnalyticsManager ()
@property (nonatomic, assign, readwrite) BOOL flurryAnalyticsHasStarted;
@property (nonatomic, assign, readwrite) BOOL googleAnalyticsHasStarted;
@property (nonatomic, assign, readwrite) BOOL flurryAnalyticsAreActive;
@property (nonatomic, assign, readwrite) BOOL googleAnalyticsAreActive;
@end

@implementation AnalyticsManager

+ (AnalyticsManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static AnalyticsManager *sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesDidChange:) name:kSettingsDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountAdded:) name:kAlfrescoAccountAddedNotification object:nil];
    }
    return self;
}


- (void)startAnalytics
{
    if ([[PreferenceManager sharedManager] shouldSendDiagnostics])
    {
        // Firebase Analytics
        [FIRApp configure];
    }
}

- (void)stopAnalytics
{
    
}

 
- (void)checkAnalyticsFeature
{
    void (^checkAnalyticsBlock)(BOOL, NSUInteger) = ^(BOOL forceAnalyticsDisable, NSUInteger checkedAccountsCount){
        if (forceAnalyticsDisable)
        {
            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
            [defaults setBool:NO forKey:kSettingsSendDiagnosticsEnable];
            [defaults synchronize];
            
            [self trackEventWithCategory:kAnalyticsEventCategorySettings
                                  action:kAnalyticsEventActionAnalytics
                                   label:kAnalyticsEventLabelDisableConfig
                                   value:@1];
            [self stopAnalytics];
        }
        else
        {
            if (checkedAccountsCount == [AccountManager sharedManager].allAccounts.count)
            {
                NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
                BOOL oldDiagnosticsEnableState = [defaults boolForKey:kSettingsSendDiagnosticsEnable];
                
                if (oldDiagnosticsEnableState == NO)
                {
                    [defaults setBool:YES forKey:kSettingsSendDiagnosticsEnable];
                    [defaults synchronize];
                    [self trackAnalyticsEnableEvent];
                }
            }
        }
    };
    
    if ([AccountManager sharedManager].allAccounts.count == 0)
    {
        checkAnalyticsBlock(NO, 0);
    }
    
    [[AccountManager sharedManager].allAccounts enumerateObjectsUsingBlock:^(UserAccount *account, NSUInteger idx, BOOL *stop){
        AlfrescoConfigService *configService = [[AppConfigurationManager sharedManager] configurationServiceForAccount:account];
        
        [configService retrieveFeatureConfigWithType:kAlfrescoConfigFeatureTypeAnalytics completionBlock:^(AlfrescoFeatureConfig *config, NSError *error) {
            if (config && !config.isEnable)
            {
                checkAnalyticsBlock(YES, idx+1);
                *stop = YES;
            }
            else
            {
                checkAnalyticsBlock(NO, idx+1);
            }
        }];
    }];
}

- (NSString *)serverTypeStringForSession:(id<AlfrescoSession>)session
{
    NSString *serverTypeString = nil;
    
    if ([session isKindOfClass:[AlfrescoRepositorySession class]])
    {
        UserAccount *selectedUserAccount = [AccountManager sharedManager].selectedAccount;
        serverTypeString = [selectedUserAccount.samlData isSamlEnabled] ? kAnalyticsEventLabelOnPremiseSAML : kAnalyticsEventLabelOnPremise;
    }
    else
    {
        serverTypeString = kAnalyticsEventLabelCloud;
    }
    
    return serverTypeString;
}

#pragma mark - Tracking Methods

- (void)trackScreenWithName:(NSString *)screenName
{
    if (self.googleAnalyticsAreActive == NO)
    {
        return;
    }
    
    if (screenName == nil)
    {
        return;
    }
    
    AlfrescoLogInfo(@"GA_SCREEN: %@", screenName);
    [FIRAnalytics setScreenName:screenName screenClass:screenName];
}

- (void)trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value
{
    [self trackEventWithCategory:category action:action label:label value:value customMetric:AnalyticsMetricNone metricValue:nil];
}

- (void)trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value customMetric:(AnalyticsMetric)metric metricValue:(NSNumber *)metricValue
{
    [self trackEventWithCategory:category action:action label:label value:value customMetric:metric metricValue:metricValue session:nil];
}

- (void)trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value customMetric:(AnalyticsMetric)metric metricValue:(NSNumber *)metricValue session:(id<AlfrescoSession>)session
{
    if (self.googleAnalyticsAreActive == NO)
    {
        return;
    }
    
    if (category == nil || action == nil || label == nil)
    {
        return;
    }
    
    if (value == nil)
    {
        value = @1;
    }
    
    if ([AlfrescoLog sharedInstance].logLevel == AlfrescoLogLevelTrace)
    {
        AlfrescoLogTrace(@"GA_EVENT: %@ - %@ - %@ - %@%@", category, action, label, value, metric == AnalyticsMetricNone ? @"" : [NSString stringWithFormat:@" - %@ - %@", @(metric), metricValue.stringValue]);
    }
    
    [FIRAnalytics logEventWithName:category parameters:@{@"action": action,
                                                         @"label": label,
                                                         @"value": value,
                                                         @"metric": metricValue.stringValue}];
}

- (void)trackAnalyticsEnableEvent
{
    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySettings
                                                      action:kAnalyticsEventActionAnalytics
                                                       label:kAnalyticsEventLabelEnable
                                                       value:@1];
}

#pragma mark - Notifications Handlers

- (void)preferencesDidChange:(NSNotification *)notification
{
    NSString *preferenceKeyChanged = notification.object;
    
    void (^startOrStopAnalytics)(BOOL, AnalyticsType, BOOL) = ^void(BOOL shouldSendDiagnostics, AnalyticsType analyticsType, BOOL analyticsAreActive){
        if (shouldSendDiagnostics && analyticsAreActive == NO)
        {
        }
        else if (analyticsAreActive)
        {
        }
    };
    
    if ([preferenceKeyChanged isEqualToString:kSettingsSendDiagnosticsIdentifier])
    {
        BOOL shouldSendDiagnostics = [notification.userInfo[kSettingChangedToKey] boolValue];
        
        if (shouldSendDiagnostics)
        {
            startOrStopAnalytics(shouldSendDiagnostics, AnalyticsTypeFlurry, self.flurryAnalyticsAreActive);
            startOrStopAnalytics(shouldSendDiagnostics, AnalyticsTypeGoogleAnalytics, self.googleAnalyticsAreActive);
            
            // Send analytics enable event after starting analytics.
            [self trackAnalyticsEnableEvent];
        }
        else
        {
            // Send analytics disable event before stoping analytics.
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySettings
                                                              action:kAnalyticsEventActionAnalytics
                                                               label:kAnalyticsEventLabelDisable
                                                               value:@1];
        }
    }
}

- (void)accountAdded:(NSNotification *)notification
{
    [self checkAnalyticsFeature];
}

@end

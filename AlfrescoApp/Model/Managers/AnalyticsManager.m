/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
#import "Flurry.h"
#import "PreferenceManager.h"

@interface AnalyticsManager ()
@property (nonatomic, assign, readwrite) BOOL flurryHasStarted;
@property (nonatomic, assign, readwrite) BOOL analyticsAreActive;
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
    }
    return self;
}

- (void)startAnalytics
{
    if ([[PreferenceManager sharedManager] shouldSendDiagnostics])
    {
        [self start];
    }
}

- (void)stopAnalytics
{
    [self stop];
}

#pragma mark - Private Methods

- (void)start
{
    if (!self.flurryHasStarted)
    {
        [Flurry startSession:FLURRY_API_KEY];
        self.flurryHasStarted = YES;
    }

    [Flurry setEventLoggingEnabled:YES];
    [Flurry setSessionReportsOnCloseEnabled:YES];
    [Flurry setSessionReportsOnPauseEnabled:YES];
    self.analyticsAreActive = YES;
}

- (void)stop
{
    [Flurry setEventLoggingEnabled:NO];
    [Flurry setSessionReportsOnCloseEnabled:NO];
    [Flurry setSessionReportsOnPauseEnabled:NO];
    self.analyticsAreActive = NO;
}

- (void)preferencesDidChange:(NSNotification *)notification
{
    NSString *preferenceKeyChanged = notification.object;

    if ([preferenceKeyChanged isEqualToString:kSettingsSendDiagnosticsIdentifier])
    {
        BOOL shouldSendDiagnostics = [notification.userInfo[kSettingChangedToKey] boolValue];
        
        if (shouldSendDiagnostics && !self.analyticsAreActive)
        {
            [self start];
        }
        else if (self.analyticsAreActive)
        {
            [self stop];
        }
    }
}

@end

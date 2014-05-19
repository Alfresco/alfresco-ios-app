//
//  AnalyticsManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 02/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

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

// Should never get here
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

void uncaughtExceptionHandler(NSException *exception)
{
    [Flurry logError:@"Uncaught Exception" message:@"The app crashed!" exception:exception];
}

- (void)start
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    if (!self.flurryHasStarted)
    {
        [Flurry startSession:ALFRESCO_FLURRY_API_KEY];
        self.flurryHasStarted = YES;
    }

    [Flurry setEventLoggingEnabled:YES];
    [Flurry setSessionReportsOnCloseEnabled:YES];
    [Flurry setSessionReportsOnPauseEnabled:YES];
    self.analyticsAreActive = YES;
}

- (void)stop
{
    NSSetUncaughtExceptionHandler(nil);
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

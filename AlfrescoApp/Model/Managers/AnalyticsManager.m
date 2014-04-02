//
//  AnalyticsManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 02/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "AnalyticsManager.h"
#import "Flurry.h"

@interface AnalyticsManager ()

@property (nonatomic, assign, readwrite) BOOL analyticsAreActive;

@end

@implementation AnalyticsManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static AnalyticsManager *sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (void)startAnalytics
{
    // ADD CHECK TO SEE IF "SEND DIAGNOSTIC INFORMATION" IS SET.
    // CHECK DEPENDS ON MOBILE-2060
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [Flurry startSession:ALFRESCO_FLURRY_API_KEY];
    [Flurry setEventLoggingEnabled:YES];
    [Flurry setSessionReportsOnCloseEnabled:YES];
    [Flurry setSessionReportsOnPauseEnabled:YES];
    self.analyticsAreActive = YES;
}

- (void)stopAnalytics
{
    NSSetUncaughtExceptionHandler(nil);
    [Flurry setEventLoggingEnabled:NO];
    [Flurry setSessionReportsOnCloseEnabled:NO];
    [Flurry setSessionReportsOnPauseEnabled:NO];
    self.analyticsAreActive = NO;
}

#pragma mark - Private Methods

void uncaughtExceptionHandler(NSException *exception)
{
    // ADD CHECK TO SEE IF "SEND DIAGNOSTIC INFORMATION" IS SET. IF SO, LOG THIS ERROR
    // CHECK DEPENDS ON MOBILE-2060
    [Flurry logError:@"Uncaught Exception" message:@"The app crashed!" exception:exception];
}

@end

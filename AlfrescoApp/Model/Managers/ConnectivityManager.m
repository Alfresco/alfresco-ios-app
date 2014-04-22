//
//  ConnectivityManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ConnectivityManager.h"
#import "Reachability.h"

@interface ConnectivityManager ()

@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, assign, readwrite, getter = hasInternetConnection) BOOL hasInternetConnection;
@property (nonatomic, assign, readwrite, getter = isOnCellular) BOOL onCellular;
@property (nonatomic, assign, readwrite, getter = isOnWifi) BOOL onWifi;

@end

@implementation ConnectivityManager

+ (id)sharedManager
{
    static dispatch_once_t onceToken;
    static ConnectivityManager *sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.internetReachability = [Reachability reachabilityForInternetConnection];
        [self.internetReachability startNotifier];
        
        // start listening to reachability notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
    return self;
}

- (BOOL)hasInternetConnection
{
    NetworkStatus currentState = [self.internetReachability currentReachabilityStatus];
    if (currentState != NotReachable)
    {
        return YES;
    }
    return NO;
}

- (BOOL)isOnCellular
{
    BOOL isOnCellular = NO;
    
    NetworkStatus currentState = [self.internetReachability currentReachabilityStatus];
    if (currentState == ReachableViaWWAN)
    {
        isOnCellular = YES;
    }
    
    return isOnCellular;
}

- (BOOL)isOnWifi
{
    BOOL isOnWifi = NO;
    
    NetworkStatus currentState = [self.internetReachability currentReachabilityStatus];
    if (currentState == ReachableViaWiFi)
    {
        isOnWifi = YES;
    }
    
    return isOnWifi;
}

- (BOOL)canReachHostName:(NSString *)hostname
{
    BOOL canReach = NO;
    
    Reachability *reach = [Reachability reachabilityWithHostName:hostname];
    NetworkStatus status = [reach currentReachabilityStatus];
    
    if (status != NotReachable)
    {
        canReach = YES;
    }
    
    return canReach;
}

#pragma mark - Private Functions

- (void)reachabilityChanged:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConnectivityChangedNotification object:@([self hasInternetConnection])];
}

@end

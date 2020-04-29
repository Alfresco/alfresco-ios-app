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
 
#import "ConnectivityManager.h"
#import "Reachability.h"

@interface ConnectivityManager ()

@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, assign, readwrite, getter = hasInternetConnection) BOOL hasInternetConnection;
@property (nonatomic, assign, readwrite, getter = isOnCellular) BOOL onCellular;
@property (nonatomic, assign, readwrite, getter = isOnWifi) BOOL onWifi;

@end

@implementation ConnectivityManager

+ (ConnectivityManager *)sharedManager
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

- (void)canReachHostName:(NSString *)hostname withCompletionBlock:(void (^)(BOOL isReachable))completionBlock
{
    if (completionBlock != NULL)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NetworkStatus status = [[Reachability reachabilityWithHostName:hostname] currentReachabilityStatus];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(status != NotReachable);
            });
        });
    }
}

#pragma mark - Private Functions

- (void)reachabilityChanged:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConnectivityChangedNotification object:@([self hasInternetConnection])];
}

@end

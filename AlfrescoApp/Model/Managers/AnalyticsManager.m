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
#import <Google/Analytics.h>
#import "AccountManager.h"
#import "AppConfigurationManager.h"
#import "DownloadManager.h"
#import "SyncManager.h"
#import "SyncHelper.h"
#import "SyncNodeInfo.h"

@interface AnalyticsManager ()
@property (nonatomic, assign, readwrite) BOOL flurryHasStarted;
@property (nonatomic, assign, readwrite) BOOL googleAnalyticsHasStarted;
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

#pragma mark - Tracking Methods

- (void) trackScreenWithName: (NSString *) screenName
{
    if (screenName == nil)
        return;
    
    NSLog(@"GA_SCREEN: %@", screenName);
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void) trackEventWithCategory: (NSString *) category action: (NSString *) action label: (NSString *) label value: (NSNumber *) value
{
    [self trackEventWithCategory:category action:action label:label value:value customMetric:AnalyticsMetricNone metricValue:nil];
}

- (void) trackEventWithCategory: (NSString *) category action: (NSString *) action label: (NSString *) label value: (NSNumber *) value customMetric: (AnalyticsMetric) metric metricValue: (NSNumber *) metricValue
{
    [self trackEventWithCategory:category action:action label:label value:value customMetric:metric metricValue:metricValue session:nil];
}

- (void) trackEventWithCategory: (NSString *) category action: (NSString *) action label: (NSString *) label value: (NSNumber *) value customMetric: (AnalyticsMetric) metric metricValue: (NSNumber *) metricValue session: (id<AlfrescoSession>) session
{
    if (category == nil || action == nil || label == nil)
        return;
    
    if (value == nil)
        value = @1;
    
    NSLog(@"GA_EVENT: %@ - %@ - %@ - %@%@", category, action, label, value, metric == AnalyticsMetricNone ? @"" : [NSString stringWithFormat:@" - %lu - %@", (unsigned long)metric, metricValue.stringValue]);
    
    GAIDictionaryBuilder *builder = [GAIDictionaryBuilder createEventWithCategory:category action:action label:label value:value];
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    if (metric != AnalyticsMetricNone)
    {
        [tracker set:[GAIFields customMetricForIndex:metric]
               value:metricValue.stringValue];
    }
    
    if (session) // create new session and add custom dimensions
    {
        [builder set:@"start" forKey:kGAISessionControl];
        
        // Accounts Info / Number of accounts
        [self addAccountsInfoInTracker:tracker];
        
        // Settings Info
        [self addSettingsInfoInTracker:tracker];
        
        // Server Info
        [self addServerInfoMetricsInTracker:tracker session:session];
        
        // Download Info / Local Files
        [self addDownloadInfoMetricsInTracker:tracker];
        
        // Sync Info
        [self addSyncInfoMetricsInTracker:tracker];
        
        AppConfigurationManager *appConfigManager = [AppConfigurationManager sharedManager];
        AlfrescoConfigService *configService = [appConfigManager configurationServiceForCurrentAccount];
        configService.session = session;
        
        [configService retrieveProfilesWithCompletionBlock:^(NSArray *profilesArray, NSError *profilesError)
        {
            // Profiles Info / Number of profiles
            [self addProfilesInfoInTracker:tracker profilesArray:profilesArray];
            
            NSDictionary *dictionary = [builder build];
            [tracker send:dictionary];
        }];
    }
    else
    {
        NSDictionary *dictionary = [builder build];
        [tracker send:dictionary];
    }
}

#pragma mark - Private Methods For Analytics

- (void) addSettingsInfoInTracker: (id<GAITracker>) tracker
{
    // Sync Cellular
    BOOL syncOnCellular = [[PreferenceManager sharedManager] shouldSyncOnCellular];
    [tracker set:[GAIFields customMetricForIndex:AnalyticsMetricSyncOnCellular] value:syncOnCellular ? @"1" : @"0"];
    
    // Data Protection
    BOOL fileProtection = [[PreferenceManager sharedManager] shouldProtectFiles];
    [tracker set:[GAIFields customMetricForIndex:AnalyticsMetricDataProtection] value:fileProtection ? @"1" : @"0"];
    
    // Passcode - v2.3
}

- (void) addProfilesInfoInTracker: (id<GAITracker>) tracker profilesArray: (NSArray *) profilesArray
{
    [tracker set:[GAIFields customMetricForIndex:AnalyticsMetricProfilesCounts]
           value:[NSString stringWithFormat:@"%lu", (unsigned long)profilesArray.count]];
}

- (void) addAccountsInfoInTracker: (id<GAITracker>) tracker
{
    NSUInteger accountsCount = [AccountManager sharedManager].allAccounts.count;
    NSString *accountsCountString = [NSString stringWithFormat:@"%lu", (unsigned long)accountsCount];
    
    [tracker set:[GAIFields customMetricForIndex:AnalyticsMetricAccounts] value:accountsCountString];
}

- (void) addServerInfoMetricsInTracker: (id<GAITracker>) tracker session: (id<AlfrescoSession>) session
{
    NSString *serverTypeString = [session isKindOfClass:[AlfrescoRepositorySession class]] ? kAnalyticsEventLabelOnPremise : kAnalyticsEventLabelCloud;
    
    [tracker set:[GAIFields customMetricForIndex:AnalyticsMetricSessionCreated] value:@"1"];
    [tracker set:[GAIFields customDimensionForIndex:AnalyticsDimensionServerType] value:serverTypeString];
    [tracker set:[GAIFields customDimensionForIndex:AnalyticsDimensionServerEdition] value:[session repositoryInfo].edition];
    [tracker set:[GAIFields customDimensionForIndex:AnalyticsDimensionServerVersion] value:[session repositoryInfo].version];
}

- (void) addDownloadInfoMetricsInTracker: (id<GAITracker>) tracker
{
    NSArray *documentPaths = [[DownloadManager sharedManager] downloadedDocumentPaths];
    [tracker set:[GAIFields customMetricForIndex:AnalyticsMetricLocalFiles]
           value:[NSString stringWithFormat:@"%lu", (unsigned long)documentPaths.count]];
}

- (void) addSyncInfoMetricsInTracker: (id<GAITracker>) tracker
{
    UserAccount *account = [AccountManager sharedManager].selectedAccount;
    
    // Number of files
    NSArray *syncFiles = [[SyncHelper sharedHelper] retrieveSyncFileNodesForAccountWithId:account.accountIdentifier inManagedObjectContext:nil];
    NSUInteger syncFilesCount = syncFiles.count;
    [tracker set:[GAIFields customMetricForIndex:AnalyticsMetricSyncedFiles] value:[NSString stringWithFormat:@"%lu", (unsigned long)syncFilesCount]];
    
    // Number of folders
    NSArray *syncFolders = [[SyncHelper sharedHelper] retrieveSyncFolderNodesForAccountWithId:account.accountIdentifier inManagedObjectContext:nil];
    NSUInteger syncFoldersCount = syncFolders.count;
    [tracker set:[GAIFields customMetricForIndex:AnalyticsMetricSyncedFolders] value:[NSString stringWithFormat:@"%lu", (unsigned long)syncFoldersCount]];
    
    // Files size
    __block unsigned long long filesSize = 0;
    [syncFiles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        SyncNodeInfo *node = (SyncNodeInfo *) obj;
        NSError *error;
        NSString *path = node.syncContentPath;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        
        NSNumber *fileSize = attributes[NSFileSize];
        
        if (fileSize)
            filesSize += fileSize.unsignedLongLongValue;
    }];
    
    [tracker set:[GAIFields customMetricForIndex:AnalyticsMetricFileSize] value:[NSString stringWithFormat:@"%llu", filesSize]];
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
    
    if (!self.googleAnalyticsHasStarted)
    {
        NSLog(@"GA: %@", GA_API_KEY);
        [[GAI sharedInstance] trackerWithTrackingId:GA_API_KEY];
        self.googleAnalyticsHasStarted = YES;
    }
    
    [GAI sharedInstance].optOut = NO;
    
    self.analyticsAreActive = YES;
}

- (void)stop
{
    [Flurry setEventLoggingEnabled:NO];
    [Flurry setSessionReportsOnCloseEnabled:NO];
    [Flurry setSessionReportsOnPauseEnabled:NO];
    
    [GAI sharedInstance].optOut = YES;
    
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
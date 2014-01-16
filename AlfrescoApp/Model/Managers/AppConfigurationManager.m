//
//  AppConfigurationManager.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 15/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "AppConfigurationManager.h"

static NSString * const kConfigurationRootMenuKey = @"rootMenu";
static NSString * const kConfigurationActivitiesKey = @"com.alfresco.activities";
static NSString * const kConfigurationFavoritesKey = @"com.alfresco.favorites";
static NSString * const kConfigurationLocalFilesKey = @"com.alfresco.localFiles";
static NSString * const kConfigurationNotificationsKey = @"com.alfresco.notifications";
static NSString * const kConfigurationRepositoryKey = @"com.alfresco.repository";
static NSString * const kConfigurationSearchKey = @"com.alfresco.search";
static NSString * const kConfigurationSitesKey = @"com.alfresco.sites";
static NSString * const kConfigurationTasksKey = @"com.alfresco.tasks";
static NSString * const kConfigurationItemVisibleKey = @"visible";

@interface AppConfigurationManager ()

@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;

@end

@implementation AppConfigurationManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static AppConfigurationManager *sharedConfigurationManager = nil;
    dispatch_once(&onceToken, ^{
        sharedConfigurationManager = [[self alloc] init];
    });
    return sharedConfigurationManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sessionReceived:)
                                                     name:kAlfrescoSessionReceivedNotification
                                                   object:nil];
    }
    return self;
}

- (void)retrieveAppConfiguration
{
    [self.documentService retrieveNodeWithFolderPath:kAppConfigurationFileLocationOnServer completionBlock:^(AlfrescoNode *node, NSError *error) {
        
        if (node)
        {
            [self.documentService retrieveContentOfDocument:(AlfrescoDocument *)node completionBlock:^(AlfrescoContentFile *contentFile, NSError *contentError) {
                
                if (contentFile)
                {
                    [self updateAppConfigurationUsingFileURL:contentFile.fileUrl];
                }
            } progressBlock:nil];
        }
        else
        {
            if (error.code == kAlfrescoErrorCodeRequestedNodeNotFound)
            {
            }
        }
    }];
}

#pragma mark - Private Methods

- (void)updateAppConfigurationUsingFileURL:(NSURL *)fileUrl
{
    NSData *configurationData = [NSData dataWithContentsOfURL:fileUrl];
    
    NSError *jsonError = nil;
    NSDictionary *appConfiguration = [NSJSONSerialization JSONObjectWithData:configurationData options:NSJSONReadingMutableContainers error:&jsonError];
    
    if (!jsonError)
    {
        NSDictionary *rootMenuConfiguration = [appConfiguration objectForKey:kConfigurationRootMenuKey];
        if (rootMenuConfiguration)
        {
            NSDictionary *activitiesConfiguration = [rootMenuConfiguration objectForKey:kConfigurationActivitiesKey];
            if (activitiesConfiguration)
            {
                self.showActivities = [[activitiesConfiguration objectForKey:kConfigurationItemVisibleKey] boolValue];
            }
            
            NSDictionary *favoritesConfiguration = [rootMenuConfiguration objectForKey:kConfigurationFavoritesKey];
            if (favoritesConfiguration)
            {
                self.showFavorites = [[favoritesConfiguration objectForKey:kConfigurationItemVisibleKey] boolValue];
            }
            
            NSDictionary *localFilesConfiguration = [rootMenuConfiguration objectForKey:kConfigurationLocalFilesKey];
            if (localFilesConfiguration)
            {
                self.showLocalFiles = [[localFilesConfiguration objectForKey:kConfigurationItemVisibleKey] boolValue];
            }
            
            NSDictionary *notificationConfiguration = [rootMenuConfiguration objectForKey:kConfigurationNotificationsKey];
            if (notificationConfiguration)
            {
                self.showNotifications = [[notificationConfiguration objectForKey:kConfigurationItemVisibleKey] boolValue];
            }
            
            NSDictionary *repositoryConfiguration = [rootMenuConfiguration objectForKey:kConfigurationRepositoryKey];
            if (repositoryConfiguration)
            {
                self.showRepository = [[repositoryConfiguration objectForKey:kConfigurationItemVisibleKey] boolValue];
            }
            
            NSDictionary *searchConfiguration = [rootMenuConfiguration objectForKey:kConfigurationSearchKey];
            if (searchConfiguration)
            {
                self.showSearch = [[searchConfiguration objectForKey:kConfigurationItemVisibleKey] boolValue];
            }
            
            NSDictionary *sitesConfiguration = [rootMenuConfiguration objectForKey:kConfigurationSitesKey];
            if (sitesConfiguration)
            {
                self.showSites = [[sitesConfiguration objectForKey:kConfigurationItemVisibleKey] boolValue];
            }
            
            NSDictionary *tasksConfiguration = [rootMenuConfiguration objectForKey:kConfigurationTasksKey];
            if (tasksConfiguration)
            {
                self.showTasks = [[tasksConfiguration objectForKey:kConfigurationItemVisibleKey] boolValue];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAppConfigurationUpdatedNotification object:nil userInfo:nil];
        }
    }
}

#pragma mark - Session Notification Method

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    [self retrieveAppConfiguration];
}

@end

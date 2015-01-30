/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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
 
#import "AppConfigurationManager.h"
#import "AccountManager.h"

static NSString * const kConfigurationRootMenuKey = @"rootMenu";
static NSString * const kConfigurationItemVisibleKey = @"visible";

static NSString * const kRepositoryId = @"{RepositoryId}";
static NSString * const kRepositoryDataDictionaryPathKey = @"com.alfresco.dataDictionary.{RepositoryId}";
static NSString * const kRepositoryDownloadedConfigurationFileLastUpdatedDate = @"repositoryDownloadedConfigurationFileLastUpdatedDate";

@interface AppConfigurationManager ()

@property (nonatomic, strong) id<AlfrescoSession> alfrescoSession;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, strong) NSMutableDictionary *appConfigurations;
@property (nonatomic, assign) BOOL useDefaultConfiguration;
@property (nonatomic, assign, readwrite) BOOL showRepositorySpecificItems;
@property (nonatomic, strong, readwrite) AlfrescoFolder *myFiles;
@property (nonatomic, strong, readwrite) AlfrescoPermissions *myFilesPermissions;
@property (nonatomic, strong, readwrite) AlfrescoFolder *sharedFiles;
@property (nonatomic, strong, readwrite) AlfrescoPermissions *sharedFilesPermissions;

@end

@implementation AppConfigurationManager

+ (AppConfigurationManager *)sharedManager
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
        [self checkIfConfigurationFileExistsLocallyAndUpdateAppConfiguration];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noMoreAccounts:) name:kAlfrescoAccountsListEmptyNotification object:nil];
    }
    return self;
}

- (void)retrieveAppConfigurationWithCompletionBlock:(void (^)())completionBlock
{
    void (^processError)(NSError *) = ^(NSError *error) {
        if (error.code == kAlfrescoErrorCodeRequestedNodeNotFound)
        {
            [self updateAppUsingDefaultConfiguration];
            
            NSError *error = nil;
            [[AlfrescoFileManager sharedManager] removeItemAtPath:[self localConfigurationFilePathForSelectedAccount] error:&error];
            
            if (error)
            {
                AlfrescoLogDebug(@"Could not remove config file", error);
            }
        }
        else
        {
            [self checkIfConfigurationFileExistsLocallyAndUpdateAppConfiguration];
        }
    };
    
    [self appDataDictionaryPathWithCompletionBlock:^(NSString *dataDictionaryPath) {
        if (dataDictionaryPath)
        {
            [self.documentService retrieveNodeWithFolderPath:dataDictionaryPath completionBlock:^(AlfrescoNode *node, NSError *nodeRetrievalError) {
                if (node)
                {
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    NSString *destinationPath = [self localConfigurationFilePathForSelectedAccount];
                    // if config file does not exist at destination clear last downloaded date in user defaults
                    if (![[AlfrescoFileManager sharedManager] fileExistsAtPath:destinationPath])
                    {
                        [userDefaults removeObjectForKey:kRepositoryDownloadedConfigurationFileLastUpdatedDate];
                        [userDefaults synchronize];
                    }

                    NSDate *downloadedConfigurationFileLastModificationDate = [userDefaults objectForKey:kRepositoryDownloadedConfigurationFileLastUpdatedDate];
                    BOOL downloadConfigurationFile = downloadedConfigurationFileLastModificationDate ? ([downloadedConfigurationFileLastModificationDate compare:node.modifiedAt] == NSOrderedAscending) : YES;
                    if (downloadConfigurationFile)
                    {
                        NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];

                        [self.documentService retrieveContentOfDocument:(AlfrescoDocument *)node outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *documentRetrievalError) {
                            if (succeeded)
                            {
                                [self updateAppConfigurationUsingFileURL:[NSURL fileURLWithPath:destinationPath]];
                                [userDefaults setObject:node.modifiedAt forKey:kRepositoryDownloadedConfigurationFileLastUpdatedDate];
                                [userDefaults synchronize];
                            }
                            else
                            {
                                processError(documentRetrievalError);
                            }
                            completionBlock();
                        } progressBlock:nil];
                    }
                    else
                    {
                        [self checkIfConfigurationFileExistsLocallyAndUpdateAppConfiguration];
                        completionBlock();
                    }
                }
                else
                {
                    processError(nodeRetrievalError);
                    completionBlock();
                }
            }];
        }
        else
        {
            [self checkIfConfigurationFileExistsLocallyAndUpdateAppConfiguration];
            completionBlock();
        }
    }];
}

- (BOOL)visibilityForMainMenuItemWithKey:(NSString *)menuItemKey
{
    BOOL visible = YES;
    
    if ([menuItemKey isEqualToString:kAppConfigurationSharedFilesKey])
    {
        visible = self.sharedFiles != nil;
    }
    else if ([menuItemKey isEqualToString:kAppConfigurationMyFilesKey])
    {
        visible = self.myFiles != nil;
    }
    else if ([menuItemKey isEqualToString:kAppConfigurationTasksKey])
    {
        // Only show tasks for on-premise servers, if a workflow engine is available
        if ([self.alfrescoSession isKindOfClass:[AlfrescoCloudSession class]])
        {
            visible = NO;
        }
        else if (!self.alfrescoSession.repositoryInfo.capabilities.doesSupportActivitiWorkflowEngine &&
                 !self.alfrescoSession.repositoryInfo.capabilities.doesSupportJBPMWorkflowEngine)
        {
            visible = NO;
        }
        
        if (visible)
        {
            visible = [self visibilityInfoInAppConfigurationForMenuItem:menuItemKey];
        }
    }
    else if (!self.useDefaultConfiguration)
    {
        visible = [self visibilityInfoInAppConfigurationForMenuItem:menuItemKey];
    }
    return visible;
}

- (void)checkIfConfigurationFileExistsLocallyAndUpdateAppConfiguration
{
    AccountManager *accountManager = [AccountManager sharedManager];
    
    if (accountManager.selectedAccount)
    {
        self.showRepositorySpecificItems = YES;
        NSString *configurationFilePath = [self localConfigurationFilePathForSelectedAccount];
        BOOL configurationFileExists = [[AlfrescoFileManager sharedManager] fileExistsAtPath:configurationFilePath];
        if (configurationFileExists)
        {
            [self updateAppConfigurationUsingFileURL:[NSURL fileURLWithPath:configurationFilePath]];
        }
        else
        {
            [self updateAppUsingDefaultConfiguration];
        }
    }
    else
    {
        self.showRepositorySpecificItems = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAppConfigurationUpdatedNotification object:self userInfo:nil];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification Method

- (void)sessionReceived:(NSNotification *)notification
{
    self.myFiles = nil;
    self.sharedFiles = nil;
    self.alfrescoSession = notification.object;
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.alfrescoSession];
    self.searchService = [[AlfrescoSearchService alloc] initWithSession:self.alfrescoSession];
    
    void (^retrieveMyFilesAndSharedFiles)(void) = ^(void)
    {
        BOOL showMyFiles = [self visibilityInfoInAppConfigurationForMenuItem:kAppConfigurationMyFilesKey];
        BOOL showSharedFiles = [self visibilityInfoInAppConfigurationForMenuItem:kAppConfigurationSharedFilesKey];
        NSString *repositoryEdition = self.alfrescoSession.repositoryInfo.edition;
        float version = [[NSString stringWithFormat:@"%i.%i", self.alfrescoSession.repositoryInfo.majorVersion.intValue, self.alfrescoSession.repositoryInfo.minorVersion.intValue] floatValue];

        if (([repositoryEdition isEqualToString:kRepositoryEditionEnterprise] && version >= 4.2f) ||
            ([repositoryEdition isEqualToString:kRepositoryEditionCommunity] && version >= 4.3f))
        {
            __block NSInteger numberOfRetrievalsInProgress = 0;
            
            if (showMyFiles)
            {
                numberOfRetrievalsInProgress++;

                [self retrieveMyFilesWithCompletionBlock:^{
                    numberOfRetrievalsInProgress--;
                    if (numberOfRetrievalsInProgress == 0)
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAppConfigurationUpdatedNotification object:self userInfo:nil];
                    }
                }];
            }
            if (showSharedFiles)
            {
                numberOfRetrievalsInProgress++;

                [self retrieveSharedFilesWithCompletionBlock:^{
                    numberOfRetrievalsInProgress--;
                    if (numberOfRetrievalsInProgress == 0)
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAppConfigurationUpdatedNotification object:self userInfo:nil];
                    }
                }];
            }
        }
    };
    
    if ([self.alfrescoSession isKindOfClass:[AlfrescoCloudSession class]])
    {
        [self updateAppUsingDefaultConfiguration];
        retrieveMyFilesAndSharedFiles();
    }
    else
    {
        [self retrieveAppConfigurationWithCompletionBlock:^{
            retrieveMyFilesAndSharedFiles();
        }];
    }
}

- (void)accountRemoved:(NSNotification *)notification
{
    UserAccount *accountRemoved = (UserAccount *)notification.object;
    
    if ([[[AccountManager sharedManager] selectedAccount] isEqual:accountRemoved])
    {
        self.showRepositorySpecificItems = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAppConfigurationUpdatedNotification object:self userInfo:nil];
    }
    
    NSError *error = nil;
    [[AlfrescoFileManager sharedManager] removeItemAtPath:[self localConfigurationFilePathForSelectedAccount] error:&error];
    
    if (error)
    {
        AlfrescoLogDebug(@"Could not remove config file", error);
    }
}

- (void)noMoreAccounts:(NSNotification *)notification
{
    self.showRepositorySpecificItems = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAppConfigurationUpdatedNotification object:self userInfo:nil];
}

#pragma mark - Private Methods

- (BOOL)visibilityInfoInAppConfigurationForMenuItem:(NSString *)menuItemKey
{
    BOOL visible = YES;
    NSDictionary *menuItemConfiguration = [self.appConfigurations objectForKey:menuItemKey];
    
    if (menuItemConfiguration)
    {
        NSNumber *visibility = [menuItemConfiguration objectForKey:kConfigurationItemVisibleKey];
        if (visibility)
        {
            visible = visibility.boolValue;
        }
    }
    return visible;
}

- (NSString *)localConfigurationFilePathForSelectedAccount
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    NSString *accountIdentifier = selectedAccount.accountIdentifier;
    
    if (selectedAccount.accountType == UserAccountTypeCloud)
    {
        accountIdentifier = [NSString stringWithFormat:@"%@-%@", accountIdentifier, selectedAccount.selectedNetworkId];
    }
    
    NSString *configurationFileName = [accountIdentifier stringByAppendingPathExtension:[kAppConfigurationFileLocationOnServer pathExtension]];
    NSURL *sharedContainerURL = [[NSFileManager alloc] containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroupIdentifier];
    return [sharedContainerURL.path stringByAppendingPathComponent:configurationFileName];
}

- (void)updateAppUsingDefaultConfiguration
{
    self.useDefaultConfiguration = YES;
    self.showRepositorySpecificItems = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAppConfigurationUpdatedNotification object:self userInfo:nil];
}

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
            self.useDefaultConfiguration = NO;
            self.showRepositorySpecificItems = YES;
            self.appConfigurations = [rootMenuConfiguration mutableCopy];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAppConfigurationUpdatedNotification object:self userInfo:nil];
        }
    }
}

- (void)appDataDictionaryPathWithCompletionBlock:(void (^)(NSString *dataDictionaryPath))completionBlock
{
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedAppGroupIdentifier];
    
    if (self.alfrescoSession)
    {
        AlfrescoRepositoryInfo *repositoryInfo = self.alfrescoSession.repositoryInfo;
        
        // When using the PublicAPI, all repository identifiers are returned as "-default-" and so the rootFolder ID is used as the unique key instead
        NSString *repositoryIdentifier = repositoryInfo.capabilities.doesSupportPublicAPI ? self.alfrescoSession.rootFolder.identifier : repositoryInfo.identifier;
        NSString *dataDictionaryPathKey = [kRepositoryDataDictionaryPathKey stringByReplacingOccurrencesOfString:kRepositoryId withString:repositoryIdentifier];
        NSString *dataDictionaryPath = [userDefaults objectForKey:dataDictionaryPathKey];
        
        if (dataDictionaryPath)
        {
            completionBlock(dataDictionaryPath);
        }
        else
        {
            NSString *searchQuery = @"SELECT * FROM cmis:folder WHERE CONTAINS ('QNAME:\"app:company_home/app:dictionary\"')";
            [self.searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *resultsArray, NSError *error) {
                if (error)
                {
                    AlfrescoLogDebug(@"Could not retrieve Data Dictionary: %@", error);
                    completionBlock(nil);
                }
                else
                {
                    AlfrescoFolder *dataDictionaryFolder = [resultsArray firstObject];
                    if (dataDictionaryFolder)
                    {
                        NSString *configurationFileLocationOnServer = [NSString stringWithFormat:@"/%@/%@", dataDictionaryFolder.name, kAppConfigurationFileLocationOnServer];
                        [userDefaults setObject:configurationFileLocationOnServer forKey:dataDictionaryPathKey];
                        [userDefaults synchronize];
                        completionBlock(configurationFileLocationOnServer);
                    }
                    else
                    {
                        completionBlock(nil);
                    }
                }
            }];
        }
    }
    else
    {
        completionBlock(nil);
    }
}

- (void)retrieveSharedFilesWithCompletionBlock:(void (^)())completionBlock
{
    NSString *searchQuery = @"SELECT * FROM cmis:folder WHERE CONTAINS ('QNAME:\"app:company_home/app:shared\"')";
    [self.searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *resultsArray, NSError *error) {
        if (error)
        {
            AlfrescoLogDebug(@"Could not retrieve Shared Files: %@", error);
            if (completionBlock != NULL)
            {
                completionBlock();
            }
        }
        else
        {
            self.sharedFiles = [resultsArray firstObject];
            if (!self.sharedFiles)
            {
                if (completionBlock != NULL)
                {
                    completionBlock();
                }
            }
            else
            {
                [self.documentService retrievePermissionsOfNode:self.sharedFiles completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                    if (error)
                    {
                        AlfrescoLogDebug(@"Could not retrieve permissions for Shared Files: %@", error);
                        self.sharedFilesPermissions = nil;
                    }
                    else
                    {
                        self.sharedFilesPermissions = permissions;
                    }

                    if (completionBlock != NULL)
                    {
                        completionBlock();
                    }
                }];
            }
        }
    }];
}

- (void)retrieveMyFilesWithCompletionBlock:(void (^)())completionBlock
{
    // MOBILE-2984: The username needs to be escaped using ISO9075 encoding, as there's nothing built-in to do this and this
    // is a temporary fix (CMIS 1.1 will expose the nodeRef of the users home folder) we'll manually replace the commonly used
    // characters manually, namely, "@" and space rather than implementing a complete ISO9075 encoder!
    NSString *escapedUsername = [self.alfrescoSession.personIdentifier stringByReplacingOccurrencesOfString:@"@" withString:@"_x0040_"];
    escapedUsername = [escapedUsername stringByReplacingOccurrencesOfString:@" " withString:@"_x0020_"];
    
    NSString *searchQuery = [NSString stringWithFormat:@"SELECT * FROM cmis:folder WHERE CONTAINS ('QNAME:\"app:company_home/app:user_homes/cm:%@\"')", escapedUsername];
    [self.searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *resultsArray, NSError *error) {
        if (error)
        {
            AlfrescoLogDebug(@"Could not retrieve My Files: %@", error);
            if (completionBlock != NULL)
            {
                completionBlock();
            }
        }
        else
        {
            self.myFiles = [resultsArray firstObject];
            if (!self.myFiles)
            {
                if (completionBlock != NULL)
                {
                    completionBlock();
                }
            }
            else
            {
                [self.documentService retrievePermissionsOfNode:self.myFiles completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                    if (error)
                    {
                        AlfrescoLogDebug(@"Could not retrieve permissions for My Files: %@", error);
                        self.myFilesPermissions = nil;
                    }
                    else
                    {
                        self.myFilesPermissions = permissions;
                    }

                    if (completionBlock != NULL)
                    {
                        completionBlock();
                    }
                }];
            }
        }
    }];
}

@end

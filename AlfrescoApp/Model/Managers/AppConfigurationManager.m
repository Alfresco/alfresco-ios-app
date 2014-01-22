//
//  AppConfigurationManager.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 15/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "AppConfigurationManager.h"
#import "AccountManager.h"

static NSString * const kConfigurationRootMenuKey = @"rootMenu";
static NSString * const kConfigurationItemVisibleKey = @"visible";

// repository version numbers supporting My Files and Shared Files
static NSUInteger const kRepositorySupportedMajorVersion = 4;
static NSUInteger const kRepositoryCommunitySupportedMinorVersion = 3;
static NSUInteger const kRepositoryEnterpriseSupportedMinorVersion = 2;

static NSString * const kRepositoryEditionEnterprise = @"Enterprise";
static NSString * const kRepositoryEditionCommunity = @"Community";

@interface AppConfigurationManager ()

@property (nonatomic, strong) id<AlfrescoSession> alfrescoSession;
@property (nonatomic, strong) NSMutableDictionary *appConfigurations;
@property (nonatomic, assign) BOOL useDefaultConfiguration;
@property (nonatomic, assign, readwrite) BOOL showRepositorySpecificItems;
@property (nonatomic, strong, readwrite) AlfrescoFolder *myFiles;
@property (nonatomic, strong, readwrite) AlfrescoFolder *sharedFiles;

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
        [self checkIfConfigurationFileExistsLocallyAndUpdateAppConfiguration];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noMoreAccounts:) name:kAlfrescoAccountsListEmptyNotification object:nil];
    }
    return self;
}

- (void)retrieveAppConfigurationWithCompletionBlock:(void (^)())completionBlock
{
    void (^processError)(NSError *) = ^(NSError *error)
    {
        if (error.code == kAlfrescoErrorCodeRequestedNodeNotFound)
        {
            [self updateAppUsingDefaultConfiguration];
            
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:[self localConfigurationFilePathForSelectedAccount] error:&error];
            
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
    
    AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.alfrescoSession];
    [documentService retrieveNodeWithFolderPath:kAppConfigurationFileLocationOnServer completionBlock:^(AlfrescoNode *node, NSError *nodeRetrievalError) {
        
        if (node)
        {
            NSString *destinationPath = [self localConfigurationFilePathForSelectedAccount];
            NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];
            [documentService retrieveContentOfDocument:(AlfrescoDocument *)node outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *documentRetrievalError) {
                
                if (succeeded)
                {
                    self.useDefaultConfiguration = NO;
                    self.showRepositorySpecificItems = YES;
                    [self updateAppConfigurationUsingFileURL:[NSURL fileURLWithPath:destinationPath]];
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
            processError(nodeRetrievalError);
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
        BOOL configurationFileExists = [[NSFileManager defaultManager] fileExistsAtPath:configurationFilePath];
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
    
    [self retrieveAppConfigurationWithCompletionBlock:^{
        
        BOOL showMyFiles = [self visibilityInfoInAppConfigurationForMenuItem:kAppConfigurationMyFilesKey];
        BOOL showSharedFiles = [self visibilityInfoInAppConfigurationForMenuItem:kAppConfigurationSharedFilesKey];
        
        NSString *repositoryEdition = self.alfrescoSession.repositoryInfo.edition;
        NSInteger repositoryMajorVersion = [self.alfrescoSession.repositoryInfo.majorVersion intValue];
        NSInteger repositoryMinorVersion = [self.alfrescoSession.repositoryInfo.minorVersion intValue];
        
        if ((showMyFiles || showSharedFiles) && repositoryMajorVersion >= kRepositorySupportedMajorVersion)
        {
            BOOL isEnterpriseServerAndSupportsMyFilesSharedFiles = ([repositoryEdition isEqualToString:kRepositoryEditionEnterprise] && repositoryMinorVersion >= kRepositoryEnterpriseSupportedMinorVersion);
            BOOL isCommunityServerAndSupportsMyFilesSharedFiles = ([repositoryEdition isEqualToString:kRepositoryEditionCommunity] && repositoryMinorVersion >= kRepositoryCommunitySupportedMinorVersion);
            
            if (isEnterpriseServerAndSupportsMyFilesSharedFiles || isCommunityServerAndSupportsMyFilesSharedFiles)
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
        }
    }];
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
    [[NSFileManager defaultManager] removeItemAtPath:[self localConfigurationFilePathForSelectedAccount] error:&error];
    
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
    return [NSTemporaryDirectory() stringByAppendingPathComponent:configurationFileName];
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
            self.appConfigurations = [rootMenuConfiguration mutableCopy];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAppConfigurationUpdatedNotification object:self userInfo:nil];
        }
    }
}

- (void)retrieveSharedFilesWithCompletionBlock:(void (^)())completionBlock
{
    NSString *searchQuery = @"SELECT * FROM cmis:folder WHERE CONTAINS ('QNAME:\"app:company_home/app:shared\"')";
    AlfrescoSearchService *searchService = [[AlfrescoSearchService alloc] initWithSession:self.alfrescoSession];
    [searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *resultsArray, NSError *error) {
        
        if (error)
        {
            AlfrescoLogDebug(@"Could not retrieve Shared Files: %@", error);
        }
        else
        {
            self.sharedFiles = [resultsArray firstObject];
        }
        
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}

- (void)retrieveMyFilesWithCompletionBlock:(void (^)())completionBlock
{
    NSString *searchQuery = [NSString stringWithFormat:@"SELECT * FROM cmis:folder WHERE CONTAINS ('QNAME:\"app:company_home/app:user_homes/cm:%@\"')", self.alfrescoSession.personIdentifier];
    AlfrescoSearchService *searchService = [[AlfrescoSearchService alloc] initWithSession:self.alfrescoSession];
    [searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *resultsArray, NSError *error) {
        
        if (error)
        {
            AlfrescoLogDebug(@"Could not retrieve My Files: %@", error);
        }
        else
        {
            self.myFiles = [resultsArray firstObject];
        }
        
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}

@end

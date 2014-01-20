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

@interface AppConfigurationManager ()

@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) NSMutableDictionary *appConfigurations;
@property (nonatomic, assign) BOOL useDefaultConfiguration;
@property (nonatomic, assign, readwrite) BOOL showRepositorySpecificItems;

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
        [self  checkIfConfigurationFileExistsLocallyAndUpdateAppConfiguration];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noMoreAccounts:) name:kAlfrescoAccountsListEmptyNotification object:nil];
    }
    return self;
}

- (void)retrieveAppConfiguration
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
    
    [self.documentService retrieveNodeWithFolderPath:kAppConfigurationFileLocationOnServer completionBlock:^(AlfrescoNode *node, NSError *nodeRetrievalError) {
        
        if (node)
        {
            NSString *destinationPath = [self localConfigurationFilePathForSelectedAccount];
            NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];
            [self.documentService retrieveContentOfDocument:(AlfrescoDocument *)node outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *documentRetrievalError) {
                
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
            } progressBlock:nil];
        }
        else
        {
            processError(nodeRetrievalError);
        }
    }];
}

- (BOOL)visibilityForMainMenuItemWithKey:(NSString *)menuItemKey
{
    BOOL visible = YES;
    
    if (!self.useDefaultConfiguration)
    {
        NSDictionary *menuItemConfiguration = [self.appConfigurations objectForKey:menuItemKey];
        
        if (menuItemConfiguration)
        {
            NSNumber *visibility = [menuItemConfiguration objectForKey:kConfigurationItemVisibleKey];
            if (visibility)
            {
                visible = visibility.boolValue;
            }
        }
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
    id<AlfrescoSession> session = notification.object;
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    [self retrieveAppConfiguration];
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

@end

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
#import "MainMenuVisibilityScope.h"
#import "MainMenuItem.h"
#import "MainMenuLocalConfigurationBuilder.h"
#import "MainMenuRemoteConfigurationBuilder.h"
#import "Utility.h"

static NSString * const kMainMenuConfigurationDefaultsKey = @"Configuration";

@interface AppConfigurationManager ()
@property (nonatomic, strong) AlfrescoConfigService *currentConfigService;
@property (nonatomic, strong) AlfrescoConfigService *embeddedConfigService;
@property (nonatomic, strong) AlfrescoConfigService *noAccountConfigService;
@property (nonatomic, strong) NSString *currentConfigAccountIdentifier;
@end

@implementation AppConfigurationManager

static dispatch_once_t onceToken;
+ (AppConfigurationManager *)sharedManager
{
    
    static AppConfigurationManager *sharedConfigurationManager = nil;
    dispatch_once(&onceToken, ^{
        sharedConfigurationManager = [[self alloc] init];
    });
    return sharedConfigurationManager;
}

+ (AppConfigurationManager *)resetInstanceAndReturnManager
{
    onceToken = 0;
    return [AppConfigurationManager sharedManager];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noMoreAccounts:) name:kAlfrescoAccountsListEmptyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configurationFileUpdatedFromServer:) name:kAlfrescoConfigNewConfigRetrievedFromServerNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedProfileDidChange:) name:kAlfrescoConfigProfileDidChangeNotification object:nil];
        
        [self setupConfigurationFileFromBundleIfRequiredWithCompletionBlock:^(NSString *configurationFilePath) {
            NSDictionary *parameters = @{kAlfrescoConfigServiceParameterFolder: configurationFilePath.stringByDeletingLastPathComponent,
                                         kAlfrescoConfigServiceParameterFileName: configurationFilePath.lastPathComponent};
            NSDictionary *noAccountParameters = @{kAlfrescoConfigServiceParameterFolder:configurationFilePath.stringByDeletingLastPathComponent,
                                                  kAlfrescoConfigServiceParameterFileName: kAlfrescoNoAccountConfigurationFileName};
            
            self.embeddedConfigService = [[AlfrescoConfigService alloc] initWithDictionary:parameters];
            self.noAccountConfigService = [[AlfrescoConfigService alloc] initWithDictionary:noAccountParameters];
            if(([AccountManager sharedManager].allAccounts.count > 0) || ([AccountManager sharedManager].selectedAccount != nil))
            {
                self.currentConfigService = self.embeddedConfigService;
            }
            else
            {
                self.currentConfigService = self.noAccountConfigService;
            }
            
            [self.currentConfigService retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *defaultProfile, NSError *defaultProfileError) {
                if (defaultProfileError)
                {
                    AlfrescoLogWarning(@"Could not retrieve the default profile: %@", defaultProfileError.localizedDescription);
                }
                else
                {
                    self.selectedProfile = defaultProfile;
                }
            }];
        }];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray *)visibleItemIdentifiersForAccount:(UserAccount *)account
{
    NSMutableDictionary *savedDictionary = ((NSDictionary *)[[NSUserDefaults standardUserDefaults] valueForKey:kMainMenuConfigurationDefaultsKey]).mutableCopy;
    NSString *accountIdentifier = account.accountIdentifier;
    
    MainMenuVisibilityScope *visibility = [NSKeyedUnarchiver unarchiveObjectWithData:savedDictionary[accountIdentifier]];
    
    return visibility.visibleIdentifiers;
}

- (NSArray *)hiddenItemIdentifiersForAccount:(UserAccount *)account
{
    NSMutableDictionary *savedDictionary = ((NSDictionary *)[[NSUserDefaults standardUserDefaults] valueForKey:kMainMenuConfigurationDefaultsKey]).mutableCopy;
    NSString *accountIdentifier = account.accountIdentifier;
    
    MainMenuVisibilityScope *visibility = [NSKeyedUnarchiver unarchiveObjectWithData:savedDictionary[accountIdentifier]];
    
    return visibility.hiddenIdentifiers;
}

- (void)saveVisibleMenuItems:(NSArray *)visibleMenuItems hiddenMenuItems:(NSArray *)hiddenMenuItems forAccount:(UserAccount *)account
{
    NSArray *orderedVisibleIdentifiers = [visibleMenuItems valueForKey:@"itemIdentifier"];
    NSArray *orderedHiddenIdentifiers = [hiddenMenuItems valueForKey:@"itemIdentifier"];
    
    NSString *accountIdentifier = account.accountIdentifier;
    MainMenuVisibilityScope *visibility = [MainMenuVisibilityScope visibilityScopeWithVisibleIdentifiers:orderedVisibleIdentifiers hiddenIdentifiers:orderedHiddenIdentifiers];
    
    NSDictionary *accountDictionaryToPersist = @{accountIdentifier : [NSKeyedArchiver archivedDataWithRootObject:visibility]};
    
    NSMutableDictionary *savedDictionary = ((NSDictionary *)[[NSUserDefaults standardUserDefaults] valueForKey:kMainMenuConfigurationDefaultsKey]).mutableCopy;
    
    if (!savedDictionary)
    {
        savedDictionary = [NSMutableDictionary dictionary];
    }
    
    [savedDictionary addEntriesFromDictionary:accountDictionaryToPersist];
    
    [[NSUserDefaults standardUserDefaults] setObject:savedDictionary forKey:kMainMenuConfigurationDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)orderedArrayFromUnorderedMainMenuItems:(NSArray *)unorderedMenuItems usingOrderedIdentifiers:(NSArray *)orderListIdentifiers appendNotFoundObjects:(BOOL)append;
{
    NSMutableArray *sortedItems = [NSMutableArray array];
    // Array holding all objects that have not been found in the ordered list of identifiers
    NSMutableArray *notFoundObjects = [NSMutableArray arrayWithArray:unorderedMenuItems];
    
    if (orderListIdentifiers)
    {
        [orderListIdentifiers enumerateObjectsUsingBlock:^(NSString *objectIdentifier, NSUInteger idx, BOOL *stop) {
            NSPredicate *search = [NSPredicate predicateWithFormat:@"itemIdentifier like %@", objectIdentifier];
            MainMenuItem *object = [unorderedMenuItems filteredArrayUsingPredicate:search].firstObject;
            if (object)
            {
                [sortedItems addObject:object];
                [notFoundObjects removeObject:object]; // remove the object if it has been found
            }
        }];
        
        // if we want the not found objects to be appended to the result array
        if (append)
        {
            [sortedItems addObjectsFromArray:notFoundObjects];
        }
    }
    else
    {
        sortedItems = unorderedMenuItems.mutableCopy;
    }
    
    return sortedItems;
}

- (void)setVisibilityForMenuItems:(NSArray *)menuItems forAccount:(UserAccount *)account
{
    NSArray *hiddenIdentifiers = [self hiddenItemIdentifiersForAccount:account];
    
    [hiddenIdentifiers enumerateObjectsUsingBlock:^(NSString *objectIdentifier, NSUInteger idx, BOOL *stop) {
        NSPredicate *search = [NSPredicate predicateWithFormat:@"itemIdentifier like %@", objectIdentifier];
        MainMenuItem *object = [menuItems filteredArrayUsingPredicate:search].firstObject;
        if (object)
        {
            object.hidden = YES;
        }
    }];
}

- (AlfrescoConfigService *)configurationServiceForCurrentAccount
{
    return self.currentConfigService;
}

- (AlfrescoConfigService *)configurationServiceForAccount:(UserAccount *)account
{
    AlfrescoConfigService *returnService = nil;
    
    if(account)
    {
        if ([self.currentConfigAccountIdentifier isEqualToString:account.accountIdentifier])
        {
            returnService = [self configurationServiceForCurrentAccount];
        }
        else if ([self serverConfigurationExistsForAccount:account])
        {
            NSString *accountConfigurationFolderPath = [self accountSpecificConfigurationFolderPath:account];
            NSDictionary *parameters = @{kAlfrescoConfigServiceParameterFolder: accountConfigurationFolderPath,
                                         kAlfrescoConfigServiceParameterFileName: kAlfrescoEmbeddedConfigurationFileName};
            returnService = [[AlfrescoConfigService alloc] initWithDictionary:parameters];
        }
        else
        {
            returnService = [self configurationServiceForEmbeddedConfiguration];
        }
    }
    else
    {
        returnService = [self configurationServiceForNoAccountConfiguration];
    }
    
    return returnService;
}
                         
- (AlfrescoConfigService *)configurationServiceForNoAccountConfiguration
{
    return self.noAccountConfigService;
}

- (AlfrescoConfigService *)configurationServiceForEmbeddedConfiguration
{
    return self.embeddedConfigService;
}

- (BOOL)serverConfigurationExistsForAccount:(UserAccount *)account
{
    NSString *accountConfigurationFolderPath = [[self accountSpecificConfigurationFolderPath:account] stringByAppendingPathComponent:kAlfrescoEmbeddedConfigurationFileName];
    return [[AlfrescoFileManager sharedManager] fileExistsAtPath:accountConfigurationFolderPath];
}

- (void)removeConfigurationFileForAccount:(UserAccount *)account
{
    NSString *accountConfigurationFolderPath = [self accountSpecificConfigurationFolderPath:account];
    NSString *accountConfigurationPath = [NSString stringWithFormat:@"%@/%@", accountConfigurationFolderPath, kAlfrescoEmbeddedConfigurationFileName];
    NSError *error = nil;
    [[AlfrescoFileManager sharedManager] removeItemAtPath:accountConfigurationPath error:&error];
    if ([account.accountIdentifier isEqualToString:self.currentConfigAccountIdentifier])
    {
        [self setupConfigurationFileFromBundleIfRequiredWithCompletionBlock:^(NSString *configurationFilePath) {
            NSDictionary *parameters = @{kAlfrescoConfigServiceParameterFolder: configurationFilePath.stringByDeletingLastPathComponent,
                                         kAlfrescoConfigServiceParameterFileName: configurationFilePath.lastPathComponent};
            
            AlfrescoConfigService *configService = [[AlfrescoConfigService alloc] initWithDictionary:parameters];
            self.currentConfigService = configService;
            self.currentConfigService.session = self.session;
        }];
    }
}

#pragma mark - Notification Method

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    
    self.currentConfigService = [self configurationServiceForAccount:[AccountManager sharedManager].selectedAccount];
    self.currentConfigService.session = session;

    [self.currentConfigService retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *defaultProfile, NSError *defaultProfileError) {
        if (defaultProfileError)
        {
            AlfrescoLogError(@"Error retrieving the default profile. Error: %@", defaultProfileError.localizedDescription);
            
            if (defaultProfileError.code == kAlfrescoErrorCodeRequestedNodeNotFound) // The requested node wasn't found
            {
                // If the node is not found on the server, delete configuration.json from user's folder.
                UserAccount *account = [AccountManager sharedManager].selectedAccount;
                NSString *accountSpecificFolderPath = [self accountSpecificConfigurationFolderPath:account];
                accountSpecificFolderPath = [accountSpecificFolderPath stringByAppendingPathComponent:kAlfrescoEmbeddedConfigurationFileName];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:accountSpecificFolderPath])
                {
                    NSError *removeConfigurationError;
                    BOOL fileRemovedSuccessfully = [[NSFileManager defaultManager] removeItemAtPath:accountSpecificFolderPath error:&removeConfigurationError];
                    
                    if (fileRemovedSuccessfully)
                    {
                        MainMenuLocalConfigurationBuilder *localBuilder = [[MainMenuLocalConfigurationBuilder alloc] initWithAccount:account session:session];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigFileDidUpdateNotification object:localBuilder userInfo:@{kAppConfigurationUserCanEditMainMenuKey : @YES}];
                    }
                }
            }
        }
        else
        {
            self.selectedProfile = defaultProfile;
            
            // Selected account
            UserAccount *account = [AccountManager sharedManager].selectedAccount;
            
            // Update the Main Menu Controller
            MainMenuLocalConfigurationBuilder *localBuilder = [[MainMenuLocalConfigurationBuilder alloc] initWithAccount:account session:session];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigFileDidUpdateNotification object:localBuilder userInfo:@{kAppConfigurationUserCanEditMainMenuKey : @YES}];
            
            if (![session isKindOfClass:[AlfrescoCloudSession class]])
            {
                // Create the local path to store the configuration file
                NSString *accountSpecificFolderPath = [self accountSpecificConfigurationFolderPath:account];
                
                // Add parameters to the session
                NSDictionary *parameters = @{kAlfrescoConfigServiceParameterFolder : accountSpecificFolderPath,
                                             kAlfrescoConfigServiceParameterFileName : kAlfrescoEmbeddedConfigurationFileName};
                [session addParametersFromDictionary:parameters];
                
                // Attempt to download and select the default profile
                AlfrescoConfigService *configService = [[AlfrescoConfigService alloc] initWithSession:session];
                // define a success block
                void (^profileSuccessfullySelectedBlock)(AlfrescoProfileConfig *profile, BOOL isEmbeddedConfig) = ^(AlfrescoProfileConfig *selectedProfile, BOOL isEmbeddedConfig) {
                    self.currentConfigService = configService;
                    self.selectedProfile = selectedProfile;
                    self.currentConfigAccountIdentifier = account.accountIdentifier;
                    account.selectedProfileIdentifier = selectedProfile.identifier;
                    account.selectedProfileName = selectedProfile.label;
                    
                    MainMenuConfigurationBuilder *builder;
                    if(isEmbeddedConfig)
                    {
                        builder = [[MainMenuLocalConfigurationBuilder alloc] initWithAccount:account session:session];
                    }
                    else
                    {
                        builder = [[MainMenuRemoteConfigurationBuilder alloc] initWithAccount:account session:session];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigFileDidUpdateNotification object:builder userInfo:@{kAppConfigurationUserCanEditMainMenuKey : [NSNumber numberWithBool:isEmbeddedConfig]}];
                };
                
                NSString *selectedProfileIdentifier = account.selectedProfileIdentifier;
                if (selectedProfileIdentifier)
                {
                    [configService retrieveProfileWithIdentifier:selectedProfileIdentifier completionBlock:^(AlfrescoProfileConfig *identifierProfile, NSError *identifierError) {
                        if (identifierError || identifierProfile == nil)
                        {
                            AlfrescoLogWarning(@"Could not retrieve the profile with identifier: %@ from server: %@", selectedProfileIdentifier, identifierError.localizedDescription);
                            [configService retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *defaultServerProfile, NSError *defaultServerProfileError) {
                                if (defaultServerProfileError)
                                {
                                    AlfrescoLogWarning(@"Could not retrieve the default profile from server: %@", defaultServerProfileError.localizedDescription);
                                    if(defaultServerProfileError.code == kAlfrescoErrorCodeRequestedNodeNotFound)
                                    {
                                        // something happened with the configuration as it is not found; will load the embedded configuration
                                        AppConfigurationManager *appConfigM = [AppConfigurationManager resetInstanceAndReturnManager];
                                        appConfigM.configurationServiceForCurrentAccount.session = session;
                                        appConfigM.session = session;
                                        [appConfigM.configurationServiceForCurrentAccount retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *config, NSError *error) {
                                            if (defaultProfileError)
                                            {
                                                AlfrescoLogWarning(@"Could not retrieve the default profile: %@", defaultProfileError.localizedDescription);
                                            }
                                            else
                                            {
                                                profileSuccessfullySelectedBlock(defaultProfile, YES);
                                            }
                                        }];
                                    }
                                }
                                else
                                {
                                    profileSuccessfullySelectedBlock(defaultServerProfile, NO);
                                }
                            }];
                        }
                        else
                        {
                            profileSuccessfullySelectedBlock(identifierProfile, NO);
                        }
                    }];
                }
                else
                {
                    [configService retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *defaultServerProfile, NSError *defaultServerProfileError) {
                        if (defaultServerProfileError)
                        {
                            AlfrescoLogWarning(@"Could not retrieve the default profile from server config: %@", defaultServerProfileError.localizedDescription);
                            if(defaultServerProfileError.code == kAlfrescoErrorCodeRequestedNodeNotFound)
                            {
                                // something happened with the configuration as it is not found; will load the embedded configuration
                                AppConfigurationManager *appConfigM = [AppConfigurationManager resetInstanceAndReturnManager];
                                appConfigM.configurationServiceForCurrentAccount.session = session;
                                appConfigM.session = session;
                                [appConfigM.configurationServiceForCurrentAccount retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *config, NSError *error) {
                                    if (defaultProfileError)
                                    {
                                        AlfrescoLogWarning(@"Could not retrieve the default profile: %@", defaultProfileError.localizedDescription);
                                    }
                                    else
                                    {
                                        profileSuccessfullySelectedBlock(defaultProfile, YES);
                                    }
                                }];
                            }
                        }
                        else
                        {
                            profileSuccessfullySelectedBlock(defaultServerProfile, NO);
                        }
                    }];
                }
            }
        }
    }];
}

- (void)accountRemoved:(NSNotification *)notification
{
    UserAccount *accountRemoved = notification.object;
    AlfrescoConfigService *configService = [self configurationServiceForAccount:accountRemoved];
    configService.session = nil;
    [configService clear];
    
    if([self.currentConfigAccountIdentifier isEqualToString:accountRemoved.accountIdentifier])
    {
        self.currentConfigAccountIdentifier = nil;
        self.selectedProfile = nil;
        self.session = nil;
    }
}

- (void)noMoreAccounts:(NSNotification *)notification
{
    self.currentConfigService = self.noAccountConfigService;
    [AppConfigurationManager resetInstanceAndReturnManager];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigFileDidUpdateNotification object:nil userInfo:nil];
}

- (void)configurationFileUpdatedFromServer:(NSNotificationCenter *)notification
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        displayInformationMessageWithTitle(NSLocalizedString(@"configuration.manager.configuration.file.updated.title", @"Updated Message Text"), NSLocalizedString(@"configuration.manager.configuration.file.updated.message", @"Updated Title Text"));
    });
}

- (void)selectedProfileDidChange:(NSNotification *)notification
{
    UserAccount *changedAccount = notification.userInfo[kAlfrescoConfigProfileDidChangeForAccountKey];
    if ([changedAccount.accountIdentifier isEqualToString:[AccountManager sharedManager].selectedAccount.accountIdentifier])
    {
        self.selectedProfile = notification.object;
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigShouldUpdateMainMenuNotification object:nil];
    }
}

#pragma mark - Private Methods

- (NSString *)accountSpecificConfigurationFolderPath:(UserAccount *)account
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *accountIdentifier = account.accountIdentifier;
    NSString *accountSpecificFolderPath = [[fileManager defaultConfigurationFolderPath] stringByAppendingPathComponent:accountIdentifier];
    
    if (![fileManager fileExistsAtPath:accountSpecificFolderPath])
    {
        NSError *createError = nil;
        [fileManager createDirectoryAtPath:accountSpecificFolderPath withIntermediateDirectories:YES attributes:nil error:&createError];
        
        if (createError)
        {
            AlfrescoLogError(@"Unable to create folder at path: %@", accountSpecificFolderPath);
        }
    }
    
    return accountSpecificFolderPath;
}

- (void)setupConfigurationFileFromBundleIfRequiredWithCompletionBlock:(void (^)(NSString *configurationFilePath))completionBlock
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    
    // File location to the configuration file
    BOOL areThereAccounts = ([AccountManager sharedManager].allAccounts.count > 0) || ([AccountManager sharedManager].selectedAccount != nil);
    
    NSString *completeDestinationPath = areThereAccounts ? [self filePathForEmbeddedConfigurationFile] : [self filePathForNoAccountsConfigurationFile];

    if (![fileManager fileExistsAtPath:completeDestinationPath])
    {
        NSString *configFileName = areThereAccounts ? kAlfrescoEmbeddedConfigurationFileName : kAlfrescoNoAccountConfigurationFileName;
        
        NSString *fileLocationInBundle = [[NSBundle mainBundle] pathForResource:configFileName.stringByDeletingPathExtension ofType:configFileName.pathExtension];
        NSError *copyError = nil;

        [fileManager copyItemAtPath:fileLocationInBundle toPath:completeDestinationPath error:&copyError];
        
        if (copyError)
        {
            AlfrescoLogError(@"Unable to copy file from path: %@, to path: %@", fileLocationInBundle, completeDestinationPath);
        }
    }
    
    if (completionBlock != NULL)
    {
        completionBlock(completeDestinationPath);
    }
}

- (NSString *)filePathForEmbeddedConfigurationFile
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    return [[fileManager defaultConfigurationFolderPath] stringByAppendingPathComponent:kAlfrescoEmbeddedConfigurationFileName];
}

- (NSString *)filePathForNoAccountsConfigurationFile
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    return [[fileManager defaultConfigurationFolderPath] stringByAppendingPathComponent:kAlfrescoNoAccountConfigurationFileName];
}

@end

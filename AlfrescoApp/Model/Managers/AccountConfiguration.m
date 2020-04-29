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

#import "AccountConfiguration.h"
#import "AlfrescoConfigService.h"
#import "MainMenuLocalConfigurationBuilder.h"
#import "MainMenuRemoteConfigurationBuilder.h"
#import "UserAccount+FileHandling.h"
#import "ConnectivityManager.h"

@interface AccountConfiguration ()

@property (nonatomic, strong) AlfrescoConfigService *embeddedConfigService;
@property (nonatomic, strong) AlfrescoConfigService *localConfigService;
@property (nonatomic, strong) AlfrescoConfigService *serverConfigService;

@end

@implementation AccountConfiguration

#pragma mark - Init Methods

- (instancetype)initWithAccount:(UserAccount *)account session:(id<AlfrescoSession>)session
{
    if (self = [super init])
    {
        self.account = account;
        self.session = session;
        
        [ConfigurationFilesUtils setupConfigurationFileType:ConfigurationFileTypeEmbedded completionBlock:^(NSString *configurationFilePath) {
            NSDictionary *parameters = @{kAlfrescoConfigServiceParameterFolder: configurationFilePath.stringByDeletingLastPathComponent,
                                         kAlfrescoConfigServiceParameterFileName: configurationFilePath.lastPathComponent};
            self.embeddedConfigService = [[AlfrescoConfigService alloc] initWithDictionary:parameters];
            self.embeddedConfigService.shouldIgnoreRequests = YES;
            self.configService = self.embeddedConfigService;
            
            if ([account serverConfigurationExists])
            {
                NSDictionary *parameters = [self configServiceParametersForCurrentAccount];
                
                if (self.localConfigService == nil)
                {
                    self.localConfigService = [[AlfrescoConfigService alloc] initWithDictionary:parameters];
                }
                self.configService = self.localConfigService;
            }
        }];
    }
    
    return self;
}

- (instancetype)initWithNoAccounts
{
    if (self = [super init])
    {
        [ConfigurationFilesUtils setupConfigurationFileType:ConfigurationFileTypeNoAccounts completionBlock:^(NSString *configurationFilePath) {
            NSDictionary *noAccountParameters = @{kAlfrescoConfigServiceParameterFolder:configurationFilePath.stringByDeletingLastPathComponent,
                                                  kAlfrescoConfigServiceParameterFileName: kAlfrescoNoAccountConfigurationFileName};
            self.configService = [[AlfrescoConfigService alloc] initWithDictionary:noAccountParameters];
        }];
    }
    
    return self;
}

#pragma mark - Custom Accessors

- (void)setSession:(id<AlfrescoSession>)session
{
    _session = session;
    
    if (session == nil)
    {
        if ([self.account serverConfigurationExists])
        {
            NSDictionary *parameters = [self configServiceParametersForCurrentAccount];
            
            if (self.localConfigService == nil)
            {
                self.localConfigService = [[AlfrescoConfigService alloc] initWithDictionary:parameters];
            }
            self.configService = self.localConfigService;
        }
        else
        {
            self.configService = self.embeddedConfigService;
        }
    }
}

#pragma mark - Public Methods

- (void)install
{
    if (self.account == nil)
    {
        [self loadNoAccountsConfigurationWithCompletionBlock:^{
            [[AnalyticsManager sharedManager] checkAnalyticsFeature];
        }];
    }
    else
    {
        ConfigurationFileType configurationFileType = [self.account serverConfigurationExists] ? ConfigurationFileTypeLocal : ConfigurationFileTypeEmbedded;
        
        [self loadConfigurationFileType:configurationFileType completionBlock:^{
            [[AnalyticsManager sharedManager] checkAnalyticsFeature];
            if (![self.session isKindOfClass:[AlfrescoCloudSession class]] && [ConnectivityManager sharedManager].hasInternetConnection)
            {
                self.serverConfigService = [[AlfrescoConfigService alloc] initWithSession:self.session];
                [self loadConfigurationFileType:ConfigurationFileTypeServer completionBlock:nil];
            }
        }];
    }
}

- (void)switchToConfigurationFileType:(ConfigurationFileType)configurationFileType
{
    switch (configurationFileType)
    {
        case ConfigurationFileTypeLocal:
            self.configService = self.localConfigService;
            break;
            
        case ConfigurationFileTypeServer:
            [self.serverConfigService clear];
            self.configService = self.serverConfigService;
            break;
            
        case ConfigurationFileTypeEmbedded:
            self.configService = self.embeddedConfigService;
            break;
            
        default:
            break;
    }
}

- (void)retrieveProfilesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self.configService retrieveProfilesWithCompletionBlock:^(NSArray *profilesArray, NSError *profilesError) {
        
        if (completionBlock)
        {
            completionBlock(profilesArray, profilesError);
        }
    }];
}

- (void)retrieveDefaultProfileWithCompletionBlock:(AlfrescoProfileConfigCompletionBlock)completionBlock
{
    [self.configService retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *config, NSError *error) {
        if (completionBlock)
        {
            completionBlock(config, error);
        }
    }];
}

- (BOOL)isEmbeddedConfigurationLoaded
{
    return self.configService == self.embeddedConfigService;
}

#pragma mark - Private Methods

- (void)profileSuccessfullySelected:(AlfrescoProfileConfig *)selectedProfile isEmbeddedConfig:(BOOL)isEmbeddedConfig configService:(AlfrescoConfigService *)configService
{
    self.configService = configService;
    self.selectedProfile = selectedProfile;
    self.account.selectedProfileIdentifier = selectedProfile.identifier;
    self.account.selectedProfileName = selectedProfile.label;

    MainMenuConfigurationBuilder *builder;
    if(isEmbeddedConfig)
    {
        builder = [[MainMenuLocalConfigurationBuilder alloc] initWithAccount:self.account session:self.session];
    }
    else
    {
        builder = [[MainMenuRemoteConfigurationBuilder alloc] initWithAccount:self.account session:self.session];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigFileDidUpdateNotification object:builder userInfo:@{kAppConfigurationUserCanEditMainMenuKey : @(isEmbeddedConfig)}];

    [[AnalyticsManager sharedManager] checkAnalyticsFeature];
}

- (void)loadConfigurationFileType:(ConfigurationFileType)configurationFileType completionBlock:(void (^)(void))completionBlock
{
    AlfrescoConfigService *service = [self configServiceForType:configurationFileType];
    service.shouldIgnoreRequests = [ConfigurationFilesUtils configServiceShouldIgnoreRequestsForType:configurationFileType];
    service.session = self.session;
    
    NSString *selectedProfileIdentifier = self.account.selectedProfileIdentifier;
    
    void (^loadServerOrLocalDefaultProfile)(void) = ^void(){
        [service retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *config, NSError *error) {
            if (error)
            {
                if (configurationFileType == ConfigurationFileTypeServer)
                {
                    // If the node is not found on the server, delete configuration.json from user's folder.
                    [self.account deleteConfigurationFile];
                }
                
                [ConfigurationFilesUtils logDefaultProfileError:error forConfigurationWithType:configurationFileType];
                [self loadEmbeddedConfigurationWithCompletionBlock:completionBlock];
            }
            else
            {
                [self profileSuccessfullySelected:config isEmbeddedConfig:NO configService:service];
            }
            
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    };
    
    if (self.session)
    {
        if (configurationFileType == ConfigurationFileTypeServer)
        {
            NSDictionary *parameters = [self configServiceParametersForCurrentAccount];
            [service.session addParametersFromDictionary:parameters];
        }
        
        if (configurationFileType == ConfigurationFileTypeLocal || configurationFileType == ConfigurationFileTypeServer)
        {
            if (selectedProfileIdentifier)
            {
                [service retrieveProfileWithIdentifier:selectedProfileIdentifier completionBlock:^(AlfrescoProfileConfig *identifierProfile, NSError *identifierError) {
                    if (identifierError || identifierProfile == nil)
                    {
                        [ConfigurationFilesUtils logCustomProfile:selectedProfileIdentifier error:identifierError];
                        loadServerOrLocalDefaultProfile();
                    }
                    else
                    {
                        [self profileSuccessfullySelected:identifierProfile isEmbeddedConfig:NO configService:service];
                        
                        if (completionBlock)
                        {
                            completionBlock();
                        }
                    }
                }];
            }
            else
            {
                loadServerOrLocalDefaultProfile();
            }
        }
        else if (configurationFileType == ConfigurationFileTypeEmbedded)
        {
            [self loadEmbeddedConfigurationWithCompletionBlock:completionBlock];
        }
    }
    else // no session, offline
    {
        if (selectedProfileIdentifier)
        {
            [service retrieveProfileWithIdentifier:selectedProfileIdentifier completionBlock:^(AlfrescoProfileConfig *identifierProfile, NSError *identifierError) {
                if (identifierError || identifierProfile == nil)
                {
                    [ConfigurationFilesUtils logCustomProfile:selectedProfileIdentifier error:identifierError];
                    
                    if (configurationFileType == ConfigurationFileTypeLocal)
                    {
                        [self loadEmbeddedConfigurationWithCompletionBlock:completionBlock];
                    }
                }
                else
                {
                    [self profileSuccessfullySelected:identifierProfile isEmbeddedConfig:NO configService:service];
                    
                    if (completionBlock)
                    {
                        completionBlock();
                    }
                }
            }];
        }
        else
        {
            loadServerOrLocalDefaultProfile();
        }
    }
}

- (void)loadEmbeddedConfigurationWithCompletionBlock:(void (^)(void))completionBlock
{
    [self.embeddedConfigService clear];
    [self.embeddedConfigService retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *config, NSError *error) {
        if (error)
        {
            [ConfigurationFilesUtils logDefaultProfileError:error forConfigurationWithType:ConfigurationFileTypeEmbedded];
        }
        else
        {
            [self profileSuccessfullySelected:config isEmbeddedConfig:YES configService:self.embeddedConfigService];
        }
        
        if (completionBlock)
        {
            completionBlock();
        }
    }];
}

- (void)loadNoAccountsConfigurationWithCompletionBlock:(void (^)(void))completionBlock
{
    [self.configService retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *defaultProfile, NSError *defaultProfileError) {
        if (defaultProfileError)
        {
            [ConfigurationFilesUtils logDefaultProfileError:defaultProfileError forConfigurationWithType:ConfigurationFileTypeNoAccounts];
        }
        else
        {
            self.selectedProfile = defaultProfile;
        }
        
        if (completionBlock)
        {
            completionBlock();
        }
    }];
}

- (AlfrescoConfigService *)configServiceForType:(ConfigurationFileType)configurationFileType
{
    AlfrescoConfigService *service = nil;
    
    switch (configurationFileType)
    {
        case ConfigurationFileTypeEmbedded:
            service = self.embeddedConfigService;
            break;
            
        case ConfigurationFileTypeLocal:
            service = self.localConfigService;
            break;
            
        case ConfigurationFileTypeServer:
            service = self.serverConfigService;
            break;
            
        default:
            break;
    }
    
    return service;
}

- (NSDictionary *)configServiceParametersForCurrentAccount
{
    // Create the local path to store the configuration file
    NSString *accountConfigurationFolderPath = [self.account accountSpecificConfigurationFolderPath];
    
    // Add parameters to the session
    NSDictionary *parameters = @{kAlfrescoConfigServiceParameterFolder : accountConfigurationFolderPath,
                                 kAlfrescoConfigServiceParameterFileName : kAlfrescoEmbeddedConfigurationFileName};
    
    return parameters;
}

@end

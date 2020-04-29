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
 
#import "AppConfigurationManager.h"
#import "AccountManager.h"
#import "UserAccount+FileHandling.h"

@interface AppConfigurationManager ()

@property (nonatomic, strong) NSMutableDictionary *configurations;
@property (nonatomic, strong) AccountConfiguration *activeAccountConfiguration;
@property (nonatomic, strong) AccountConfiguration *noAccountsConfiguration;
@property (nonatomic) BOOL badConfigMessageDisplayed;

@end

#define kNoAccountsConfigurationKey @"kNoAccountsConfigurationKey"

@implementation AppConfigurationManager

+ (instancetype)sharedManager
{
    static AppConfigurationManager *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppConfigurationManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.configurations = [NSMutableDictionary dictionary];
        
        [self registerForNotifications];
        [self createInitialAccountConfiguration];
    }
    
    return self;
}

- (void)createInitialAccountConfiguration
{
    BOOL thereAreAccounts = [AccountManager sharedManager].allAccounts.count > 0;
    UserAccount *activeAccount = [AccountManager sharedManager].selectedAccount;
    AccountConfiguration *currentAccountConfiguration = nil;
    
    if(thereAreAccounts && activeAccount)
    {
        self.activeAccountConfiguration = [[AccountConfiguration alloc] initWithAccount:activeAccount session:nil];
        self.configurations[activeAccount.accountIdentifier] = self.activeAccountConfiguration;
        currentAccountConfiguration = self.activeAccountConfiguration;
    }
    else
    {
        self.noAccountsConfiguration = [[AccountConfiguration alloc] initWithNoAccounts];
        self.configurations[kNoAccountsConfigurationKey] = self.noAccountsConfiguration;
        currentAccountConfiguration = self.noAccountsConfiguration;
    }
    
    [currentAccountConfiguration install];
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionRefreshedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noMoreAccounts:) name:kAlfrescoAccountsListEmptyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configurationFileUpdatedFromServer:) name:kAlfrescoConfigNewConfigRetrievedFromServerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configurationFileUpdatedFromServer:) name:kAlfrescoConfigBadConfigRetrievedFromServerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedProfileDidChange:) name:kAlfrescoConfigProfileDidChangeNotification object:nil];
}

#pragma mark - Notifications Handlers

- (void)sessionReceived:(NSNotification *)notification
{
    self.badConfigMessageDisplayed = NO;
    
    UserAccount *activeAccount = [AccountManager sharedManager].selectedAccount;
    if(activeAccount)
    {
        id<AlfrescoSession> session = notification.object;
        
        AccountConfiguration *activeAccountConfiguration = self.configurations[activeAccount.accountIdentifier];
        
        [self.configurations enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, AccountConfiguration * _Nonnull configuration, BOOL * _Nonnull stop) {
            if (![key isEqualToString:kNoAccountsConfigurationKey] && ![activeAccount.accountIdentifier isEqualToString:key])
            {
                configuration.session = nil;
                configuration.configService.session = nil;
            }
        }];
        
        if (activeAccountConfiguration == nil)
        {
            activeAccountConfiguration = [[AccountConfiguration alloc] initWithAccount:activeAccount session:session];
            self.configurations[activeAccount.accountIdentifier] = activeAccountConfiguration;
        }
        else
        {
            activeAccountConfiguration.session = session;
        }
        
        self.activeAccountConfiguration = activeAccountConfiguration;
        [self.activeAccountConfiguration install];
    }
}

- (void)accountRemoved:(NSNotification *)notification
{
    UserAccount *accountRemoved = notification.object;
    
    NSString *selectedAccountIdentifier = [AccountManager sharedManager].selectedAccount.accountIdentifier;
    NSString *accountRemovedIdentifier = accountRemoved.accountIdentifier;
    
    if ([selectedAccountIdentifier isEqualToString:accountRemovedIdentifier])
    {
        self.activeAccountConfiguration = nil;
    }
    
    // Delete account configuration folder.
    [accountRemoved deleteSpecificConfigurationFolder];
    
    // Delete account sync folder
    [accountRemoved deleteSpecificSyncFolder];
    
    [[AnalyticsManager sharedManager] checkAnalyticsFeature];
}

- (void)noMoreAccounts:(NSNotification *)notification
{
    if (self.noAccountsConfiguration == nil)
    {
        self.noAccountsConfiguration = [[AccountConfiguration alloc] initWithNoAccounts];
    }
    
    [self.noAccountsConfiguration install];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigFileDidUpdateNotification object:nil userInfo:nil];
}

- (void)configurationFileUpdatedFromServer:(NSNotification *)notification
{
    if ([notification.name isEqualToString:kAlfrescoConfigBadConfigRetrievedFromServerNotification])
    {
        NSError *error = notification.object;
        
        if (error)
        {
            if(error.code == kAlfrescoErrorCodeJSONParsing)
            {
                if (self.badConfigMessageDisplayed == NO)
                {
                    self.badConfigMessageDisplayed = YES;
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        NSString *parsingErrorString = NSLocalizedString(@"configuration.manager.configuration.file.error.parse.message", @"The configuration file couldn’t be loaded.");
                        displayErrorMessage(parsingErrorString);
                    });
                }
            }
        }
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            displayInformationMessageWithTitle(NSLocalizedString(@"configuration.manager.configuration.file.updated.title", @"Updated Message Text"), NSLocalizedString(@"configuration.manager.configuration.file.updated.message", @"Updated Title Text"));
        });
    }
}

- (void)selectedProfileDidChange:(NSNotification *)notification
{
    UserAccount *changedAccount = notification.userInfo[kAlfrescoConfigProfileDidChangeForAccountKey];
    if ([changedAccount.accountIdentifier isEqualToString:[AccountManager sharedManager].selectedAccount.accountIdentifier])
    {
        AccountConfiguration *configuration = self.configurations[changedAccount.accountIdentifier];
        configuration.selectedProfile = notification.object;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigShouldUpdateMainMenuNotification object:nil];
    }
}

#pragma mark - Public Methods

- (AccountConfiguration *)accountConfigurationForAccount:(UserAccount *)account
{
    AccountConfiguration *accountConfiguration = nil;
    
    if (account.accountIdentifier == nil)
    {
        accountConfiguration = self.noAccountsConfiguration;
    }
    else
    {
        if (self.configurations[account.accountIdentifier])
        {
            accountConfiguration = self.configurations[account.accountIdentifier];
        }
        else
        {
            accountConfiguration = [[AccountConfiguration alloc] initWithAccount:account session:nil];
            self.configurations[account.accountIdentifier] = accountConfiguration;
        }
    }
    
    return accountConfiguration;
}

- (AlfrescoConfigService *)configurationServiceForNoAccountConfiguration
{
    return self.noAccountsConfiguration.configService;
}

- (AlfrescoConfigService *)configurationServiceForCurrentAccount
{
    return [self configurationServiceForAccount:[AccountManager sharedManager].selectedAccount];
}

- (AlfrescoConfigService *)configurationServiceForAccount:(UserAccount *)account
{
    AlfrescoConfigService *configService = nil;
    
    if (account == nil)
    {
        configService = [self configurationServiceForNoAccountConfiguration];
    }
    else
    {
        AccountConfiguration *accountConfiguration = [self accountConfigurationForAccount:account];
        
        if (accountConfiguration)
        {
            configService = accountConfiguration.configService;
        }
        else
        {
            configService = [self configurationServiceForNoAccountConfiguration];
        }
    }
    
    return configService;
}

- (AlfrescoProfileConfig *)selectedProfileForAccount:(UserAccount *)account
{
    AlfrescoProfileConfig *profileConfig = nil;
    
    if (account == self.activeAccountConfiguration.account)
    {
        profileConfig = self.activeAccountConfiguration.selectedProfile;
    }
    
    return profileConfig;
}

@end

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

#import "MainMenuConfigurationBuilder.h"
#import "AlfrescoConfigService.h"
#import "ActivitiesViewController.h"
#import "FileFolderListViewController.h"
#import "SitesListViewController.h"
#import "DownloadsViewController.h"
#import "SyncViewController.h"
#import "TaskViewController.h"
#import "NavigationViewController.h"
#import "AccountsViewController.h"
#import "SettingsViewController.h"
#import "WebBrowserViewController.h"
#import "AppConfigurationManager.h"
#import "AccountManager.h"

static NSString * const kIconMappingFileName = @"MenuIconMappings";

@interface MainMenuConfigurationBuilder ()
@end

@implementation MainMenuConfigurationBuilder

- (instancetype)initWithAccount:(UserAccount *)account session:(id<AlfrescoSession>)session;
{
    self = [super initWithAccount:account];
    if (self)
    {
        self.configService = [[AppConfigurationManager sharedManager] configurationServiceForAccount:account];
        self.session = session;
    }
    return self;
}

#pragma mark - Public Methods

- (void)sectionsForHeaderGroupWithCompletionBlock:(void (^)(NSArray *))completionBlock
{
    // Accounts Menu Item
    AccountsViewController *accountsController = [[AccountsViewController alloc] initWithSession:self.session];
    NavigationViewController *accountsNavigationController = [[NavigationViewController alloc] initWithRootViewController:accountsController];
    MainMenuItem *accountsItem = [MainMenuItem itemWithIdentifier:kAlfrescoMainMenuItemAccountsIdentifier
                                                            title:NSLocalizedString(@"accounts.title", @"Accounts")
                                                            image:[[UIImage imageNamed:@"mainmenu-alfresco.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                      description:nil
                                                  displayType:MainMenuDisplayTypeMaster
                                                 associatedObject:accountsNavigationController];
    
    // Create the accounts section
    MainMenuSection *accountsSection = [MainMenuSection sectionItemWithTitle:nil sectionItems:@[accountsItem]];
    
    completionBlock(@[accountsSection]);
}

- (void)sectionsForContentGroupWithCompletionBlock:(void (^)(NSArray *))completionBlock
{
    AppConfigurationManager *configManager = [AppConfigurationManager sharedManager];

    void (^buildItemsForProfile)(AlfrescoProfileConfig *profile) = ^(AlfrescoProfileConfig *profile) {
        [self.configService retrieveViewGroupConfigWithIdentifier:profile.rootViewId completionBlock:^(AlfrescoViewGroupConfig *rootViewConfig, NSError *rootViewError) {
            if (rootViewError)
            {
                AlfrescoLogError(@"Could not retrieve root config for profile %@", profile.rootViewId);
            }
            else
            {
                NSLog(@"ViewGroupConfig: %@", rootViewConfig.identifier);
                
                [self buildSectionsForRootView:rootViewConfig completionBlock:completionBlock];
            }
        }];
    };
    
    if (self.account == [AccountManager sharedManager].selectedAccount)
    {
        buildItemsForProfile(configManager.selectedProfile);
    }
    else
    {
        [self.configService retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *defaultConfig, NSError *defaultConfigError) {
            if (defaultConfigError)
            {
                AlfrescoLogError(@"Could not retrieve root config for profile %@", defaultConfig.rootViewId);
            }
            else
            {
                buildItemsForProfile(defaultConfig);
            }
        }];
    }
}

- (void)sectionsForFooterGroupWithCompletionBlock:(void (^)(NSArray *))completionBlock
{
    // Settings Menu Item
    SettingsViewController *settingsController = [[SettingsViewController alloc] initWithSession:self.session];
    NavigationViewController *settingNavigationController = [[NavigationViewController alloc] initWithRootViewController:settingsController];
    MainMenuItem *settingsItem = [MainMenuItem itemWithIdentifier:kAlfrescoMainMenuItemSettingsIdentifier
                                                            title:NSLocalizedString(@"settings.title", @"Settings")
                                                            image:[[UIImage imageNamed:@"mainmenu-settings.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                      description:nil
                                                      displayType:MainMenuDisplayTypeModal
                                                 associatedObject:settingNavigationController];
    
    // Help Menu Item
    NSString *helpURLString = [NSString stringWithFormat:kAlfrescoHelpURLString, [Utility helpURLLocaleIdentifierForAppLocale]];
    NSString *fallbackURLString = [NSString stringWithFormat:kAlfrescoHelpURLString, [Utility helpURLLocaleIdentifierForLocale:kAlfrescoISO6391EnglishCode]];
    WebBrowserViewController *helpViewController = [[WebBrowserViewController alloc] initWithURLString:helpURLString
                                                                              initialFallbackURLString:fallbackURLString
                                                                                          initialTitle:NSLocalizedString(@"help.title", @"Help Title")
                                                                                 errorLoadingURLString:nil];
    NavigationViewController *helpNavigationController = [[NavigationViewController alloc] initWithRootViewController:helpViewController];
    MainMenuItem *helpItem = [MainMenuItem itemWithIdentifier:kAlfrescoMainMenuItemHelpIdentifier
                                                        title:NSLocalizedString(@"help.title", @"Help")
                                                        image:[[UIImage imageNamed:@"mainmenu-help.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                  description:nil
                                                  displayType:MainMenuDisplayTypeModal
                                             associatedObject:helpNavigationController];
    
    // Create the section
    MainMenuSection *footerSection = [MainMenuSection sectionItemWithTitle:nil sectionItems:@[settingsItem, helpItem]];
    
    completionBlock(@[footerSection]);
}

#pragma mark - Private Methods

- (void)buildSectionsForRootView:(AlfrescoViewGroupConfig *)rootView completionBlock:(void (^)(NSArray *sections))completionBlock
{
    NSMutableArray *sections = [NSMutableArray array];
//    MainMenuSection *newSection = [[MainMenuSection alloc] initWithTitle:nil sectionItems:nil];
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:kIconMappingFileName ofType:@"plist"];
    NSDictionary *iconMappings = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    [self buildSectionsForRootView:rootView section:nil sectionArray:sections iconLookupDictionary:iconMappings completionBlock:completionBlock];
}

- (void)buildSectionsForRootView:(AlfrescoViewGroupConfig *)rootView
                         section:(MainMenuSection *)section
                    sectionArray:(NSMutableArray *)sectionArray
            iconLookupDictionary:(NSDictionary *)iconLookup
                 completionBlock:(void (^)(NSArray *sections))completionBlock
{
    for (AlfrescoItemConfig *subItem in rootView.items)
    {
        if ([subItem isKindOfClass:[AlfrescoViewGroupConfig class]])
        {
            // Recursively build the views from the view groups
            [self.configService retrieveViewGroupConfigWithIdentifier:subItem.identifier completionBlock:^(AlfrescoViewGroupConfig *groupConfig, NSError *groupConfigError) {
                if (groupConfigError)
                {
                    AlfrescoLogError(@"Unable to retrieve view group for identifier: %@. Error: %@", subItem.identifier, groupConfigError.localizedDescription);
                }
                else
                {
                    MainMenuSection *newSection = [[MainMenuSection alloc] initWithTitle:groupConfig.label sectionItems:nil];
                    [self buildSectionsForRootView:groupConfig section:newSection sectionArray:sectionArray iconLookupDictionary:iconLookup completionBlock:completionBlock];
                }
            }];
        }
        else if ([subItem isKindOfClass:[AlfrescoViewConfig class]])
        {
            if (!section)
            {
                section = [[MainMenuSection alloc] initWithTitle:subItem.label sectionItems:nil];
            }
            
            // define a block
            void (^createMenuItem)(AlfrescoViewConfig *subItem) = ^(AlfrescoViewConfig *subItem) {
                NSString *bundledIconName = iconLookup[subItem.identifier];
                bundledIconName = (bundledIconName) ?: @"mainmenu-help.png";
                id associatedObject = [self associatedObjectForAlfrescoViewConfig:(AlfrescoViewConfig *)subItem];
                MainMenuItem *item = [[MainMenuItem alloc] initWithIdentifier:subItem.identifier
                                                                        title:(subItem.label) ?: NSLocalizedString(subItem.identifier, @"Item Title")
                                                                        image:[[UIImage imageNamed:bundledIconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                  description:nil
                                                                  displayType:MainMenuDisplayTypeMaster
                                                             associatedObject:associatedObject];
                [section addMainMenuItem:item];
            };
            
            // For some reason there seems to be inline view definition in the embeded JSON configuration file
            // Not sure if this is documented behaviour?
            // Determine if a view retrieval is required
            if (![subItem.type isEqualToString:@"view-id"])
            {
                createMenuItem((AlfrescoViewConfig *)subItem);
            }
            else
            {
                // Retrieve the view using the view identifier
                [self.configService retrieveViewConfigWithIdentifier:subItem.identifier completionBlock:^(AlfrescoViewConfig *viewConfig, NSError *viewConfigError) {
                    if (viewConfigError)
                    {
                        AlfrescoLogError(@"Unable to retrieve view for identifier: %@. Error: %@", subItem.identifier, viewConfigError.localizedDescription);
                    }
                    else
                    {
                        createMenuItem((AlfrescoViewConfig *)subItem);
                    }
                }];
            }
        }
        
    }
    
    // Add the section to the sections array
    if (section)
    {
        [sectionArray addObject:section];
    }
    
    if (completionBlock != NULL)
    {
        completionBlock(sectionArray);
    }
}

- (id)associatedObjectForAlfrescoViewConfig:(AlfrescoViewConfig *)viewConfig
{
    id associatedObject = nil;
    
    if ([viewConfig.type isEqualToString:kAlfrescoMainMenuConfigurationViewTypeActivities])
    {
        // activities
        ActivitiesViewController *activityListViewController = [[ActivitiesViewController alloc] initWithSession:self.session];
        associatedObject = activityListViewController;
    }
    else if ([viewConfig.type isEqualToString:kAlfrescoMainMenuConfigurationViewTypeRepository])
    {
        // file folder
        FileFolderListViewController *fileFolderListViewController = [[FileFolderListViewController alloc] initWithFolder:nil folderDisplayName:nil session:self.session];
        associatedObject = fileFolderListViewController;
    }
    else if ([viewConfig.type isEqualToString:kAlfrescoMainMenuConfigurationViewTypeSiteBrowser])
    {
        // sites
        SitesListViewController *sitesListViewController = [[SitesListViewController alloc] initWithSession:self.session];
        associatedObject = sitesListViewController;
    }
    else if ([viewConfig.type isEqualToString:kAlfrescoMainMenuConfigurationViewTypeTasks])
    {
        // tasks
        TaskViewController *taskListViewController = [[TaskViewController alloc] initWithSession:self.session];
        associatedObject = taskListViewController;
    }
    else if ([viewConfig.type isEqualToString:kAlfrescoMainMenuConfigurationViewTypeFavourites])
    {
        // sync
        SyncViewController *syncViewController = [[SyncViewController alloc] initWithSession:self.session];
        associatedObject = syncViewController;
    }
    else if ([viewConfig.type isEqualToString:kAlfrescoMainMenuConfigurationViewTypeLocal])
    {
        // local
        DownloadsViewController *localFilesViewController = [[DownloadsViewController alloc] initWithSession:self.session];
        associatedObject = localFilesViewController;
    }
    
    // If it's nil, use an empty controller in order to stop a runtime error
    if (!associatedObject)
    {
        associatedObject = [[UIViewController alloc] init];
    }
    
    NavigationViewController *navigationController = [[NavigationViewController alloc] initWithRootViewController:associatedObject];
    
    return navigationController;
}

@end

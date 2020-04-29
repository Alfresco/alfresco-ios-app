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

#import "ProfileSelectionViewController.h"
#import "AlfrescoConfigService.h"
#import "AppConfigurationManager.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "MainMenuItemsVisibilityUtils.h"
#import "ConfigurationFilesUtils.h"
#import "UserAccount+FileHandling.h"
#import "AlfrescoClientBasedConfigService.h"

static NSString * const kProfileCellIdentifier = @"ProfileCellIdentifier";

@interface ProfileSelectionViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *tableViewData;
@property (nonatomic, strong) NSString *originallySelectedProfileIdentifier;
@property (nonatomic, strong) AlfrescoProfileConfig *currentlySelectedProfile;
@property (nonatomic, strong) AlfrescoConfigService *configService;
@property (nonatomic, strong) AccountConfiguration *accountConfiguration;
@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) id<AlfrescoSession> session;
@end

@implementation ProfileSelectionViewController

- (instancetype)initWithAccount:(UserAccount *)account session:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.account = account;
        self.session = session;
        self.configService = [[AppConfigurationManager sharedManager] configurationServiceForAccount:account];
        self.accountConfiguration = [[AppConfigurationManager sharedManager] accountConfigurationForAccount:account];
        self.originallySelectedProfileIdentifier = account.selectedProfileIdentifier;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"main.menu.profile.selection.title", @"Profile Title");
    
    UIBarButtonItem *saveBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveBarButton;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    
    [self loadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewAccountEditActiveProfile];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
}

- (void)save
{
    if (![self.originallySelectedProfileIdentifier isEqualToString:self.currentlySelectedProfile.identifier])
    {
        // Only show the notification if the change was for the currently selected account
        if ([[AccountManager sharedManager].selectedAccount.accountIdentifier isEqualToString:self.account.accountIdentifier])
        {
            [MainMenuItemsVisibilityUtils isViewOfType:kAlfrescoConfigViewTypeSync presentInProfile:self.currentlySelectedProfile forAccount:[AccountManager sharedManager].selectedAccount completionBlock:^(BOOL isViewPresent, NSError *error) {
                if(!error)
                {
                    if(isViewPresent)
                    {
                        [self didSelectNewProfile];
                    }
                    else
                    {
                        [self showDisableSyncAlert];
                    }
                }
            }];
        }
    }
}

- (void)showDisableSyncAlert
{
    // Prevent appearance of the alert if sync is already not available.
    if ([AccountManager sharedManager].selectedAccount.isSyncOn == NO)
    {
        [self didSelectNewProfile];
        return;
    }
    
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"action.disablesync.title", @"Disable sync?") message:NSLocalizedString(@"action.disablesync.message", @"This will disable sync") preferredStyle:UIAlertControllerStyleAlert];
    [confirmAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [confirmAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"action.disablesync.confirm", @"Confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self didSelectNewProfile];
    }]];
    
    [self presentViewController:confirmAlert animated:YES completion:nil];
}

- (void)didSelectNewProfile
{
    self.originallySelectedProfileIdentifier = self.currentlySelectedProfile.identifier;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigProfileDidChangeNotification
                                                        object:self.currentlySelectedProfile
                                                      userInfo:@{kAlfrescoConfigProfileDidChangeForAccountKey : self.account}];
    
    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySession
                                                      action:kAnalyticsEventActionSwitch
                                                       label:kAnalyticsEventLabelProfile
                                                       value:@1];
}

- (void)loadData
{
    BOOL isEmbeddedConfigurationLoaded = NO;
    
    if (self.account != [AccountManager sharedManager].selectedAccount)
    {
        if ([self.account serverConfigurationExists])
        {
            [self.accountConfiguration switchToConfigurationFileType:ConfigurationFileTypeLocal];
        }
        else
        {
            [self.accountConfiguration switchToConfigurationFileType:ConfigurationFileTypeEmbedded];
        }
    }
    else
    {
        isEmbeddedConfigurationLoaded = [self.accountConfiguration isEmbeddedConfigurationLoaded];
        [self.accountConfiguration switchToConfigurationFileType:ConfigurationFileTypeServer];
    }
    
    [self.accountConfiguration retrieveProfilesWithCompletionBlock:^(NSArray *profilesArray, NSError *profilesError) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if (profilesError || profilesArray == nil)
        {
            [self.account deleteConfigurationFile];
            [self.accountConfiguration switchToConfigurationFileType:ConfigurationFileTypeEmbedded];
            
            // Retrieve embedded profile.
            [self.accountConfiguration retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *config, NSError *error) {
                if (config)
                {
                    self.tableViewData = [NSArray arrayWithObject:config];
                    [self.tableView reloadData];
                    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

                    if (isEmbeddedConfigurationLoaded == NO)
                    {
                        [self didSelectNewProfile];
                    }
                }
                else
                {
                    self.tableViewData = [NSArray array];
                    [self.tableView reloadData];
                }
            }];
        }
        else
        {
            self.tableViewData = profilesArray;
            [self.tableView reloadData];
            BOOL shouldAutoSelectProfile = YES;
            for (int i = 0; i < self.tableViewData.count; i++)
            {
                AlfrescoProfileConfig *profile = self.tableViewData[i];
                if ([self.originallySelectedProfileIdentifier isEqualToString:profile.identifier])
                {
                    self.currentlySelectedProfile = profile;
                    
                    if (isEmbeddedConfigurationLoaded == NO)
                    {
                        shouldAutoSelectProfile = NO;
                        break;
                    }
                }
            }
            
            if (shouldAutoSelectProfile)
            {
                [self.accountConfiguration retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *config, NSError *error) {
                    for (int i = 0; i < self.tableViewData.count; i++)
                    {
                        AlfrescoProfileConfig *profile = self.tableViewData[i];
                        if ([config.identifier isEqualToString:profile.identifier])
                        {
                            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                            
                            if (isEmbeddedConfigurationLoaded)
                            {
                                [self didSelectNewProfile];
                            }
                            
                            break;
                        }
                    }
                }];
            }
            else if ([self shouldSelectNewProfile])
            {
                [self didSelectNewProfile];
            }
        }
    }];
}

- (BOOL)shouldSelectNewProfile
{
    BOOL isUsingCache = NO;
    
    AlfrescoClientBasedConfigService *service = (AlfrescoClientBasedConfigService *)self.accountConfiguration.configService;
    
    isUsingCache = [service isUsingCachedData];
    
    return !isUsingCache;
}

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kProfileCellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kProfileCellIdentifier];
    }
    
    AlfrescoProfileConfig *currentProfile = self.tableViewData[indexPath.row];
    cell.textLabel.text = NSLocalizedString(currentProfile.label, @"Localised Label");
    cell.detailTextLabel.text = NSLocalizedString(currentProfile.summary, @"Localised Summary");
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([currentProfile.identifier isEqualToString:self.originallySelectedProfileIdentifier])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        self.currentlySelectedProfile = currentProfile;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *deselectedCell = [tableView cellForRowAtIndexPath:indexPath];
    deselectedCell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    AlfrescoProfileConfig *selectedProfile = self.tableViewData[indexPath.row];
    self.currentlySelectedProfile = selectedProfile;
    
    self.navigationItem.rightBarButtonItem.enabled = ![self.originallySelectedProfileIdentifier isEqualToString:self.currentlySelectedProfile.identifier];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.account != [AccountManager sharedManager].selectedAccount)
    {
        indexPath = nil;
    }
    
    return indexPath;
}

@end

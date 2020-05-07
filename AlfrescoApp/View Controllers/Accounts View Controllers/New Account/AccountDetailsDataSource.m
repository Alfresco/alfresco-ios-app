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

#import "AccountDetailsDataSource.h"
#import "AccountDataSource+Internal.h"
#import "AlfrescoProfileConfig.h"

@implementation AccountDetailsDataSource

- (instancetype)initWithAccount:(UserAccount *)account backupAccount:(UserAccount *)backupAccount configuration:(NSDictionary *)configuration
{
    self = [super initWithAccount:account backupAccount:backupAccount configuration:configuration];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileDidChange:) name:kAlfrescoConfigProfileDidChangeNotification object:nil];
    
    return self;
}

#pragma mark - Notifications

-(void)profileDidChange:(NSNotification *)notification
{
    AlfrescoProfileConfig *selectedProfile = notification.object;
    self.profileLabel.text = selectedProfile.label;
 
    UserAccount *changedAccount = notification.userInfo[kAlfrescoConfigProfileDidChangeForAccountKey];
    if ([changedAccount.accountIdentifier isEqualToString:[AccountManager sharedManager].selectedAccount.accountIdentifier])
    {
        NSString *title = NSLocalizedString(@"main.menu.profile.selection.banner.title", @"Profile Changed Title");
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"main.menu.profile.selection.banner.message", @"Profile Changed"), selectedProfile.label];
        displayInformationMessageWithTitle(message, title);
    }
}

#pragma mark - Setup Methods

- (void)setup
{
    [super setup];
    
    self.title = self.account.accountDescription;
}

- (void)setupTableViewData
{
    LabelCell *profileCell = [self profileCell];
    LabelCell *editMainMenuCell = [self editMainMenuCell];
    LabelCell *accountDetailsCell = [self accountDetailsCell];
    CenterLabelCell *logout = [self logoutCell];
    if ([AccountManager sharedManager].selectedAccount != self.account || [[AccountManager sharedManager] allAccounts].count == 1)
    {
        self.tableViewData = @[@[profileCell], @[editMainMenuCell], @[accountDetailsCell] , @[logout]];
    }
    else
    {
        self.tableViewData = @[@[profileCell], @[editMainMenuCell], @[accountDetailsCell] , @[]];
    }
}

- (void)setupHeaders
{
    self.tableGroupHeaders = @[@"accountdetails.header.profile", @"accountdetails.header.main.menu.config", @"", @""];
}

- (void)setupFooters
{
    self.tableGroupFooters = @[@"", (self.canReorderMainMenuItems) ? @"" : @"accountdetails.footer.main.menu.config.disabled", @"", @""];
}

- (void)setAccessibilityIdentifiers
{
    
}

@end

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

#import "MainMenuConfigurationViewController.h"
#import "AvatarManager.h"
#import "AccountManager.h"
#import "SyncManager.h"
#import "MainMenuTableViewCell.h"
#import "AppConfigurationManager.h"
#import "MainMenuRemoteConfigurationBuilder.h"
#import "RootRevealViewController.h"

static NSString * const kSitesViewIdentifier = @"view-sites-default";
static NSString * const kFavouritesViewIdentifier = @"view-favorite-default";

// Extend the MainMenuViewController so we have access to private properties and methods
@interface MainMenuViewController ()
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSArray *tableViewData;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface MainMenuConfigurationViewController () <RootRevealViewControllerDelegate>
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) MainMenuConfigurationBuilder *builder;
@end

@implementation MainMenuConfigurationViewController

- (instancetype)initWithTitle:(NSString *)title menuBuilder:(MainMenuBuilder *)builder delegate:(id<MainMenuViewControllerDelegate>)delegate
{
    self = [super initWithTitle:title menuBuilder:builder delegate:delegate];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionUpdated:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountListEmpty:) name:kAlfrescoAccountsListEmptyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated:) name:kAlfrescoAccountUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configurationDidChange:) name:kAlfrescoConfigurationFileDidUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenu:) name:kAlfrescoConfigurationShouldUpdateMainMenuNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(URLHandlingDidEnd:) name:kAlfrescoEnableMainMenuAutoItemSelection object:nil];
        self.autoselectDefaultMenuOption = YES;
        
        [self loadGroupType:MainMenuGroupTypeHeader completionBlock:nil];
        [self loadGroupType:MainMenuGroupTypeFooter completionBlock:nil];
    }
    return self;
}

- (void)sessionUpdated:(NSNotification *)notification
{
    id<AlfrescoSession> session = (id<AlfrescoSession>)notification.object;
    UserAccount *account = [AccountManager sharedManager].selectedAccount;
    self.session = session;
    
    NSString *accountName = account.accountDescription;
    [self updateMainMenuItemWithIdentifier:kAlfrescoMainMenuItemAccountsIdentifier withDescription:accountName];
    [self updateMenu:nil];
    
    [[AvatarManager sharedManager] retrieveAvatarForPersonIdentifier:self.session.personIdentifier session:self.session completionBlock:^(UIImage *image, NSError *error) {
        if (image)
        {
            [self updateMainMenuItemWithIdentifier:kAlfrescoMainMenuItemAccountsIdentifier withImage:image];
        }
    }];
}

- (void)accountListEmpty:(NSNotification *)notification
{
    [self clearGroupType:MainMenuGroupTypeContent];
}

- (void)accountUpdated:(NSNotification *)notification
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    UserAccount *updatedAccount = notification.object;
    
    if ([selectedAccount.accountIdentifier isEqualToString:updatedAccount.accountIdentifier])
    {
        [self reloadGroupType:MainMenuGroupTypeContent completionBlock:nil];
    }
}

- (void)accountRemoved:(NSNotification *)notification
{
    [[AvatarManager sharedManager] deleteAvatarForIdentifier:self.session.personIdentifier];
    
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    UserAccount *removedAccount = notification.object;
    
    if ([selectedAccount.accountIdentifier isEqualToString:removedAccount.accountIdentifier])
    {
        self.session = nil;
        [self updateMainMenuItemWithIdentifier:kAlfrescoMainMenuItemAccountsIdentifier withDescription:@""];
    }
}

- (void)configurationDidChange:(NSNotification *)notification
{
    MainMenuConfigurationBuilder *builder = notification.object;
    self.builder = builder;
    
    [self updateMenu:notification];
}

- (void)updateMenu:(NSNotification *)notification
{
    [self reloadGroupType:MainMenuGroupTypeContent completionBlock:^{
        if(self.autoselectDefaultMenuOption)
        {
            // select sites
            [self selectMenuItemWithIdentifier:kSitesViewIdentifier fallbackIdentifier:kAlfrescoMainMenuItemAccountsIdentifier];
        }
    }];
}

- (void)URLHandlingDidEnd:(NSNotification *)notification
{
    self.autoselectDefaultMenuOption = YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainMenuTableViewCell *cell = (MainMenuTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    MainMenuSection *sectionItem = self.tableViewData[indexPath.section];
    MainMenuItem *item = sectionItem.visibleSectionItems[indexPath.row];
    
    // If the current item is the favourites item, check to see if we should display the sync text/image or favourites
    if ([item.itemIdentifier isEqualToString:kFavouritesViewIdentifier])
    {
        BOOL isSyncOn = [[SyncManager sharedManager] isSyncPreferenceOn];
        NSString *textTitle = NSLocalizedString(isSyncOn ? @"sync.title" : @"favourites.title", @"Key") ;
        NSString *imageName = isSyncOn ? @"mainmenu-sync.png" : @"mainmenu-favourites.png";
        UIImage *image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        item.itemImage = image;
        cell.itemImageView.image = image;
        item.itemTitle = textTitle;
        cell.itemTextLabel.text = textTitle.uppercaseString;
    }
    
    return cell;
}

#pragma mark - RootRevealViewControllerDelegate Methods

- (void)controllerDidExpandToDisplayMasterViewController:(RootRevealViewController *)controller
{
    [self visibilityForSectionHeadersHidden:NO animated:YES];
}

- (void)controllerWillCollapseToHideMasterViewController:(RootRevealViewController *)controller
{
    [self visibilityForSectionHeadersHidden:YES animated:YES];
}

@end

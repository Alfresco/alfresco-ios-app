/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
 
#import "SettingsViewController.h"
#import "PreferenceManager.h"
#import "SettingToggleCell.h"
#import "SettingTextFieldCell.h"
#import "SettingConstants.h"
#import "SettingLabelCell.h"
#import "AboutViewController.h"
#import "AccountManager.h"
#import "SettingButtonCell.h"
#import "UIAlertView+ALF.h"
#import "CoreDataCacheHelper.h"
#import "AvatarImageCache.h"
#import "DownloadManager.h"

static NSUInteger const kCellLeftInset = 10;

@interface SettingsViewController () <SettingsCellProtocol>
@end

@implementation SettingsViewController

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // create and configure the table view
    self.tableView = [[ALFTableView alloc] initWithFrame:view.frame style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, kCellLeftInset, 0, 0);
    [view addSubview:self.tableView];
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.allowsPullToRefresh = NO;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString *pListPath = [[NSBundle mainBundle] pathForResource:@"UserPreferences" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:pListPath];

    self.title = NSLocalizedString([dictionary objectForKey:kSettingsLocalizedTitleKey], @"Settings Title") ;
    self.tableViewData = [self filteredPreferences:[dictionary objectForKey:kSettingsTableViewData]];
    [self.tableView reloadData];
}

#pragma mark - Private Functions

- (NSMutableArray *)filteredPreferences:(NSMutableArray *)unfilteredPreferences
{
    BOOL hasPaidAccounts = [[AccountManager sharedManager] numberOfPaidAccounts] > 0;
    if (!hasPaidAccounts)
    {
        // Filter the groups first
        NSMutableArray *filteredGroups = [NSMutableArray array];
        for (NSDictionary *unfilteredGroup in unfilteredPreferences)
        {
            NSMutableDictionary *filteredGroup = [unfilteredGroup mutableCopy];
            NSNumber *groupValue = [filteredGroup objectForKey:kSettingsPaidAccountsOnly];
            if (groupValue == nil || ![groupValue boolValue])
            {
                // Filter the items
                NSMutableArray *filteredItems = [NSMutableArray array];
                for (NSDictionary *item in filteredGroup[kSettingsGroupCells])
                {
                    NSNumber *itemValue = [item objectForKey:kSettingsPaidAccountsOnly];
                    if (itemValue == nil || ![itemValue boolValue])
                    {
                        [filteredItems addObject:item];
                    }
                }
                if (filteredItems.count > 0)
                {
                    filteredGroup[kSettingsGroupCells] = filteredItems;
                    [filteredGroups addObject:filteredGroup];
                }
            }
        }
        return filteredGroups;
    }
    return unfilteredPreferences;
}

- (void)doneButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:self.dismissCompletionBlock];
}

- (Class)determineTableViewCellClassFromCellInfo:(NSDictionary *)cellInfo
{
    NSString *cellPreferenceType = [cellInfo objectForKey:kSettingsCellType];
    
    Class returnClass;
    
    if ([cellPreferenceType isEqualToString:kSettingsToggleCell])
    {
        returnClass = [SettingToggleCell class];
    }
    else if ([cellPreferenceType isEqualToString:kSettingsTextFieldCell])
    {
        returnClass = [SettingTextFieldCell class];
    }
    else if ([cellPreferenceType isEqualToString:kSettingsLabelCell])
    {
        returnClass = [SettingLabelCell class];
    }
    else if ([cellPreferenceType isEqualToString:kSettingsButtonCell])
    {
        returnClass = [SettingButtonCell class];
    }
    
    return returnClass;
}

- (NSString *)determineCellReuseIdentifierFromCellInfo:(NSDictionary *)cellInfo
{
    NSString *cellPreferenceType = [cellInfo objectForKey:kSettingsCellType];
    
    NSString *reuseIdentifier = nil;
    
    if ([cellPreferenceType isEqualToString:kSettingsToggleCell])
    {
        reuseIdentifier = kSettingsToggleCellReuseIdentifier;
    }
    else if ([cellPreferenceType isEqualToString:kSettingsTextFieldCell])
    {
        reuseIdentifier = kSettingsTextFieldCellReuseIdentifier;
    }
    else if ([cellPreferenceType isEqualToString:kSettingsLabelCell])
    {
        reuseIdentifier = kSettingsLabelCellReuseIdentifier;
    }
    else if ([cellPreferenceType isEqualToString:kSettingsButtonCellReuseIdentifier])
    {
        reuseIdentifier = kSettingsButtonCellReuseIdentifier;
    }
    
    return reuseIdentifier;
}

- (void)handleActionWithPreferenceIdentifier:(NSString *)preferenceIdentifier
{
    NSLog(@"Pressed %@", preferenceIdentifier);
    if ([preferenceIdentifier isEqualToString:kSettingsResetAccountsIdentifier])
    {
        UIAlertView *resetAccountAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"settings.reset.accounts.confirmation.title", @"Clear Accounts")
                                                                    message:NSLocalizedString(@"settings.reset.accounts.confirmation.message", @"Clear Accounts Message")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                          otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
        
        [resetAccountAlert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
            if (!isCancelButton)
            {
                // Remove accounts
                [[AccountManager sharedManager] removeAllAccounts];
                // Delete avatar cache
                CoreDataCacheHelper *cacheHelper = [[CoreDataCacheHelper alloc] init];
                [cacheHelper removeAllAvatarDataInManagedObjectContext:nil];
                
                UIAlertView *confirmation = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"settings.reset.confirmation.title", @"Reset Complete Title")
                                                                            message:NSLocalizedString(@"settings.reset.confirmation.message", @"Reset Complete Message")
                                                                           delegate:self
                                                                  cancelButtonTitle:NSLocalizedString(@"Close", @"Close")
                                                                  otherButtonTitles:nil];
                [confirmation show];
            }
        }];
    }
    else if ([preferenceIdentifier isEqualToString:kSettingsResetEntireAppIdentifier])
    {
        UIAlertView *resetAccountAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"settings.reset.confirmation.title", @"Clear Accounts, Cache and Downloads Title")
                                                                    message:NSLocalizedString(@"settings.reset.entire.app.confirmation.message", @"Clear Accounts, Cache and Downloads Message")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                          otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
        
        [resetAccountAlert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
            if (!isCancelButton)
            {
                // Reset accounts, delete cache databases, tmp folder, downloads
                // Remove accounts
                [[AccountManager sharedManager] removeAllAccounts];
                // Delete cache
                CoreDataCacheHelper *cacheHelper = [[CoreDataCacheHelper alloc] init];
                [cacheHelper removeAllAvatarDataInManagedObjectContext:nil];
                [cacheHelper removeAllDocLibImageDataInManagedObjectContext:nil];
                [cacheHelper removeAllDocumentPreviewImageDataInManagedObjectContext:nil];
                // Remove downloads
                [[DownloadManager sharedManager] removeAllDownloads];
                // Remove all contents of the temp folder
                [[AlfrescoFileManager sharedManager] clearTemporaryDirectory];
                
                UIAlertView *confirmation = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"settings.reset.confirmation.title", @"Reset Complete Title")
                                                                       message:NSLocalizedString(@"settings.reset.confirmation.message", @"Reset Complete Message")
                                                                      delegate:self
                                                             cancelButtonTitle:NSLocalizedString(@"Close", @"Close")
                                                             otherButtonTitles:nil];
                [confirmation show];
            }
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.tableViewData objectAtIndex:section] objectForKey:kSettingsGroupCells] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *groupInfoDictionary = [self.tableViewData objectAtIndex:section];
    NSString *groupHeaderTitle = [groupInfoDictionary objectForKey:kSettingsGroupHeaderLocalizedKey];
    return NSLocalizedString(groupHeaderTitle, @"Section header title");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary *groupInfoDictionary = [self.tableViewData objectAtIndex:section];
    NSString *groupHeaderTitle = [groupInfoDictionary objectForKey:kSettingsGroupFooterLocalizedKey];
    return NSLocalizedString(groupHeaderTitle, @"Section footer title");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *groupInfoDictionary = [self.tableViewData objectAtIndex:indexPath.section];
    NSArray *groupCellsArray = [groupInfoDictionary objectForKey:kSettingsGroupCells];
    NSDictionary *currentCellInfo = [groupCellsArray objectAtIndex:indexPath.row];
    
    NSString *CellIdentifier = [self determineCellReuseIdentifierFromCellInfo:currentCellInfo];
    Class CellClass = [self determineTableViewCellClassFromCellInfo:currentCellInfo];
    
    SettingCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = (SettingCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(CellClass) owner:self options:nil] lastObject];
        cell.delegate = self;
    }
    
    id preferenceValue = [[PreferenceManager sharedManager] preferenceForIdentifier:[currentCellInfo valueForKey:kSettingsCellPreferenceIdentifier]];
    
    [cell updateCellForCellInfo:currentCellInfo value:preferenceValue delegate:self];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingCell *cell = (SettingCell *)[tableView cellForRowAtIndexPath:indexPath];
    if ([cell.preferenceIdentifier isEqualToString:kSettingsAboutIdentifier])
    {
        AboutViewController *aboutViewController = [[AboutViewController alloc] init];
        [self.navigationController pushViewController:aboutViewController animated:YES];
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - SettingsCellProtocol Functions

- (void)valueDidChangeForCell:(SettingCell *)cell preferenceIdentifier:(NSString *)preferenceIdentifier value:(id)value
{
    // If it's an action cell that requires action, else, update the prefernces
    if ([cell isKindOfClass:[SettingButtonCell class]])
    {
        [self handleActionWithPreferenceIdentifier:preferenceIdentifier];
    }
    else
    {
        [[PreferenceManager sharedManager] updatePreferenceToValue:value preferenceIdentifier:preferenceIdentifier];
    }
}

@end

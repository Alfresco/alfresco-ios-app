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
 
#import "AccountTypeSelectionViewController.h"
//#import "AccountInfoViewController.h"
#import "LoginManager.h"
#import "AccountManager.h"
#import "NewAccountViewController.h"

static NSInteger const kNumberAccountTypes = 2;
static NSInteger const kNumberOfTypesPerSection = 1;

static NSInteger const kCloudSectionNumber = 0;

static CGFloat const kAccountTypeTitleFontSize = 18.0f;
static CGFloat const kAccountTypeCellRowHeight = 66.0f;

@interface AccountTypeSelectionViewController () <NewAccountViewControllerDelegate>
@end

@implementation AccountTypeSelectionViewController

- (id)init
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:nil];
    if (self)
    {
    }
    return self;
}

- (instancetype)initWithDelegate:(id<AccountTypeSelectionViewControllerDelegate>)delegate
{
    self = [self init];
    if (self)
    {
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.allowsPullToRefresh = NO;
    self.title = NSLocalizedString(@"accountdetails.title.newaccount", @"New Account");
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancel;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberAccountTypes;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return kNumberOfTypesPerSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AccountTypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:kAccountTypeTitleFontSize];
    if (indexPath.section == 0)
    {
        cell.imageView.image = [[UIImage imageNamed:@"account-type-cloud.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.textLabel.text = NSLocalizedString(@"accounttype.cloud", @"Alfresco Cloud");
    }
    else
    {
        cell.imageView.image = [UIImage imageNamed:@"account-type-onpremise.png"];
        cell.textLabel.text = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
        cell.accessoryView = nil;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kCloudSectionNumber)
    {
        UserAccount *account = [[UserAccount alloc] initWithAccountType:UserAccountTypeCloud];
        account.accountDescription = NSLocalizedString(@"accounttype.cloud", @"Alfresco Cloud");
        
        [[LoginManager sharedManager] authenticateCloudAccount:account networkId:nil navigationController:self.navigationController completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                AccountManager *accountManager = [AccountManager sharedManager];
                
                if (accountManager.totalNumberOfAddedAccounts == 0)
                {
                    [accountManager selectAccount:account selectNetwork:[account.accountNetworks firstObject] alfrescoSession:alfrescoSession];
                }
                
                if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerWillDismiss:accountAdded:)])
                {
                    [self.delegate accountTypeSelectionViewControllerWillDismiss:self accountAdded:YES];
                }
                
                [accountManager addAccount:account];

                [self dismissViewControllerAnimated:YES completion:^{
                    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerDidDismiss:accountAdded:)])
                    {
                        [self.delegate accountTypeSelectionViewControllerDidDismiss:self accountAdded:YES];
                    }
                }];
            }
            else
            {
                UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account")
                                                                       message:NSLocalizedString(@"accountdetails.alert.save.validationerror", @"Login Failed Message")
                                                                      delegate:nil cancelButtonTitle:NSLocalizedString(@"Done", @"Done")
                                                             otherButtonTitles:nil, nil];
                [failureAlert show];
            }
        }];
    }
    else
    {
        NewAccountViewController *accountInfoController = [[NewAccountViewController alloc] initWithAccount:nil configuration:nil];
        accountInfoController.delegate = self;
        [self.navigationController pushViewController:accountInfoController animated:YES];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *titleKey = (section == kCloudSectionNumber) ? @"accounttype.footer.alfrescoCloud" : @"accounttype.footer.alfrescoServer";
    return NSLocalizedString(titleKey, @"Access Alfresco Account");
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kAccountTypeCellRowHeight;
}

#pragma mark - private functions

- (void)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerWillDismiss:accountAdded:)])
    {
        [self.delegate accountTypeSelectionViewControllerWillDismiss:self accountAdded:NO];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerDidDismiss:accountAdded:)])
        {
            [self.delegate accountTypeSelectionViewControllerDidDismiss:self accountAdded:NO];
        }
    }];
}

#pragma mark - AccountInfoViewControllerDelegate Functions

- (void)newAccountViewControllerWillDismiss:(NewAccountViewController *)controller
{
    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerWillDismiss:accountAdded:)])
    {
        [self.delegate accountTypeSelectionViewControllerWillDismiss:self accountAdded:NO];
    }
}

- (void)newAccountViewControllerDidDismiss:(NewAccountViewController *)controller
{
    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerDidDismiss:accountAdded:)])
    {
        [self.delegate accountTypeSelectionViewControllerDidDismiss:self accountAdded:NO];
    }
}

- (void)newAccountViewController:(NewAccountViewController *)controller willDismissAfterAddingAccount:(UserAccount *)account
{
    BOOL accountAdded = (account != nil);
    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerWillDismiss:accountAdded:)])
    {
        [self.delegate accountTypeSelectionViewControllerWillDismiss:self accountAdded:accountAdded];
    }
}

- (void)newAccountViewController:(NewAccountViewController *)controller didDismissAfterAddingAccount:(UserAccount *)account
{
    BOOL accountAdded = (account != nil);
    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerDidDismiss:accountAdded:)])
    {
        [self.delegate accountTypeSelectionViewControllerDidDismiss:self accountAdded:accountAdded];
    }
}

@end

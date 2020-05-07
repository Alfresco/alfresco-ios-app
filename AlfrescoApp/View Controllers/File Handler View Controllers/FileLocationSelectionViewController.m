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
 
#import "FileLocationSelectionViewController.h"
#import "AccountManager.h"
#import "LoginManager.h"
#import "LoginViewController.h"
#import "NodePicker.h"

static NSUInteger const kNumberOfSectionsInTableView = 2;
static NSUInteger const kAccountsSectionIndex = 0;
static NSUInteger const kDownloadsSectionIndex = 1;

static NSString * const kCellIdentifier = @"FileLocationSelectionViewControllerCell";

@interface FileLocationSelectionViewController () <LoginViewControllerDelegate, NodePickerDelegate>

// Views
@property (nonatomic, weak) IBOutlet UITableView *tableView;
// Data Models
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSArray *accountList;
@property (nonatomic, strong) NSMutableArray *accountListIndexPaths;
@property (nonatomic, strong) NodePicker *nodePicker;
@property (nonatomic, assign) NSUInteger numberOfAccountRows;

@end

@implementation FileLocationSelectionViewController

- (instancetype)initWithFilePath:(NSString *)filePath session:(id<AlfrescoSession>)session delegate:(id<FileLocationSelectionViewControllerDelegate>)delegate
{
    self = [self init];
    if (self)
    {
        self.filePath = filePath;
        self.session = session;
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"saveback.locationpicker.title", @"Choose Location");
    
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    
    self.accountList = [[AccountManager sharedManager] allAccounts];
    self.accountListIndexPaths = [NSMutableArray array];
    self.numberOfAccountRows = [self numberOfAccountSectionRows];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Functions

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
}

- (void)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSUInteger)numberOfAccountSectionRows
{
    NSUInteger accountIndex = 0;
    
    for (UserAccount *account in self.accountList)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:accountIndex++];

        if (account.accountType == UserAccountTypeOnPremise)
        {
            [self.accountListIndexPaths addObject:indexPath];
        }
        else
        {
            for (NSUInteger networkIndex = 0; networkIndex < account.accountNetworks.count; networkIndex++)
            {
                [self.accountListIndexPaths addObject:[indexPath indexPathByAddingIndex:networkIndex]];
            }
        }
    }
    
    return self.accountListIndexPaths.count;
}

- (void)displayNodePickerWithSession:(id<AlfrescoSession>)session navigationContoller:(UINavigationController *)navigationContoller
{
    self.nodePicker = [[NodePicker alloc] initWithSession:session navigationController:navigationContoller];
    self.nodePicker.delegate = self;
    [self.nodePicker startWithNodes:nil type:NodePickerTypeFolders mode:NodePickerModeSingleSelect];
}

#pragma mark - UITableViewDataSource Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSectionsInTableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 1;
    
    if (section == kAccountsSectionIndex)
    {
        numberOfRows = self.numberOfAccountRows;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if (indexPath.section == kAccountsSectionIndex)
    {
        NSInteger rowIndex = indexPath.row;
        NSIndexPath *indexPath = self.accountListIndexPaths[rowIndex];
        UserAccount *currentAccount = self.accountList[[indexPath indexAtPosition:0]];
        
        cell.textLabel.text = currentAccount.accountDescription;
        
        UIImage *accountTypeImage = [UIImage imageNamed:@"account-type-onpremise.png"];
        if (currentAccount.accountType == UserAccountTypeCloud)
        {
            accountTypeImage = [[UIImage imageNamed:@"account-type-cloud.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", currentAccount.accountDescription, currentAccount.accountNetworks[[indexPath indexAtPosition:1]]];
        }
        
        cell.imageView.image = accountTypeImage;
    }
    else
    {
        cell.textLabel.text = NSLocalizedString(@"downloads.title", @"Local Files");
        cell.imageView.image = [UIImage imageNamed:@"mainmenu-localfiles.png"];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = nil;
    
    if (section == kAccountsSectionIndex)
    {
        headerTitle = NSLocalizedString(@"accounts.title", @"Accounts Title");
    }
    else
    {
        headerTitle = NSLocalizedString(@"saveback.locationpicker.other", @"Other Title");
    }
    
    return headerTitle;
}

#pragma mark - UITableViewDelegate Functions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == kAccountsSectionIndex)
    {
        NSIndexPath *accountListIndexPath = self.accountListIndexPaths[indexPath.row];
        UserAccount *selectedAccount = self.accountList[[accountListIndexPath indexAtPosition:0]];
        UserAccount *activeAccount = [[AccountManager sharedManager] selectedAccount];
        
        if (selectedAccount == activeAccount && self.session != nil)
        {
            [self displayNodePickerWithSession:self.session navigationContoller:self.navigationController];
        }
        else
        {
            MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.navigationController.view addSubview:progressHUD];
            if (selectedAccount.accountType == UserAccountTypeCloud)
            {
                NSString *networkID = selectedAccount.accountNetworks[[accountListIndexPath indexAtPosition:1]];
                [progressHUD showAnimated:YES];
                [[LoginManager sharedManager] authenticateCloudAccount:selectedAccount networkId:networkID navigationController:nil completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                    [progressHUD hideAnimated:YES];
                    if (successful && alfrescoSession)
                    {
                        [self displayNodePickerWithSession:alfrescoSession navigationContoller:self.navigationController];
                        self.session = alfrescoSession;
                    }
                }];
            }
            else
            {
                if (selectedAccount.password.length == 0)
                {
                    [progressHUD showAnimated:YES];
                    [[LoginManager sharedManager] authenticateOnPremiseAccount:selectedAccount password:selectedAccount.password completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                        [progressHUD hideAnimated:YES];
                        if (successful)
                        {
                            [self displayNodePickerWithSession:alfrescoSession navigationContoller:self.navigationController];
                            self.session = alfrescoSession;
                        }
                        else
                        {
                            displayErrorMessage([ErrorDescriptions descriptionForError:error]);
                        }
                    }];
                }
                else
                {
                    // display login controller
                    LoginViewController *loginViewController = [[LoginViewController alloc] initWithAccount:selectedAccount delegate:self];
                    [self.navigationController pushViewController:loginViewController animated:YES];
                }
                
            }
        }
    }
    else if (indexPath.section == kDownloadsSectionIndex)
    {
        [self.delegate fileLocationSelectionViewController:self saveFileAtPathToDownloads:self.filePath];
    }
}

#pragma mark - LoginViewControllerDelegate Functions

- (void)loginViewController:(LoginViewController *)loginViewController didPressRequestLoginToAccount:(UserAccount *)account username:(NSString *)username password:(NSString *)password
{
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:loginViewController.navigationController.view];
    [loginViewController.navigationController.view addSubview:progressHUD];
    [progressHUD showAnimated:YES];
    [[LoginManager sharedManager] authenticateOnPremiseAccount:account password:password completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
        [progressHUD hideAnimated:YES];
        if (successful)
        {
            [self displayNodePickerWithSession:alfrescoSession navigationContoller:self.navigationController];
            self.session = alfrescoSession;
        }
        else
        {
            displayErrorMessage([ErrorDescriptions descriptionForError:error]);
        }
    }];
}

- (void)loginViewController:(LoginViewController *)loginViewController didPressCancel:(UIBarButtonItem *)button
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - NodePickerDelegate Functions

- (void)nodePicker:(NodePicker *)nodePicker didSelectNodes:(NSArray *)selectedNodes
{
    if (selectedNodes.count > 0)
    {
        [self.delegate fileLocationSelectionViewController:self uploadToFolder:selectedNodes.lastObject session:self.session filePath:self.filePath];
    }
}

@end

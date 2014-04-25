//
//  FileLocationSelectionViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 23/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "FileLocationSelectionViewController.h"
#import "AccountManager.h"
#import "LoginManager.h"
#import "LoginViewController.h"
#import "NodePicker.h"
#import "MBProgressHUD.h"

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
    self.numberOfAccountRows = [self numberOfAccountSectionRows];
}

#pragma mark - Private Functions

- (void)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSUInteger)numberOfAccountSectionRows
{
    NSArray *cloudAccounts = [self.accountList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.accountType == %i", UserAccountTypeCloud]];
    NSArray *onPremiseAccounts = [self.accountList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.accountType == %i", UserAccountTypeOnPremise]];
    
    int totalTenants = 0;
    for (UserAccount *account in cloudAccounts)
    {
        totalTenants += account.accountNetworks.count;
    }
    
    return onPremiseAccounts.count + totalTenants;
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
    NSInteger numberOfRows = 0;
    
    if (section == kAccountsSectionIndex)
    {
        numberOfRows = self.numberOfAccountRows;
    }
    else
    {
        numberOfRows = 1;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if (indexPath.section == kAccountsSectionIndex)
    {
        NSInteger rowIndex = indexPath.row;
        UserAccount *currentAccount = self.accountList[rowIndex];
        
        cell.textLabel.text = currentAccount.accountDescription;
        
        UIImage *accountTypeImage = [UIImage imageNamed:@"account-type-onpremise.png"];
        if (currentAccount.accountType == UserAccountTypeCloud)
        {
            accountTypeImage = [[UIImage imageNamed:@"account-type-cloud.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", currentAccount.accountDescription, currentAccount.accountNetworks[rowIndex]];
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
        UserAccount *selectedAccount = self.accountList[indexPath.row];
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
                NSString *networkID = selectedAccount.accountNetworks[indexPath.row];
                [progressHUD show:YES];
                [[LoginManager sharedManager] authenticateCloudAccount:selectedAccount networkId:networkID navigationConroller:nil completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession) {
                    [progressHUD hide:YES];
                    if (successful && alfrescoSession)
                    {
                        [self displayNodePickerWithSession:alfrescoSession navigationContoller:self.navigationController];
                        self.session = alfrescoSession;
                    }
                }];
            }
            else
            {
                if (selectedAccount.password != nil && ![selectedAccount.password isEqualToString:@""])
                {
                    [progressHUD show:YES];
                    [[LoginManager sharedManager] authenticateOnPremiseAccount:selectedAccount password:selectedAccount.password completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession) {
                        [progressHUD hide:YES];
                        if (successful && alfrescoSession)
                        {
                            [self displayNodePickerWithSession:alfrescoSession navigationContoller:self.navigationController];
                            self.session = alfrescoSession;
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
    [progressHUD show:YES];
    [[LoginManager sharedManager] authenticateOnPremiseAccount:account password:password completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession) {
        [progressHUD hide:YES];
        if (successful && alfrescoSession)
        {
            [self displayNodePickerWithSession:alfrescoSession navigationContoller:self.navigationController];
            self.session = alfrescoSession;
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
        [self.delegate fileLocationSelectionViewController:self uploadToFolder:selectedNodes[0] session:self.session filePath:self.filePath];
    }
}

@end

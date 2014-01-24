//
//  AddNewAccountViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 24/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AccountTypeSelectionViewController.h"
#import "AccountInfoViewController.h"
#import "LoginManager.h"
#import "AccountManager.h"
#import "CloudSignUpViewController.h"

static NSInteger const kNumberAccountTypes = 2;
static NSInteger const kNumberOfTypesPerSection = 1;

static NSInteger const kCloudSectionNumber = 0;
static NSInteger const kOnPremiseSectionNumber = 1;

static CGFloat const kAccountTypeTitleFontSize = 20.0f;
static CGFloat const kAccountTypeCellRowHeight = 66.0f;

static CGFloat const kAccountTypeFooterFontSize = 15.0f;
static CGFloat const kAccountTypeFooterHeight = 60.0f;

@interface AccountTypeSelectionViewController () <AccountInfoViewControllerDelegate>

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
    
    [self disablePullToRefresh];
    
    self.title = NSLocalizedString(@"accountdetails.title.newaccount", @"New Account");
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancel;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        cell.imageView.image = [UIImage imageNamed:@"cloud.png"];
        cell.textLabel.text = NSLocalizedString(@"accounttype.cloud", @"Alfresco Cloud");
    }
    else
    {
        cell.imageView.image = [UIImage imageNamed:@"server.png"];
        cell.textLabel.text = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kCloudSectionNumber)
    {
        UserAccount *account = [[UserAccount alloc] initWithAccountType:UserAccountTypeCloud];
        account.accountDescription = NSLocalizedString(@"accounttype.cloud", @"Alfresco Cloud");
        BOOL useTemporarySession = !([[AccountManager sharedManager] totalNumberOfAddedAccounts] == 0);
        
        [[LoginManager sharedManager] authenticateCloudAccount:account networkId:nil navigationConroller:self.navigationController completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession) {
            
            if (successful)
            {
                AccountManager *accountManager = [AccountManager sharedManager];
                
                if (accountManager.totalNumberOfAddedAccounts == 0)
                {
                    id<AlfrescoSession> session = useTemporarySession ? nil : alfrescoSession;
                    [accountManager selectAccount:account selectNetwork:[account.accountNetworks firstObject] alfrescoSession:session];
                }
                
                if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerWillDismiss:accountAdded:)])
                {
                    [self.delegate accountTypeSelectionViewControllerWillDismiss:self accountAdded:YES];
                }
                
                [self dismissViewControllerAnimated:YES completion:^{
                    [accountManager addAccount:account];
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
        AccountInfoViewController *accountInfoController = [[AccountInfoViewController alloc] initWithAccount:nil accountActivityType:AccountActivityTypeNewAccount];
        accountInfoController.delegate = self;
        [self.navigationController pushViewController:accountInfoController animated:YES];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == kCloudSectionNumber)
    {
        return [self cloudAccountFooter];
    }
    else
    {
        return [self alfrescoServerAccountFooter];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kAccountTypeCellRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kAccountTypeFooterHeight;
}

#pragma mark - private functions

- (void)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerWillDismiss:)])
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

- (UIView *)cloudAccountFooter
{
    NSString *signupText = NSLocalizedString(@"accounttype.footer.signuplink", @"New to Alfresco? Sign up...") ;
    NSString *footerText = NSLocalizedString(@"accounttype.footer.alfrescoCloud", @"Access your Alfresco in the cloud account");
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    [footerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth];
    
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    footerLabel.adjustsFontSizeToFitWidth = YES;
    footerLabel.backgroundColor = self.tableView.backgroundColor;
    footerLabel.userInteractionEnabled = YES;
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1];
    footerLabel.font = [UIFont systemFontOfSize:15];
    footerLabel.text = footerText;
    [footerLabel sizeToFit];
    [footerLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    
    TTTAttributedLabel *signupLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    CGRect signUpLabelFrame = signupLabel.frame;
    signUpLabelFrame.size.width = footerView.frame.size.width;
    signUpLabelFrame.origin.y = footerLabel.frame.size.height;
    signupLabel.frame = signUpLabelFrame;
    
    signupLabel.adjustsFontSizeToFitWidth = YES;
    signupLabel.backgroundColor = self.tableView.backgroundColor;
    signupLabel.numberOfLines = 0;
    signupLabel.userInteractionEnabled = YES;
    signupLabel.textAlignment = NSTextAlignmentCenter;
    signupLabel.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1];
    signupLabel.font = [UIFont systemFontOfSize:15];
    signupLabel.text = signupText;
    [signupLabel sizeToFit];
    [signupLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    
    NSString *signUpLink = NSLocalizedString(@"accounttype.footer.signuplink.linktext", @"Sign up");
    NSRange signupRange = [signupText rangeOfString:signUpLink];
    if (signupRange.length > 0)
    {
        [signupLabel addLinkToURL:[NSURL URLWithString:signUpLink] withRange:signupRange];
        [signupLabel setDelegate:self];
    }
    
    [footerView addSubview:footerLabel];
    [footerView addSubview:signupLabel];
    return footerView;
}

- (UIView *)alfrescoServerAccountFooter
{
    NSString *footerText = NSLocalizedString(@"accounttype.footer.alfrescoServer", @"Access your Alfresco Server");
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    [footerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth];
    
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    footerLabel.adjustsFontSizeToFitWidth = YES;
    footerLabel.backgroundColor = self.tableView.backgroundColor;
    footerLabel.userInteractionEnabled = YES;
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1];
    footerLabel.font = [UIFont systemFontOfSize:15];
    footerLabel.text = footerText;
    [footerLabel sizeToFit];
    [footerLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    
    [footerView addSubview:footerLabel];
    return footerView;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    CloudSignUpViewController *signUpController = [[CloudSignUpViewController alloc] initWithAccount:nil];
    [self.navigationController pushViewController:signUpController animated:YES];
}

#pragma mark - AccountInfoViewControllerDelegate Functions

- (void)accountInfoViewControllerWillDismiss:(AccountInfoViewController *)controller
{
    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerWillDismiss:accountAdded:)])
    {
        [self.delegate accountTypeSelectionViewControllerWillDismiss:self accountAdded:NO];
    }
}

- (void)accountInfoViewControllerDidDismiss:(AccountInfoViewController *)controller
{
    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerDidDismiss:accountAdded:)])
    {
        [self.delegate accountTypeSelectionViewControllerDidDismiss:self accountAdded:NO];
    }
}

- (void)accountInfoViewController:(AccountInfoViewController *)controller willDismissAfterAddingAccount:(UserAccount *)account
{
    BOOL accountAdded = (account != nil);
    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerWillDismiss:accountAdded:)])
    {
        [self.delegate accountTypeSelectionViewControllerWillDismiss:self accountAdded:accountAdded];
    }
}

- (void)accountInfoViewController:(AccountInfoViewController *)controller didDismissAfterAddingAccount:(UserAccount *)account
{
    BOOL accountAdded = (account != nil);
    if ([self.delegate respondsToSelector:@selector(accountTypeSelectionViewControllerDidDismiss:accountAdded:)])
    {
        [self.delegate accountTypeSelectionViewControllerDidDismiss:self accountAdded:accountAdded];
    }
}

@end

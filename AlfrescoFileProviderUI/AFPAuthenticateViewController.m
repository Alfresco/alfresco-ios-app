/*******************************************************************************
 * Copyright (C) 2005-2018 Alfresco Software Limited.
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

#import "AFPAuthenticateViewController.h"
#import "AFPUIInfoViewController.h"
#import "AFPAccountManager.h"
#import "AccountManager.h"
#import "AFPUIConstants.h"
#import "LoginManagerCore.h"
#import "MBProgressHUD.h"

@interface AFPAuthenticateViewController () <LoginManagerCoreDelegate, AFPUIInfoViewControllerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint     *toolbarHeightConstraint;

@property (strong, nonatomic) LoginManagerCore *loginManagerCore;
@property (strong, nonatomic) MBProgressHUD    *progressHud;
@property (assign, nonatomic) CGFloat          initialToolbarHeight;

@end

@implementation AFPAuthenticateViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _loginManagerCore = [LoginManagerCore new];
        _loginManagerCore.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.initialToolbarHeight = kUIExtensionToolbarHeight;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (@available(iOS 11.0, *)) {
        self.toolbarHeightConstraint.constant = self.initialToolbarHeight + self.view.safeAreaInsets.top;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupProgressHudComponent];
    
    if ([AFPAccountManager isPINAuthenticationSet])
    {
        [self performSegueWithIdentifier:kUIExtentionPinViewControllerSegueIdentifier
                                  sender:nil];
    } else {
        AccountManager *accountManager = [AccountManager sharedManager];
        if (accountManager.selectedAccount)
        {
            [self.loginManagerCore attemptLoginToAccount:accountManager.selectedAccount
                                               networkId:accountManager.selectedAccount.selectedNetworkId
                                         completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                                             NSLog(@"");
            }];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([kUIExtentionPinViewControllerSegueIdentifier isEqualToString:segue.identifier] ||
        [kUIExtentionBasicAuthViewControllerSegueIdentifier isEqualToString:segue.identifier])
    {
        AFPUIInfoViewController *infoViewController = (AFPUIInfoViewController *)segue.destinationViewController;
        infoViewController.delegate = self;
        
        if ([kUIExtentionPinViewControllerSegueIdentifier isEqualToString:segue.identifier])
        {
            infoViewController.controllerType = AFPUIInfoViewControllerTypePIN;
        }
        else
        {
            infoViewController.controllerType = AFPUIInfoViewControllerTypeBasicAuth;
        }
    }
}

#pragma mark - Actions

- (IBAction)onCancel:(id)sender {
    [self.loginManagerCore cancelLoginRequest];
    [self userDidCancelledInfoScreen];
}

#pragma mark - AFPUIInfoViewControllerDelegate

- (void)userDidCancelledInfoScreen
{
    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:FPUIErrorDomain
                                                                      code:FPUIExtensionErrorCodeUserCancelled
                                                                  userInfo:nil]];
}

#pragma mark - LoginManagerCoreDelegate

- (void)willBeginVisualAuthenticationProgress
{
    [self showProgressHud];
}

- (void)willEndVisualAuthenticationProgress
{
    [self hideProgressHud];
}

- (void)showSAMLLoginViewController:(AlfrescoSAMLUILoginViewController *)viewController
             inNavigationController:(UINavigationController *)navigationController
{
    NSLog(@"");
}

- (void)showOauthLoginController:(AlfrescoOAuthUILoginViewController *)viewController
          inNavigationController:(UINavigationController *)navigationController
{
    NSLog(@"");
}

- (void)showSignInAlertWithSignedInBlock:(void (^)(void))completionBlock
{
    NSLog(@"");
}

- (void)displayLoginViewControllerWithAccount:(UserAccount *)account
                                     username:(NSString *)username
{
    [self performSegueWithIdentifier:kUIExtentionBasicAuthViewControllerSegueIdentifier
                              sender:nil];
}


- (void)clearDetailViewController
{
    NSLog(@"");
}

- (void)trackAnalyticsEventWithCategory:(NSString *)eventCategory
                                 action:(NSString *)eventAction
                                  label:(NSString *)eventLabel
                                  value:(NSNumber *)value
{
    NSLog(@"");
}

- (void)trackAnalyticsScreenWithName:(NSString *)screenName
{
    NSLog(@"");
}

#pragma mark - Hud component

- (void)setupProgressHudComponent
{
    self.progressHud = [[MBProgressHUD alloc] initWithView:self.view];
    self.progressHud.removeFromSuperViewOnHide = YES;
}

- (void)showProgressHud
{
    [self.view addSubview:self.progressHud];
    [self.progressHud showAnimated:YES];
}

- (void)hideProgressHud
{
    [self.progressHud hideAnimated:YES];
}

@end

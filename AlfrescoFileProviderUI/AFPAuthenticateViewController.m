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

#import "AFPAuthenticateViewController.h"
#import "AFPUIInfoViewController.h"
#import "AFPAccountManager.h"
#import "AccountManager.h"
#import "AFPUIConstants.h"
#import "LoginManagerCore.h"
#import "MBProgressHUD.h"
#import "UserAccountWrapper.h"

@interface AFPAuthenticateViewController () <LoginManagerCoreDelegate, AFPUIInfoViewControllerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint     *toolbarHeightConstraint;

@property (strong, nonatomic) LoginManagerCore *loginManagerCore;
@property (strong, nonatomic) MBProgressHUD    *progressHud;
@property (assign, nonatomic) CGFloat          initialToolbarHeight;
@property (weak, nonatomic) IBOutlet UIView    *containerView;

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
    
    if (@available(iOS 11.0, *))
    {
        self.toolbarHeightConstraint.constant = self.initialToolbarHeight + self.view.safeAreaInsets.top;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupProgressHudComponent];
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
    
    if ([AFPAccountManager isPINAuthenticationSet])
    {
        [self performSegueWithIdentifier:kUIExtentionPinViewControllerSegueIdentifier
                                  sender:nil];
    }
    else if ([defaults objectForKey:kFileProviderAccountNotActivatedKey])
    {
        [self performSegueWithIdentifier:kUIExtentionAccountNotActivatedViewControllerSegueIdentifier
                                  sender:nil];
    }
    else
    {
        AccountManager *accountManager = [AccountManager sharedManager];
        [accountManager loadAccountsFromKeychain];
        
        if (accountManager.selectedAccount)
        {
            __weak typeof(self) weakSelf = self;
            [self.loginManagerCore attemptLoginToAccount:accountManager.selectedAccount
                                               networkId:accountManager.selectedAccount.selectedNetworkId
                                         completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                                             __strong typeof(self) strongSelf = weakSelf;
                                             
                                             if (alfrescoSession)
                                             {
                                                 [[AccountManager sharedManager] saveAccountsToKeychain];
                                                 [strongSelf.extensionContext completeRequest];
                                             }
            }];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([kUIExtentionPinViewControllerSegueIdentifier isEqualToString:segue.identifier] ||
        [kUIExtentionBasicAuthViewControllerSegueIdentifier isEqualToString:segue.identifier] ||
        [kUIExtentionAccountNotActivatedViewControllerSegueIdentifier isEqualToString:segue.identifier])
    {
        AFPUIInfoViewController *infoViewController = (AFPUIInfoViewController *)segue.destinationViewController;
        infoViewController.delegate = self;
        
        if ([kUIExtentionPinViewControllerSegueIdentifier isEqualToString:segue.identifier])
        {
            infoViewController.controllerType = AFPUIInfoViewControllerTypePIN;
        }
        else if ([kUIExtentionAccountNotActivatedViewControllerSegueIdentifier isEqualToString:segue.identifier])
        {
            infoViewController.controllerType = AFPUIInfoViewControllerTypeAccountNotActivated;
        }
        else
        {
            infoViewController.controllerType = AFPUIInfoViewControllerTypeBasicAuth;
        }
    }
}

#pragma mark - Actions

- (IBAction)onCancel:(id)sender
{
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

- (void)userDidTapOnURL:(NSURL *)URL
{
    NSExtensionContext *extensionContext = self.extensionContext;
    [extensionContext openURL:URL completionHandler:nil];
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
    [self addChildViewController:viewController];
    viewController.view.frame = self.containerView.bounds;
    [self.containerView addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)showSignInAlertWithSignedInBlock:(void (^)(void))completionBlock
{
    [self performSegueWithIdentifier:kUIExtentionBasicAuthViewControllerSegueIdentifier
                              sender:nil];
}

- (void)displayLoginViewControllerWithAccount:(UserAccount *)account
                                     username:(NSString *)username
{
    [self performSegueWithIdentifier:kUIExtentionBasicAuthViewControllerSegueIdentifier
                              sender:nil];
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

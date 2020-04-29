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
 
#import "OnboardingViewController.h"
#import "UniversalDevice.h"
#import "NavigationViewController.h"
#import "AccountTypeSelectionViewController.h"
#import "RootRevealViewController.h"
#import "WebBrowserViewController.h"
#import "AccountDetailsViewController.h"

static CGFloat const kButtonCornerRadius = 5.0f;

@interface OnboardingViewController () <AccountFlowDelegate>

@property (nonatomic, weak) IBOutlet UIButton *useExistingAccountButton;
@property (nonatomic, weak) IBOutlet UIButton *closeWelcomeScreenButton;
@property (nonatomic, weak) IBOutlet UIButton *helpButton;
@property (nonatomic, assign) BOOL needsResetAppZoomLevel;

@end

@implementation OnboardingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.useExistingAccountButton.backgroundColor = [UIColor appTintColor];
    self.useExistingAccountButton.layer.cornerRadius = kButtonCornerRadius;
    
    [self.closeWelcomeScreenButton setImage:[[UIImage imageNamed:@"closeButton.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeWelcomeScreenButton.tintColor = [UIColor blackColor];
    
    [self.helpButton setTitleColor:[UIColor appTintColor] forState:UIControlStateNormal];
    
    self.view.backgroundColor = [UIColor onboardingOffWhiteColor];
    
    [self localiseUI];
    [self setAccessibilityIdentifiers];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.needsResetAppZoomLevel)
    {
        self.needsResetAppZoomLevel = NO;
        [Utility resetAppZoomLevelWithCompletionBlock:NULL];
    }
    [super viewWillAppear:animated];
}

#pragma mark - Private Functions

- (void)removeControllerFromParentController
{
    RootRevealViewController *parentViewController = (RootRevealViewController *)self.parentViewController;
    if((parentViewController.hasOverlayController) && ([parentViewController.overlayedViewController isKindOfClass:[OnboardingViewController class]]))
    {
        [parentViewController removeOverlayedViewControllerWithAnimation:YES];
    }
}

- (void)localiseUI
{
    [self.useExistingAccountButton setTitle:NSLocalizedString(@"onboarding.setup.existing.account.button.title", @"I already have an account") forState:UIControlStateNormal];
    [self.helpButton setTitle:NSLocalizedString(@"onboarding.help.button.title", @"Help") forState:UIControlStateNormal];
}

- (void)setAccessibilityIdentifiers
{
    self.view.accessibilityIdentifier = kOnboardingVCViewIdentifier;
    self.closeWelcomeScreenButton.accessibilityIdentifier = kOnboardingVCCloseButtonIdentifier;
    self.useExistingAccountButton.accessibilityIdentifier = kOnboardingVCLoginButtonIdentifier;
    self.helpButton.accessibilityIdentifier = kOnboardingVCHelpButtonIdentifier;
}

#pragma mark - IBAction Functions

- (IBAction)closeButtonPressed:(id)sender
{
    [self removeControllerFromParentController];
}

- (IBAction)useExistingAccountButtonPressed:(id)sender
{
    UIButton *addAccountButton = (UIButton *)sender;
    addAccountButton.enabled = NO;
    
    AccountDetailsViewController *accountDetailsViewController = [[AccountDetailsViewController alloc] initWithDataSourceType:AccountDataSourceTypeNewAccountServer account:nil configuration:nil session:nil];
    accountDetailsViewController.delegate = self;
    NavigationViewController *accountDetailsNavController = [[NavigationViewController alloc] initWithRootViewController:accountDetailsViewController];
    [UniversalDevice displayModalViewController:accountDetailsNavController onController:self withCompletionBlock:nil];
    [Utility zoomAppLevelOutWithCompletionBlock:^{
        addAccountButton.enabled = YES;
    }];

    
    [Utility zoomAppLevelOutWithCompletionBlock:^{
        addAccountButton.enabled = YES;
    }];
}

- (IBAction)helpButtonPressed:(id)sender
{
    NSString *helpURLString = [NSString stringWithFormat:kAlfrescoHelpURLString, [Utility helpURLLocaleIdentifierForAppLocale]];
    NSString *fallbackURLString = [NSString stringWithFormat:kAlfrescoHelpURLString, [Utility helpURLLocaleIdentifierForLocale:kAlfrescoISO6391EnglishCode]];
    WebBrowserViewController *helpViewController = [[WebBrowserViewController alloc] initWithURLString:helpURLString
                                                                              initialFallbackURLString:fallbackURLString
                                                                                          initialTitle:NSLocalizedString(@"help.title", @"Help Title")
                                                                                 errorLoadingURLString:nil];
    NavigationViewController *helpNavigationController = [[NavigationViewController alloc] initWithRootViewController:helpViewController];
    
    [self presentViewController:helpNavigationController animated:YES completion:nil];
    [Utility zoomAppLevelOutWithCompletionBlock:^{
        self.needsResetAppZoomLevel = YES;
    }];
}

#pragma mark - AccountTypeSelectionViewControllerDelegate Functions

- (void)accountFlowWillDismiss:(AccountTypeSelectionViewController *)accountTypeSelectionViewController accountAdded:(UserAccount*)accountAdded
{
    [Utility resetAppZoomLevelWithCompletionBlock:NULL];
    if (accountAdded)
    {
        [self removeControllerFromParentController];
    }
}

@end

//
//  OnboardingViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 25/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "OnboardingViewController.h"
#import "Utility.h"
#import "UniversalDevice.h"
#import "NavigationViewController.h"
#import "CloudSignUpViewController.h"
#import "AccountInfoViewController.h"
#import "RootRevealControllerViewController.h"

@interface OnboardingViewController () <CloudSignUpViewControllerDelegate, AccountInfoViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *createCloudAccountButton;
@property (nonatomic, weak) IBOutlet UIButton *useExistingAccountButton;
@property (nonatomic, weak) IBOutlet UIButton *closeWelcomeScreenButton;
@property (nonatomic, weak) IBOutlet UIButton *helpButton;

@end

@implementation OnboardingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.createCloudAccountButton setBackgroundImage:[[UIImage imageNamed:@"onboarding-blue.png"] stretchableImageWithLeftCapWidth:12.0f topCapHeight:12.0f] forState:UIControlStateNormal];
    [self.useExistingAccountButton setBackgroundImage:[[UIImage imageNamed:@"onboarding-grey.png"] stretchableImageWithLeftCapWidth:12.0f topCapHeight:12.0f] forState:UIControlStateNormal];
    
    [self localiseUI];
}

#pragma mark - Private Functions

- (void)removeControllerFromParentController
{
    RootRevealControllerViewController *parentViewController = (RootRevealControllerViewController *)self.parentViewController;
    [parentViewController removeOverlayedViewController];
}

- (void)localiseUI
{
    [self.createCloudAccountButton setTitle:NSLocalizedString(@"onboarding.setup.cloud.button.title", @"Signup for cloud") forState:UIControlStateNormal];
    [self.useExistingAccountButton setTitle:NSLocalizedString(@"onboarding.setup.existing.account.button.title", @"Use existing account") forState:UIControlStateNormal];
    [self.helpButton setTitle:NSLocalizedString(@"onboarding.help.button.title", @"Help button text") forState:UIControlStateNormal];
}

#pragma mark - IBAction Functions

- (IBAction)closeButtonPressed:(id)sender
{
    [self removeControllerFromParentController];
}

- (IBAction)createCloudAccountButtonPressed:(id)sender
{
    UIButton *createButton = (UIButton *)sender;
    createButton.enabled = NO;
    
    CloudSignUpViewController *cloudSignupViewController = [[CloudSignUpViewController alloc] init];
    cloudSignupViewController.delegate = self;
    NavigationViewController *cloudNavController = [[NavigationViewController alloc] initWithRootViewController:cloudSignupViewController];
    
    [Utility zoomAppLevelOutWithCompletionBlock:^{
        createButton.enabled = YES;
        [UniversalDevice displayModalViewController:cloudNavController onController:self withCompletionBlock:nil];
    }];
}

- (IBAction)useExistingAccountButtonPressed:(id)sender
{
    UIButton *addAccountButton = (UIButton *)sender;
    addAccountButton.enabled = NO;
    
    AccountInfoViewController *existingAccountViewController = [[AccountInfoViewController alloc] initWithAccount:nil accountActivityType:AccountActivityTypeNewAccount];
    existingAccountViewController.delegate = self;
    NavigationViewController *existingAccountNavController = [[NavigationViewController alloc] initWithRootViewController:existingAccountViewController];
    
    [Utility zoomAppLevelOutWithCompletionBlock:^{
        addAccountButton.enabled = YES;
        [UniversalDevice displayModalViewController:existingAccountNavController onController:self withCompletionBlock:nil];
    }];
}

- (IBAction)helpButtonPressed:(id)sender
{
    
}

#pragma mark - CloudSignUpViewControllerDelegate Functions

- (void)cloudSignupControllerDidDismiss:(CloudSignUpViewController *)controller
{
    [Utility resetAppZoomLevelWithCompletionBlock:nil];
}

#pragma mark - AccountInfoViewControllerDelegate Functions

- (void)accountInfoViewControllerDidDismiss:(AccountInfoViewController *)controller
{
    [Utility resetAppZoomLevelWithCompletionBlock:nil];
}

- (void)accountInfoViewController:(AccountInfoViewController *)controller didDismissAfterAddingAccount:(UserAccount *)account
{
    [Utility resetAppZoomLevelWithCompletionBlock:nil];
    [self removeControllerFromParentController];
}

@end

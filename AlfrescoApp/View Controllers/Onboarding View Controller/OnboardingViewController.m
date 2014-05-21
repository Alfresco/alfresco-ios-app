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
#import "AccountTypeSelectionViewController.h"
#import "RootRevealControllerViewController.h"
#import "WebBrowserViewController.h"

static CGFloat const kButtonCornerRadius = 5.0f;

@interface OnboardingViewController () <CloudSignUpViewControllerDelegate, AccountTypeSelectionViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *createCloudAccountButton;
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
    
    self.createCloudAccountButton.backgroundColor = [UIColor whiteColor];
    self.createCloudAccountButton.layer.cornerRadius = kButtonCornerRadius;
    
    [self.closeWelcomeScreenButton setImage:[[UIImage imageNamed:@"closeButton.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeWelcomeScreenButton.tintColor = [UIColor blackColor];
    
    [self.helpButton setTitleColor:[UIColor appTintColor] forState:UIControlStateNormal];
    
    self.view.backgroundColor = [UIColor onboardingOffWhiteColor];
    
    [self localiseUI];
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
    RootRevealControllerViewController *parentViewController = (RootRevealControllerViewController *)self.parentViewController;
    [parentViewController removeOverlayedViewController];
}

- (void)localiseUI
{
    [self.createCloudAccountButton setTitle:NSLocalizedString(@"onboarding.setup.cloud.button.title", @"Sign up for Alfresco Cloud") forState:UIControlStateNormal];
    [self.useExistingAccountButton setTitle:NSLocalizedString(@"onboarding.setup.existing.account.button.title", @"I already have an account") forState:UIControlStateNormal];
    [self.helpButton setTitle:NSLocalizedString(@"onboarding.help.button.title", @"Help") forState:UIControlStateNormal];
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
    
    [UniversalDevice displayModalViewController:cloudNavController onController:self withCompletionBlock:nil];
    [Utility zoomAppLevelOutWithCompletionBlock:^{
        createButton.enabled = YES;
    }];
}

- (IBAction)useExistingAccountButtonPressed:(id)sender
{
    UIButton *addAccountButton = (UIButton *)sender;
    addAccountButton.enabled = NO;
    
    AccountTypeSelectionViewController *existingAccountViewController = [[AccountTypeSelectionViewController alloc] initWithDelegate:self];
    NavigationViewController *existingAccountNavController = [[NavigationViewController alloc] initWithRootViewController:existingAccountViewController];
    
    [UniversalDevice displayModalViewController:existingAccountNavController onController:self withCompletionBlock:nil];
    [Utility zoomAppLevelOutWithCompletionBlock:^{
        addAccountButton.enabled = YES;
    }];
}

- (IBAction)helpButtonPressed:(id)sender
{
    NSURL *helpGuideURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"UserGuide" ofType:@"pdf"]];
    NSURL *errorWebPageURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"HelpErrorPage" ofType:@"html" inDirectory:@"Help Error"]];
    WebBrowserViewController *helpViewController = [[WebBrowserViewController alloc] initWithURL:helpGuideURL
                                                                                    initialTitle:NSLocalizedString(@"help.title", @"Help Title")
                                                                                 errorLoadingURL:errorWebPageURL];
    // This will need to be readded once we use online help
//    NSString *errorWebPage = [[NSBundle mainBundle] pathForResource:@"HelpErrorPage" ofType:@"html" inDirectory:@"Help Error"];
//    WebBrowserViewController *helpViewController = [[WebBrowserViewController alloc] initWithURLString:kAlfrescoHelpURLString
//                                                                                          initialTitle:NSLocalizedString(@"help.title", @"Help Title")
//                                                                                 errorLoadingURLString:errorWebPage];
    NavigationViewController *helpNavigationController = [[NavigationViewController alloc] initWithRootViewController:helpViewController];
    
    [self presentViewController:helpNavigationController animated:YES completion:nil];
    [Utility zoomAppLevelOutWithCompletionBlock:^{
        self.needsResetAppZoomLevel = YES;
    }];
}

#pragma mark - CloudSignUpViewControllerDelegate Functions

- (void)cloudSignupControllerWillDismiss:(CloudSignUpViewController *)controller
{
    [Utility resetAppZoomLevelWithCompletionBlock:NULL];
}

#pragma mark - AccountTypeSelectionViewControllerDelegate Functions

- (void)accountTypeSelectionViewControllerWillDismiss:(AccountTypeSelectionViewController *)accountTypeSelectionViewController accountAdded:(BOOL)accountAdded
{
    [Utility resetAppZoomLevelWithCompletionBlock:NULL];
    if (accountAdded)
    {
        [self removeControllerFromParentController];
    }
}

@end

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

#import "PersonProfileViewController.h"
#import "UIColor+Custom.h"
#import "AvatarManager.h"
#import "RootRevealViewController.h"
#import "UniversalDevice.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "ContactDetailView.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

static CGFloat const kFadeSpeed = 0.3f;
static CGFloat const kAvatarImageViewCornerRadius = 10.0f;

typedef NS_ENUM(NSUInteger, ContactInformationType)
{
    ContactInformationTypeEmail,
    ContactInformationTypeSkype,
    ContactInformationTypeInstantMessage,
    ContactInformationTypePhone,
    ContactInformationTypeMobile
};

@interface ContactInformation : NSObject
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, strong) NSString *contactInformation;
@property (nonatomic, assign) ContactInformationType contactType;
- (instancetype)initWithTitleText:(NSString *)title contactInformation:(NSString *)contactInformation image:(UIImage *)image contactType:(ContactInformationType)contactType;
@end

@implementation ContactInformation
- (instancetype)initWithTitleText:(NSString *)title contactInformation:(NSString *)contactInformation image:(UIImage *)image contactType:(ContactInformationType)contactType
{
    self = [self init];
    if (self)
    {
        self.image = image;
        self.titleText = title;
        self.contactInformation = contactInformation;
        self.contactType = contactType;
    }
    return self;
}
@end

@interface PersonProfileViewController () <MFMailComposeViewControllerDelegate>
// Layout Constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *summaryHeightConstraint;
// IBOutlets
@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *nameTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *companyTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *summaryTitleTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *summaryValueTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *contactInfomationTitleTextLabel;
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *underlineViews;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *summaryContainerView;
@property (nonatomic, weak) IBOutlet UIView *contactDetailsListViewContainer;
// Model
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoPerson *person;
@property (nonatomic, strong) NSArray *availableContactInformation;
// Services
@property (nonatomic, strong) AlfrescoPersonService *personService;
@end

@implementation PersonProfileViewController

- (instancetype)initWithUsername:(NSString *)username session:(id<AlfrescoSession>)session
{
    self = [self init];
    if (self)
    {
        self.username = username;
        self.session = session;
        [self createServicesWithSession:session];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!IS_IPAD && !self.presentingViewController)
    {
        UIBarButtonItem *hamburgerButtom = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger.png"] style:UIBarButtonItemStylePlain target:self action:@selector(expandRootRevealController)];
        if (self.navigationController.viewControllers.firstObject == self)
        {
            self.navigationItem.leftBarButtonItem = hamburgerButtom;
        }
    }
    
    [self initialViewSetup];
    
    if (self.person)
    {
        [self updateViewWithPerson:self.person];
    }
    else
    {
        [self retrievePersonForUsername:self.username];
    }
}

#pragma mark - Private Methods

- (void)createServicesWithSession:(id<AlfrescoSession>)session
{
    self.personService = [[AlfrescoPersonService alloc] initWithSession:session];
}

- (void)retrievePersonForUsername:(NSString *)username
{
    // Hide the content
    [self showScrollView:NO aminated:YES];
    
    // Display progress
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:progressHUD];
    progressHUD.removeFromSuperViewOnHide = YES;
    [progressHUD show:YES];
    
    // Get the user
    [self.personService retrievePersonWithIdentifier:self.username completionBlock:^(AlfrescoPerson *person, NSError *error) {
        [progressHUD hide:YES];
        if (error)
        {
            NSString *errorTitle = NSLocalizedString(@"error.person.profile.no.profile.title", @"Profile Error Title");
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.person.profile.no.profile.message", @"Profile Error Message"), self.username];
            displayErrorMessageWithTitle(errorMessage, errorTitle);
        }
        else
        {
            self.person = person;
            [self updateViewWithPerson:person];
            [self showScrollView:YES aminated:YES];
        }
    }];
}

- (void)initialViewSetup
{
    self.avatarImageView.layer.cornerRadius = kAvatarImageViewCornerRadius;
    self.summaryTitleTextLabel.text = NSLocalizedString(@"person.profile.view.controller.header.title.summary", @"Summary").uppercaseString;
    self.summaryTitleTextLabel.textColor = [UIColor appTintColor];
    self.contactInfomationTitleTextLabel.text = NSLocalizedString(@"person.profile.view.controller.header.title.contact.information", @"Contact Info").uppercaseString;
    self.contactInfomationTitleTextLabel.textColor = [UIColor appTintColor];
    
    for (UIView *underlineView in self.underlineViews)
    {
        underlineView.backgroundColor = [UIColor appTintColor];
    }
    
    [self showScrollView:NO aminated:NO];
    
    [self.view layoutIfNeeded];
}

- (void)updateViewWithPerson:(AlfrescoPerson *)person
{
    self.title = (person.fullName) ?: self.username;
    self.nameTextLabel.text = (person.fullName) ?: self.username;
    self.titleTextLabel.text = person.jobTitle;
    self.companyTextLabel.text = person.company.name;
    
    // If there is no summary, hide this view
    if (!person.summary)
    {
        self.summaryHeightConstraint = [NSLayoutConstraint constraintWithItem:self.summaryContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
        [self.summaryContainerView addConstraint:self.summaryHeightConstraint];
    }
    else if (self.summaryHeightConstraint)
    {
        [self.summaryContainerView removeConstraint:self.summaryHeightConstraint];
    }
    
    self.summaryValueTextLabel.text = (person.summary) ?: NSLocalizedString(@"person.profile.view.controller.value.summary.no.summary", @"No Summary");
    
    NSArray *availableContactInformation = [self availableContactInformationFromPerson:person];
    self.availableContactInformation = availableContactInformation;
    [self.contactDetailsListViewContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setupSubviewsInContainer:self.contactDetailsListViewContainer forContactInformation:availableContactInformation];
    
    UIImage *avatar = [[AvatarManager sharedManager] avatarForIdentifier:self.username];
    if (avatar)
    {
        self.avatarImageView.image = avatar;
    }
    else
    {
        UIImage *placeholderImage = [UIImage imageNamed:@"avatar.png"];
        self.avatarImageView.image = placeholderImage;
        [[AvatarManager sharedManager] retrieveAvatarForPersonIdentifier:self.username session:self.session completionBlock:^(UIImage *avatarImage, NSError *avatarError) {
            if (avatarImage)
            {
                self.avatarImageView.image = avatarImage;
            }
        }];
    }
}

- (NSArray *)availableContactInformationFromPerson:(AlfrescoPerson *)person
{
    BOOL canSendEmail = [MFMailComposeViewController canSendMail];
    BOOL canMakeCalls = [self canDeviceMakeVoiceCalls];
    BOOL skypeInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kSkypeURLScheme]];
    
    NSMutableArray *contactDetails = [NSMutableArray array];
    
    ContactInformation *contactInformation = nil;
    if (person.email && ![person.email isEqualToString:@""])
    {
        contactInformation = [[ContactInformation alloc] initWithTitleText:NSLocalizedString(@"person.profile.view.controller.contact.information.type.email.title", @"Email")
                                                        contactInformation:person.email
                                                                     image:(canSendEmail) ? [[UIImage imageNamed:@"contact-details-email.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil
                                                               contactType:ContactInformationTypeEmail];
        [contactDetails addObject:contactInformation];
    }
    
    if (person.skypeId && ![person.skypeId isEqualToString:@""])
    {
        contactInformation = [[ContactInformation alloc] initWithTitleText:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.title", @"Skype")
                                                        contactInformation:person.skypeId
                                                                     image:(skypeInstalled) ? [[UIImage imageNamed:@"contact-details-skype.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil
                                                               contactType:ContactInformationTypeSkype];
        [contactDetails addObject:contactInformation];
    }
    
    if (person.instantMessageId && ![person.instantMessageId isEqualToString:@""])
    {
        contactInformation = [[ContactInformation alloc] initWithTitleText:NSLocalizedString(@"person.profile.view.controller.contact.information.type.instant.message.title", @"Instant Messaging")
                                                        contactInformation:person.instantMessageId
                                                                     image:nil
                                                               contactType:ContactInformationTypeInstantMessage];
        [contactDetails addObject:contactInformation];
    }
    
    if (person.telephoneNumber && ![person.telephoneNumber isEqualToString:@""])
    {
        contactInformation = [[ContactInformation alloc] initWithTitleText:NSLocalizedString(@"person.profile.view.controller.contact.information.type.telephone.title", @"Telephone")
                                                        contactInformation:person.telephoneNumber
                                                                     image:(canMakeCalls) ? [[UIImage imageNamed:@"contact-details-phone.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil
                                                               contactType:ContactInformationTypePhone];
        [contactDetails addObject:contactInformation];
    }
    
    if (person.mobileNumber && ![person.mobileNumber isEqualToString:@""])
    {
        contactInformation = [[ContactInformation alloc] initWithTitleText:NSLocalizedString(@"person.profile.view.controller.contact.information.type.mobile.title", @"Mobile")
                                                        contactInformation:person.mobileNumber
                                                                     image:(canMakeCalls) ? [[UIImage imageNamed:@"contact-details-phone.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil
                                                               contactType:ContactInformationTypeMobile];
        [contactDetails addObject:contactInformation];
    }
    
    return contactDetails;
}

- (void)setupSubviewsInContainer:(UIView *)containerView forContactInformation:(NSArray *)contactInformation
{
    for (ContactInformation *contactInfo in contactInformation)
    {
        ContactDetailView *contactInfoView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ContactDetailView class]) owner:self options:nil].lastObject;
        contactInfoView.translatesAutoresizingMaskIntoConstraints = NO;
        contactInfoView.titleLabel.textColor = [UIColor appTintColor];
        contactInfoView.titleLabel.text = contactInfo.titleText;
        contactInfoView.valueLabel.text = contactInfo.contactInformation;
        [contactInfoView.actionButton setImage:contactInfo.image forState:UIControlStateNormal];
        [contactInfoView.actionButton addTarget:self action:@selector(contactInformationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [containerView addSubview:contactInfoView];
    }
    
    // Constraint setup
    NSArray *subviews = containerView.subviews;
    NSMutableArray *constraints = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < subviews.count; i++)
    {
        UIView *currentSubview = subviews[i];
        
        NSLayoutConstraint *topConstraint = nil;
        if (currentSubview == subviews.firstObject)
        {
            topConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:currentSubview.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
        }
        else
        {
            UIView *previousSubview = subviews[i-1];
            topConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:previousSubview attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
        }
        
        NSLayoutConstraint *bottomConstraint = nil;
        if (currentSubview == subviews.lastObject)
        {
            bottomConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:currentSubview.superview attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
        }
        else
        {
            UIView *nextSubview = subviews[i+1];
            bottomConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:nextSubview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
        }
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:currentSubview.superview attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:currentSubview.superview attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f];
        
        [constraints addObject:topConstraint];
        [constraints addObject:bottomConstraint];
        [constraints addObject:leftConstraint];
        [constraints addObject:rightConstraint];
    }
    
    // Add constraints
    [containerView addConstraints:constraints];
}

- (void)expandRootRevealController
{
    [(RootRevealViewController *)[UniversalDevice revealViewController] expandViewController];
}

- (void)showScrollView:(BOOL)show aminated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:kFadeSpeed animations:^{
            CGFloat transitionAlphaValue = (show) ? 1.0f : 0.0f;
            self.scrollView.alpha = transitionAlphaValue;
        } completion:^(BOOL finished) {
            self.scrollView.hidden = !show;
        }];
    }
    else
    {
        self.scrollView.hidden = !show;
    }
}

- (void)contactInformationButtonPressed:(UIButton *)button
{
    NSArray *contactViews = self.contactDetailsListViewContainer.subviews;
    UIView *buttonSuperview = button.superview;
    NSInteger index = [contactViews indexOfObject:buttonSuperview];

    ContactInformation *selectedContactInformation = self.availableContactInformation[index];
    
    switch (selectedContactInformation.contactType)
    {
        case ContactInformationTypeEmail:
        {
            MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
            mailViewController.mailComposeDelegate = self;
            
            [mailViewController setToRecipients:@[selectedContactInformation.contactInformation]];
            
            // Content body template
            NSString *footer = [NSString stringWithFormat:NSLocalizedString(@"mail.footer", @"Sent from..."), @"<a href=\"http://itunes.apple.com/app/alfresco/id459242610?mt=8\">Alfresco Mobile</a>"];
            NSString *messageBody = [NSString stringWithFormat:@"<br><br>%@", footer];
            [mailViewController setMessageBody:messageBody isHTML:YES];
            mailViewController.modalPresentationStyle = UIModalPresentationPageSheet;
            
            [self presentViewController:mailViewController animated:YES completion:nil];
        }
        break;
            
        case ContactInformationTypeSkype:
        {
            void (^handleSkypeRequestWithSkypeCommunicationType)(NSString *) = ^(NSString *contactType) {
                BOOL installed = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kSkypeURLScheme]];
                if(installed)
                {
                    NSString *skypeString = [NSString stringWithFormat:@"%@%@?%@", kSkypeURLScheme, selectedContactInformation.contactInformation, contactType];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:skypeString]];
                }
                else
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kSkypeAppStoreURL]];
                }
            };
            
            // Actions
            UIAlertAction *chatAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.chat", @"Chat") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                handleSkypeRequestWithSkypeCommunicationType(kSkypeURLCommunicationTypeChat);
            }];
            UIAlertAction *callAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.call", @"Call") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                handleSkypeRequestWithSkypeCommunicationType(kSkypeURLCommunicationTypeCall);
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil];
            
            // Display options
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.title", @"Skype")
                                                                                     message:[NSString stringWithFormat:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.message", @"Message"), selectedContactInformation.contactInformation]
                                                                              preferredStyle:UIAlertControllerStyleActionSheet];
            [alertController addAction:chatAction];
            [alertController addAction:callAction];
            [alertController addAction:cancelAction];
            
            alertController.popoverPresentationController.sourceView = buttonSuperview;
            alertController.popoverPresentationController.sourceRect = button.frame;
            
            [self presentViewController:alertController animated:YES completion:nil];
        }
        break;
            
        case ContactInformationTypePhone:
        {
            NSString *phoneNumber = [kPhoneURLScheme stringByAppendingString:selectedContactInformation.contactInformation];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
        }
        break;
            
        case ContactInformationTypeMobile:
        {
            NSString *mobileNumber = [kPhoneURLScheme stringByAppendingString:selectedContactInformation.contactInformation];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mobileNumber]];
        }
        break;
            
        default:
            break;
    }
}

- (BOOL)canDeviceMakeVoiceCalls
{
    BOOL canMakeCalls = NO;
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kPhoneURLScheme]])
    {
        CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = networkInfo.subscriberCellularProvider;
        NSString *mobileNetworkCode = carrier.mobileNetworkCode;
        if (mobileNetworkCode.length != 0)
        {
            canMakeCalls = YES;
        }
    }
    
    return canMakeCalls;
}

#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultSent:
        case MFMailComposeResultCancelled:
        {
            [controller dismissViewControllerAnimated:YES completion:nil];
        }
        break;
          
        case MFMailComposeResultFailed:
        {
            [controller dismissViewControllerAnimated:YES completion:^{
                displayErrorMessageWithTitle(@"Unable to send the email", @"Email Failed");
            }];
        }
        break;
            
        default:
            break;
    }
}

@end

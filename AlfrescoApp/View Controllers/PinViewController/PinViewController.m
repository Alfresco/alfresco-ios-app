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

#import "PinViewController.h"
#import "BulletView.h"
#import "SettingConstants.h"
#import "PinBulletsView.h"
#import "KeychainUtils.h"
#import "SharedConstants.h"
#import "PreferenceManager.h"

#import "AnalyticsConstants.h"

NSString * const kShowKeyboardInPinScreenNotification = @"ShowKeyboardInPinScreenNotification";
NSString * const kAppResetedNotification = @"AppResetedNotification";

@interface PinViewController ()

@property (nonatomic) PinFlow pinFlow;
@property (nonatomic, strong) PinFlowCompletionBlock completionBlock;
@property (nonatomic) BOOL animatedDismiss;
@property (nonatomic) BOOL ownWindow;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet PinBulletsView *bulletsView;

@end

@implementation PinViewController
{
    NSMutableString *_oldPin;
    NSMutableString *_enteredPin;
    NSMutableString *_reenteredPin;
    
    NSUInteger _step;
    NSInteger _remainingAttempts;
    BOOL _shouldAllowPinEntry;
}

#pragma mark - Class Methods

+ (UINavigationController *)pinNavigationViewControllerWithFlow:(PinFlow)pinFlow completionBlock:(PinFlowCompletionBlock)completionBlock
{
    return [PinViewController pinNavigationViewControllerWithFlow:pinFlow animatedDismiss:YES completionBlock:completionBlock];
}

+ (UINavigationController *)pinNavigationViewControllerWithFlow:(PinFlow)pinFlow animatedDismiss:(BOOL)animatedDismiss completionBlock:(PinFlowCompletionBlock)completionBlock
{
    return [PinViewController pinNavigationViewControllerWithFlow:pinFlow inOwnWindow:NO animatedDismiss:animatedDismiss completionBlock:completionBlock];
}

+ (UINavigationController *)pinNavigationViewControllerWithFlow:(PinFlow)pinFlow inOwnWindow:(BOOL)ownWindow completionBlock:(PinFlowCompletionBlock)completionBlock
{
    return [PinViewController pinNavigationViewControllerWithFlow:pinFlow inOwnWindow:ownWindow animatedDismiss:YES completionBlock:completionBlock];
}

+ (UINavigationController *)pinNavigationViewControllerWithFlow:(PinFlow)pinFlow inOwnWindow:(BOOL)ownWindow animatedDismiss:(BOOL)animatedDismiss completionBlock:(PinFlowCompletionBlock)completionBlock
{
    PinViewController *pinViewController = [[PinViewController alloc] init];
    pinViewController.pinFlow = pinFlow;
    pinViewController.completionBlock = completionBlock;
    pinViewController.animatedDismiss = animatedDismiss;
    pinViewController.ownWindow = ownWindow;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:pinViewController];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    navigationController.modalPresentationCapturesStatusBarAppearance = YES;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:pinViewController action:@selector(pressedCancelButton:)];
    pinViewController.navigationItem.rightBarButtonItem = cancelButton;
    
    if (pinFlow == PinFlowEnter)
    {
        [navigationController setNavigationBarHidden:YES animated:NO];
    }
    
    return navigationController;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowAnimated:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showKeyboardInPinScreen:) name:kShowKeyboardInPinScreenNotification object:nil];
    
    [self becomeFirstResponder];
    [self setup];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[PreferenceManager sharedManager] shouldSendDiagnostics])
    {
        [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewSettingsPasscode];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Orientation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self setupConstraints];
}

#pragma mark - Notification Handlers

- (void)showKeyboardInPinScreen:(NSNotification *)notification
{
    if (self.pinFlow != PinFlowEnter && _step == 1)
    {
        NSError *error;
        NSNumber *number = [KeychainUtils retrieveItemForKey:kRemainingAttemptsKey error:&error];
        _remainingAttempts = number ? number.integerValue : REMAINING_ATTEMPTS_MAX_VALUE;
        
        [self showNumberOfAttemptsRemaining];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self becomeFirstResponder];
    });
}

- (void)keyboardWillShowAnimated:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _containerHeightConstraint.constant = CGRectGetMinY(keyboardFrame)-64; // subtract nav bar and status bar
}

#pragma mark - UIResponder Methods

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma - UIKeyInput Methods

// Responders that implement the UIKeyInput protocol will be driven by the system-provided keyboard,
// which will be made available whenever a conforming responder becomes first responder.

/*
 A Boolean value that indicates whether the text-entry objects has any text.
 YES if the backing store has textual content, NO otherwise.
 */
- (BOOL)hasText
{
    NSMutableString *pin = [self pinInUse];
    
    return pin.length != 0;
}

/*
 Insert a character into the displayed text.
 Add the character text to your class’s backing store at the index corresponding to the cursor and redisplay the text.
 */
- (void)insertText:(NSString *)text
{
    if (_shouldAllowPinEntry == NO)
    {
        return;
    }

    if ([text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet].invertedSet].location != NSNotFound)
    {
        return;
    }
    
    if ((self.pinFlow == PinFlowSet && _step == 1) || (self.pinFlow == PinFlowChange && _step == 2))
    {
        _subtitleLabel.hidden = YES;
    }
    
    NSMutableString *pin = [self pinInUse];
    
    if (pin.length == 4)
    {
        return;
    }

    [pin appendString:text];
    
    [self fillBullets:YES];
    
    if (pin.length == 4)
    {
        [self validate];
    }
}

/*
 Delete a character from the displayed text.
 Remove the character just before the cursor from your class’s backing store and redisplay the text.
 */
- (void)deleteBackward
{
    NSMutableString *pin = [self pinInUse];
    
    if (pin.length == 0)
    {
        return;
    }
    
    [pin deleteCharactersInRange:NSMakeRange(pin.length - 1, 1)];
    
    [self fillBullets:YES];
}

#pragma mark - UITextInputTraits Methods

// Controls features of text widgets (or other custom objects that might wish
// to respond to keyboard input).

- (UIKeyboardType)keyboardType
{
    return UIKeyboardTypeNumberPad;
}

#pragma mark - Pin Flows Methods

- (void)validate
{
    switch (self.pinFlow)
    {
        case PinFlowChange:
            [self validateChangeFlow];
            break;
            
        case PinFlowEnter:
        case PinFlowVerify:
            [self validateEnterFlow];
            break;
            
        case PinFlowSet:
            [self validateSetFlow];
            break;
            
        case PinFlowUnset:
            [self validateUnsetFlow];
            break;
            
        default:
            break;
    }
}

- (void)validateChangeFlow
{
    if (_step == 1)
    {
        NSError *error;
        NSString *pin = [KeychainUtils retrieveItemForKey:kPinKey
                                                  inGroup:kSharedAppGroupIdentifier
                                                    error:&error];
        
        if ([_oldPin isEqualToString:pin])
        {
            _step ++;
            _shouldAllowPinEntry = NO;
            _subtitleLabel.hidden = YES;
            [KeychainUtils saveItem:@(REMAINING_ATTEMPTS_MAX_VALUE) forKey:kRemainingAttemptsKey error:&error];
            
            __weak typeof(self) weakSelf = self;
            
            // This delay allows the user to see the 4th bullet getting filled.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                __strong typeof(self) strongSelf = weakSelf;
                
                strongSelf.titleLabel.text = NSLocalizedString(@"settings.security.passcode.enter.new", @"Enter your new Alfresco passcode");
                [strongSelf fillBullets:NO];
                strongSelf->_shouldAllowPinEntry = YES;
            });
        }
        else
        {
            _remainingAttempts --;
            NSError *error;
            [KeychainUtils saveItem:@(_remainingAttempts) forKey:kRemainingAttemptsKey error:&error];
            
            __weak typeof(self) weakSelf = self;
            [_bulletsView shakeWithCompletionBlock:^{
                __strong typeof(self) strongSelf = weakSelf;
                
                if (strongSelf->_remainingAttempts == 0)
                {
                    [strongSelf unsetPinAndDismissWithCompletionBlock:^{
                        if (strongSelf.completionBlock)
                        {
                            strongSelf.completionBlock(PinFlowCompletionStatusReset);
                        }
                    }];
                }
                else
                {
                    strongSelf->_oldPin = [NSMutableString string];
                    
                    [strongSelf fillBullets:NO];
                    [strongSelf showNumberOfAttemptsRemaining];
                }
            }];
        }
    }
    else if (_step == 2)
    {
        _step ++;
        _shouldAllowPinEntry = NO;
        _subtitleLabel.hidden = YES;
        
        __weak typeof(self) weakSelf = self;
        // This delay allows the user to see the 4th bullet getting filled.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            
            strongSelf.titleLabel.text = NSLocalizedString(@"settings.security.passcode.re-enter.new", @"Re-enter your new passcode");
            [strongSelf fillBullets:NO];
            strongSelf->_shouldAllowPinEntry = YES;
        });
    }
    else if (_step == 3)
    {
        if ([_reenteredPin isEqualToString:_enteredPin])
        {
            NSError *error;
            [KeychainUtils saveItem:_enteredPin
                             forKey:kPinKey
                            inGroup:kSharedAppGroupIdentifier
                              error:&error];
            
            if (self.completionBlock)
            {
                self.completionBlock(PinFlowCompletionStatusSuccess);
            }

            [self dismissViewControllerAnimated:self.animatedDismiss completion:nil];
        }
        else
        {
            _titleLabel.text = NSLocalizedString(@"settings.security.passcode.enter.new", @"Enter your new Alfresco passcode");
            _subtitleLabel.text = NSLocalizedString(kSettingsSecurityPasscodeMissmatchString, @"Passcodes didn't match. Try again.");
            _subtitleLabel.hidden = NO;
            _step = 2;
            _enteredPin = [NSMutableString string];
            _reenteredPin = [NSMutableString string];
            
            __weak typeof(self) weakSelf = self;
            [_bulletsView shakeWithCompletionBlock:^{
                [weakSelf fillBullets:NO];
            }];
        }
    }
}

- (void)validateEnterFlow
{
    _titleLabel.text = NSLocalizedString(kSettingsSecurityPasscodeEnterString, @"Enter your Alfresco Passcode");
    
    NSError *error;
    NSString *pin = [KeychainUtils retrieveItemForKey:kPinKey
                                              inGroup:kSharedAppGroupIdentifier
                                                error:&error];
    __weak typeof(self) weakSelf = self;
    
    if ([_oldPin isEqualToString:pin])
    {
        _shouldAllowPinEntry = NO;
        _subtitleLabel.hidden = YES;
        [KeychainUtils saveItem:@(REMAINING_ATTEMPTS_MAX_VALUE) forKey:kRemainingAttemptsKey error:&error];
        
        // This will prevent hiding the keyboard in any other instance of PinViewController that may be underneath.
        [[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardInPinScreenNotification object:nil];

        if (_ownWindow)
        {
            if (weakSelf.completionBlock)
            {
                weakSelf.completionBlock(PinFlowCompletionStatusSuccess);
            }
        }
        else
        {
            [self dismissViewControllerAnimated:self.animatedDismiss completion:^{
                if (weakSelf.completionBlock)
                {
                    weakSelf.completionBlock(PinFlowCompletionStatusSuccess);
                }
            }];
        }
    }
    else
    {
        _remainingAttempts --;
        NSError *error;
        [KeychainUtils saveItem:@(_remainingAttempts) forKey:kRemainingAttemptsKey error:&error];
        
        [_bulletsView shakeWithCompletionBlock:^{
            __strong typeof(self) strongSelf = weakSelf;
            
            if (strongSelf->_remainingAttempts == 0)
            {
                if (strongSelf.completionBlock)
                {
                    strongSelf.completionBlock(PinFlowCompletionStatusReset);
                }
                
                [strongSelf unsetPinAndDismissWithCompletionBlock:nil];
            }
            else
            {
                strongSelf->_oldPin = [NSMutableString string];
                
                [strongSelf fillBullets:NO];
                [strongSelf showNumberOfAttemptsRemaining];
                
                if (strongSelf.completionBlock)
                {
                    strongSelf.completionBlock(PinFlowCompletionStatusFailure);
                }
            }
        }];
    }
}

- (void)validateSetFlow
{
    __weak typeof(self) weakSelf = self;
    
    if (_step == 1)
    {
        _step ++;
        _shouldAllowPinEntry = NO;
        
        // This delay allows the user to see the 4th bullet getting filled.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            
            strongSelf.titleLabel.text = NSLocalizedString(kSettingsSecurityPasscodeReenterString, @"Re-enter your Alfresco Passcode");
            [strongSelf fillBullets:NO];
            strongSelf->_shouldAllowPinEntry = YES;
        });
    }
    else
    {
        if ([_reenteredPin isEqualToString:_enteredPin])
        {
            NSError *error;
            [KeychainUtils saveItem:_enteredPin
                             forKey:kPinKey
                            inGroup:kSharedAppGroupIdentifier
                              error:&error];
            
            [KeychainUtils saveItem:@(REMAINING_ATTEMPTS_MAX_VALUE) forKey:kRemainingAttemptsKey error:&error];
            
            [self dismissViewControllerAnimated:self.animatedDismiss completion:^{
                if (weakSelf.completionBlock)
                {
                    weakSelf.completionBlock(PinFlowCompletionStatusSuccess);
                }
            }];
        }
        else
        {
            _titleLabel.text = NSLocalizedString(kSettingsSecurityPasscodeEnterString, @"Enter your Alfresco Passcode");
            _subtitleLabel.text = NSLocalizedString(kSettingsSecurityPasscodeMissmatchString, @"Passcodes didn't match. Try again.");
            _subtitleLabel.hidden = NO;
            _step = 1;
            _enteredPin = [NSMutableString string];
            _reenteredPin = [NSMutableString string];
            
            __weak typeof(self) weakSelf = self;
            [_bulletsView shakeWithCompletionBlock:^{
                [weakSelf fillBullets:NO];
            }];
        }
    }
}

- (void)validateUnsetFlow
{
    NSError *error;
    NSString *pin = [KeychainUtils retrieveItemForKey:kPinKey
                                              inGroup:kSharedAppGroupIdentifier
                                                error:&error];
    
    if ([_oldPin isEqualToString:pin])
    {
        if (self.completionBlock)
        {
            self.completionBlock(PinFlowCompletionStatusSuccess);
        }
        [self unsetPinAndDismissWithCompletionBlock:nil];
    }
    else
    {
        _remainingAttempts --;
        NSError *error;
        [KeychainUtils saveItem:@(_remainingAttempts) forKey:kRemainingAttemptsKey error:&error];
        
        __weak typeof(self) weakSelf = self;
        
        [_bulletsView shakeWithCompletionBlock:^{
            __strong typeof(self) strongSelf = weakSelf;
            
            if (strongSelf->_remainingAttempts == 0)
            {
                [strongSelf unsetPinAndDismissWithCompletionBlock:^{
                    if (strongSelf.completionBlock)
                    {
                        strongSelf.completionBlock(PinFlowCompletionStatusReset);
                    }
                }];
            }
            else
            {
                strongSelf->_oldPin = [NSMutableString string];
                
                [strongSelf fillBullets:NO];
                [strongSelf showNumberOfAttemptsRemaining];
            }
        }];
    }
}

#pragma mark -

- (NSMutableString *)pinInUse
{
    switch (self.pinFlow)
    {
        case PinFlowEnter:
        case PinFlowUnset:
        case PinFlowVerify:
            return _oldPin;
            
        case PinFlowChange:
            return _step == 1 ? _oldPin : (_step == 2 ? _enteredPin : _reenteredPin);
            break;
            
        case PinFlowSet:
            return _step == 1 ? _enteredPin : _reenteredPin;
            break;
            
        default:
            break;
    }
    
    return nil;
}

- (void)unsetPinAndDismissWithCompletionBlock:(void (^)(void))completionBlock
{
    NSError *error;
    [KeychainUtils saveItem:@(REMAINING_ATTEMPTS_MAX_VALUE) forKey:kRemainingAttemptsKey error:&error];
    [KeychainUtils deleteItemForKey:kPinKey
                            inGroup:kSharedAppGroupIdentifier
                              error:&error];
    
    [self dismissViewControllerAnimated:self.animatedDismiss completion:completionBlock];
}

- (void)showNumberOfAttemptsRemaining
{
    if (_remainingAttempts == REMAINING_ATTEMPTS_MAX_VALUE)
    {
        _subtitleLabel.text = @"";
    }
    else if (_remainingAttempts > 1)
    {
        NSString *attemptsRemainingFormat = NSLocalizedString(kSettingsSecurityPasscodeAttemptsMany, @"%d attempts remaining");
        _subtitleLabel.text = [NSString stringWithFormat:attemptsRemainingFormat, _remainingAttempts];
    }
    else
    {
        _subtitleLabel.text = NSLocalizedString(kSettingsSecurityPasscodeAttemptsOne, @"1 attempt remaining");
    }

    _subtitleLabel.hidden = NO;
}

- (void)fillBullets:(BOOL)fill
{
    [_bulletsView fillBullets:fill forPin:[self pinInUse]];
}

- (void)setup
{
    _step = 1;
    
    NSError *error;
    NSNumber *number = [KeychainUtils retrieveItemForKey:kRemainingAttemptsKey error:&error];
    _remainingAttempts = number ? number.integerValue : REMAINING_ATTEMPTS_MAX_VALUE;
    
    _shouldAllowPinEntry = YES;
    
    if (_remainingAttempts == 1)
    {
        [self showNumberOfAttemptsRemaining];
    }
    else
    {
        _subtitleLabel.hidden = YES;
    }
    
    switch (self.pinFlow)
    {
        case PinFlowChange:
            _titleLabel.text = NSLocalizedString(@"settings.security.passcode.enter.old", @"Enter your old Alfresco passcode");
            break;
            
        case PinFlowSet:
        case PinFlowUnset:
        case PinFlowEnter:
        case PinFlowVerify:
            _titleLabel.text = NSLocalizedString(kSettingsSecurityPasscodeEnterString, @"Enter your Alfresco Passcode");
            break;
            
        default:
            break;
    }
    
    [self setupConstraints];
    [self initializePinStrings];
    [self setupScreenTitle];
}

- (void)setupConstraints
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        UIInterfaceOrientation toOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
        _logoTopConstraint.constant = UIInterfaceOrientationIsPortrait(toOrientation) ? 140 : 40;
    }
    
    // Remove the logo for small screen devices (3.5" devices).
    if ([[UIScreen mainScreen] bounds].size.height < 568)
    {
        _logoHeightConstraint.constant = 0;
        _logoTopConstraint.constant = 0;
    }
    
    if (self.pinFlow == PinFlowEnter)
    {
        _logoTopConstraint.constant += 64;
    }
}

- (void)initializePinStrings
{
    switch (self.pinFlow)
    {
        case PinFlowSet:
            _enteredPin = [NSMutableString string];
            _reenteredPin = [NSMutableString string];
            break;
            
        case PinFlowEnter:
        case PinFlowUnset:
        case PinFlowVerify:
            _oldPin = [NSMutableString string];
            break;
            
        case PinFlowChange:
            _oldPin = [NSMutableString string];
            _enteredPin = [NSMutableString string];
            _reenteredPin = [NSMutableString string];
            break;
            
        default:
            break;
    }
}

- (void)setupScreenTitle
{
    switch (self.pinFlow)
    {
        case PinFlowSet:
        case PinFlowUnset:
            self.title = NSLocalizedString(kSettingsSecurityPasscodeSetTitle, @"Set Passcode");
            break;
            
        case PinFlowChange:
        case PinFlowEnter:
        case PinFlowVerify:
            self.title = NSLocalizedString(kSettingsSecurityPasscodeEnterTitle, @"Enter Passcode");
            break;
            
        default:
            break;
    }
}

- (PinFlow)pinFlow
{
    return _pinFlow;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    UIStatusBarStyle statusBarStyle = UIStatusBarStyleLightContent;
    
    if (_pinFlow == PinFlowEnter)
    {
        statusBarStyle = UIStatusBarStyleDefault;
    }
    
    return statusBarStyle;
}

#pragma mark - Actions

- (void)pressedCancelButton:(UIBarButtonItem *)sender
{
    __weak typeof(self) weakSelf = self;
    
    [self dismissViewControllerAnimated:self.animatedDismiss completion:^{
        if (weakSelf.completionBlock)
        {
            weakSelf.completionBlock(PinFlowCompletionStatusCancel);
        }
    }];
}

@end

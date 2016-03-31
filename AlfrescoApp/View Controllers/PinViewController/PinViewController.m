/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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
#import "PreferenceManager.h"
#import "PinBulletsView.h"
#import "KeychainUtils.h"
#import "SecurityManager.h"

@interface PinViewController ()

@property (nonatomic) PinFlow pinFlow;

@end

@implementation PinViewController
{
    __weak IBOutlet NSLayoutConstraint *_logoTopConstraint;
    __weak IBOutlet NSLayoutConstraint *_logoHeightConstraint;
    __weak IBOutlet NSLayoutConstraint *_titleLabelTopConstraint;
    __weak IBOutlet NSLayoutConstraint *_bulletsViewTopConstraint;
    __weak IBOutlet NSLayoutConstraint *_subtitleLabelTopConstraint;
    __weak IBOutlet UILabel *_titleLabel;
    __weak IBOutlet UILabel *_subtitleLabel;
    __weak IBOutlet PinBulletsView *_bulletsView;
    
    NSMutableString *_oldPin;
    NSMutableString *_enteredPin;
    NSMutableString *_reenteredPin;
    
    NSUInteger _step;
    NSInteger _remainingAttempts;
    BOOL _shouldAllowPinEntry;
}

#pragma mark - Class Methods

+ (UINavigationController *)pinNavigationViewControllerWithFlow:(PinFlow)pinFlow
{
    PinViewController *pinViewController = [[PinViewController alloc] init];
    pinViewController.pinFlow = pinFlow;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:pinViewController];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:pinViewController action:@selector(pressedCancelButton:)];
    pinViewController.navigationItem.rightBarButtonItem = cancelButton;
    
    return navigationController;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
    [self becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
    
    if (self.pinFlow == PinFlowSet && _step == 1)
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
}

- (void)validateEnterFlow
{
}

- (void)validateSetFlow
{
    if (_step == 1)
    {
        _step ++;
        _shouldAllowPinEntry = NO;
        
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _titleLabel.text = NSLocalizedString(kSettingsSecurityPasscodeReenterString, @"Re-enter your Alfresco Passcode");
            [weakSelf fillBullets:NO];
            _shouldAllowPinEntry = YES;
        });
    }
    else
    {
        if ([_reenteredPin isEqualToString:_enteredPin])
        {
            NSError *error;
            [KeychainUtils saveItem:_enteredPin forKey:kPinKey error:&error];
            [KeychainUtils saveItem:@(kRemainingAttemptsMaxValue) forKey:kRemainingAttemptsKey error:&error];
            
            [[PreferenceManager sharedManager] updatePreferenceToValue:@(YES) preferenceIdentifier:kSettingsSecurityUsePasscodeLockIdentifier];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            _titleLabel.text = NSLocalizedString(kSettingsSecurityPasscodeEnterString, @"Enter your Alfresco Passcode");
            _subtitleLabel.text = NSLocalizedString(kSettingsSecurityPasscodeMissmatchString, @"Passcodes did not match. Try again.");
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
    NSString *pin = [KeychainUtils retrieveItemForKey:kPinKey error:&error];
    
    if ([_oldPin isEqualToString:pin])
    {
        [self unsetPinAndDismiss];
    }
    else
    {
        _remainingAttempts --;
        NSError *error;
        [KeychainUtils saveItem:@(_remainingAttempts) forKey:kRemainingAttemptsKey error:&error];
        
        __weak typeof(self) weakSelf = self;
        
        [_bulletsView shakeWithCompletionBlock:^{
            if (_remainingAttempts == 0)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kSettingResetEntireApp object:nil];
                [weakSelf unsetPinAndDismiss];
            }
            else
            {
                _oldPin = [NSMutableString string];
                
                [weakSelf fillBullets:NO];
                [weakSelf showNumberOfAttemptsRemaining];
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

- (void)unsetPinAndDismiss
{
    [[PreferenceManager sharedManager] updatePreferenceToValue:@(NO) preferenceIdentifier:kSettingsSecurityUsePasscodeLockIdentifier];
    
    NSError *error;
    [KeychainUtils saveItem:@(kRemainingAttemptsMaxValue) forKey:kRemainingAttemptsKey error:&error];
    [KeychainUtils deleteItemForKey:kPinKey error:&error];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showNumberOfAttemptsRemaining
{
    if (_remainingAttempts > 1)
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
    _remainingAttempts = number ? number.integerValue : kRemainingAttemptsMaxValue;
    
    _shouldAllowPinEntry = YES;
    
    if (_remainingAttempts == 1)
    {
        [self showNumberOfAttemptsRemaining];
    }
    else
    {
        _subtitleLabel.hidden = YES;
    }
    
    [self setupConstraints];
    [self initializePinStrings];
    [self setupScreenTitle];
}

- (void)setupConstraints
{
    if (IS_IPAD || IS_IPHONE_6 || IS_IPHONE_6_PLUS)
    {
        _logoTopConstraint.constant = 40;
    }
    else if (IS_IPHONE_4)
    {
        _logoHeightConstraint.constant = 50;
        _logoTopConstraint.constant = 10;
        _titleLabelTopConstraint.constant = 10;
        _bulletsViewTopConstraint.constant = 10;
        _subtitleLabelTopConstraint.constant = 10;
    }
    else if (IS_IPHONE_5)
    {
        _logoTopConstraint.constant = 25;
        _titleLabelTopConstraint.constant = 20;
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
            self.title = NSLocalizedString(kSettingsSecurityPasscodeEnterTitle, @"Enter Passcode");
            break;
            
        default:
            break;
    }
}

#pragma mark - Actions

- (void)pressedCancelButton:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
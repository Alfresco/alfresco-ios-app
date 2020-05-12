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

#import "SecurityManager.h"
#import "KeychainUtils.h"
#import "AppDelegate.h"
#import "PinViewController.h"
#import "PreferenceManager.h"
#import "UniversalDevice.h"
#import "FileHandlerManager.h"
#import "AccountManager.h"
#import "CoreDataCacheHelper.h"
#import "DownloadManager.h"
#import "TouchIDManager.h"

#define BLANK_SCREEN_TAG 234
#define FADE_ANIMATION_DURATION 0.2

@interface SecurityManager()

@property (nonatomic, strong) UIWindow *pinScreenWindow;

@end

@implementation SecurityManager

+ (instancetype)sharedManager
{
    static SecurityManager *sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

- (void)setup
{
    [self addObservers];
    
    if ([[PreferenceManager sharedManager] shouldUsePasscodeLock])
    {
        [self migratePINValuesInKeychain];
        self.pinScreenWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.pinScreenWindow.rootViewController = [UIViewController new];
        [self.pinScreenWindow makeKeyAndVisible];
        [self showPinScreenIfNeededInOwnWindow:YES];
    }
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstPaidAccountAdded:) name:kAlfrescoFirstPaidAccountAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lastPaidAccountRemoved:) name:kAlfrescoLastPaidAccountRemovedNotification object:nil];
}

#pragma mark - Notification Handlers

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
    if ([[PreferenceManager sharedManager] shouldUsePasscodeLock] == NO)
    {
        return;
    }
    
    [self showBlankScreen:YES];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification
{
    if ([self forceResetIfNecessary])
    {
        return;
    }
    
    if ([[PreferenceManager sharedManager] shouldUsePasscodeLock] == NO)
    {
        return;
    }
    
    if ([TouchIDManager shouldUseTouchID])
    {
        [self evaluatePolicy];
    }
    else
    {
        [self showPinScreenAnimated:YES inOwnWindow:NO completionBlock:^{
            [self showBlankScreen:NO];
        }];
    }
}

- (void)firstPaidAccountAdded:(NSNotification *)notification
{
    [[PreferenceManager sharedManager] updatePreferenceToValue:@(NO) preferenceIdentifier:kSettingsSecurityUsePasscodeLockIdentifier];
}

- (void)lastPaidAccountRemoved:(NSNotification *)notification
{
    displayWarningMessageWithTitle(NSLocalizedString(@"alfresco-one-features.message", @"File protection and Passcode security are no longer available"),
                                   NSLocalizedString(@"alfresco-one-features.title", @"Alfresco One Features"));
    [[PreferenceManager sharedManager] updatePreferenceToValue:@(NO) preferenceIdentifier:kSettingsSecurityUsePasscodeLockIdentifier];
    [SecurityManager reset];
}

#pragma mark - Reset Methods

+ (void)reset
{
    NSError *error;
    [KeychainUtils deleteItemForKey:kPinKey
                            inGroup:kSharedAppGroupIdentifier
                              error:&error];
    [KeychainUtils deleteItemForKey:kRemainingAttemptsKey
                              error:&error];
}

+ (void)resetWithType:(ResetType)resetType
{
    [SecurityManager resetWithType:resetType showConfirmation:YES];
}

+ (void)resetWithType:(ResetType)resetType showConfirmation:(BOOL)showConfirmation
{
    switch (resetType)
    {
        case ResetTypeAccounts:
            [SecurityManager resetAccounts];
            break;
            
        case ResetTypeEntireApp:
            [SecurityManager resetEntireApp];
            break;
            
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAppResetedNotification object:nil];
    
    if (showConfirmation)
    {
        [self showConfirmationAlert];
    }
}

+ (void)resetAccounts
{
    // Remove accounts
    [[AccountManager sharedManager] removeAllAccounts];
    // Delete avatar cache
    CoreDataCacheHelper *cacheHelper = [[CoreDataCacheHelper alloc] init];
    [cacheHelper removeAllAvatarDataInManagedObjectContext:nil];
    
    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySettings
                                                      action:kAnalyticsEventActionClearData
                                                       label:kAnalyticsEventLabelPartial
                                                       value:@1];
}

+ (void)resetEntireApp
{
    // Reset accounts, delete cache databases, tmp folder, downloads
    // Remove accounts
    [[AccountManager sharedManager] removeAllAccounts];
    // Delete cache
    CoreDataCacheHelper *cacheHelper = [[CoreDataCacheHelper alloc] init];
    [cacheHelper removeAllAvatarDataInManagedObjectContext:nil];
    [cacheHelper removeAllDocLibImageDataInManagedObjectContext:nil];
    [cacheHelper removeAllDocumentPreviewImageDataInManagedObjectContext:nil];
    // Remove downloads
    [[DownloadManager sharedManager] removeAllDownloads];
    // Remove all contents of the temp folder
    [[AlfrescoFileManager sharedManager] clearTemporaryDirectory];
    
    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySettings
                                                      action:kAnalyticsEventActionClearData
                                                       label:kAnalyticsEventLabelFull
                                                       value:@1];
}

- (BOOL)forceResetIfNecessary
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
    BOOL shouldReset = [defaults boolForKey:kShouldResetEntireAppKey];
    
    if (shouldReset)
    {
        [defaults setBool:NO forKey:kShouldResetEntireAppKey];
        [defaults synchronize];
        
        [SecurityManager resetWithType:ResetTypeEntireApp];
        
        [self hideCurrentPinViewScreenWithFlow:PinFlowAny animated:NO completionBlock:nil];
        [self showBlankScreen:NO];
        
        [[PreferenceManager sharedManager] updatePreferenceToValue:@(NO) preferenceIdentifier:kSettingsSecurityUsePasscodeLockIdentifier];
        [SecurityManager reset];
    }
    
    return shouldReset;
}

#pragma mark - Private Methods

+ (void)showConfirmationAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"settings.reset.confirmation.title", @"Reset Complete Title")
                                                                             message:NSLocalizedString(@"settings.reset.confirmation.message", @"Reset Complete Message")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Close", @"Close")
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];
    [alertController addAction:closeAction];
    
    UIViewController *controller = [UniversalDevice topPresentedViewController];
    
    if ([controller isKindOfClass:[UINavigationController class]])
    {
        UIViewController *top = [(UINavigationController *)controller topViewController];
        
        if ([top isKindOfClass:[PinViewController class]])
        {
            controller = controller.presentingViewController;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(FADE_ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [controller presentViewController:alertController animated:YES completion:nil];
    });
}

- (UIWindow *)pinAndBlankScreensWindow
{
    UIWindow *window = self.pinScreenWindow;
    
    if (self.pinScreenWindow == nil)
    {
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        window = delegate.window;
    }
    
    return window;
}

- (void)showPinScreenIfNeededInOwnWindow:(BOOL)ownWindow
{
    if ([self forceResetIfNecessary])
    {
        return;
    }
    
    if ([[PreferenceManager sharedManager] shouldUsePasscodeLock] == NO)
    {
        return;
    }
    
    if ([TouchIDManager shouldUseTouchID])
    {
        [self showBlankScreen:YES];
        [self evaluatePolicy];
    }
    else
    {
        [self showPinScreenAnimated:NO inOwnWindow:ownWindow completionBlock:nil];
    }
}

- (void)showPinScreenAnimated:(BOOL)animated inOwnWindow:(BOOL)ownWindow completionBlock:(void (^)(void))completionBlock
{
    PinViewController *pvc = [self currentPinScreen];
    
    if (pvc && [pvc pinFlow] == PinFlowEnter)
    {
        if (completionBlock)
        {
            completionBlock();
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kKeyboardInPinScreenAppearanceDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardInPinScreenNotification object:nil];
        });
        
        return;
    }
    
    UINavigationController *navController = [PinViewController pinNavigationViewControllerWithFlow:PinFlowEnter inOwnWindow:ownWindow completionBlock:^(PinFlowCompletionStatus status){
        switch (status)
        {
            case PinFlowCompletionStatusSuccess:
            {
                [self switchToMainWindowWithCompletionBlock:nil];
                [[FileHandlerManager sharedManager] handleCachedPackage];
            }
                break;
            case PinFlowCompletionStatusReset:
            {
                [SecurityManager resetWithType:ResetTypeEntireApp showConfirmation:NO];
                [self switchToMainWindowWithCompletionBlock:^{
                    [SecurityManager  showConfirmationAlert];
                }];
            }
                break;
                
            default:
                break;
        }
    }];
    
    if (ownWindow)
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.pinScreenWindow.rootViewController = navController;
            [strongSelf.pinScreenWindow makeKeyAndVisible];
        });
    }
    else
    {
        if (self.pinScreenWindow == nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UniversalDevice topPresentedViewController] presentViewController:navController animated:animated completion:completionBlock];
            });
        }
        else
        {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(self) strongSelf = weakSelf;
                strongSelf.pinScreenWindow.rootViewController = navController;
                [strongSelf.pinScreenWindow makeKeyAndVisible];
            });
        }
    }
}

- (void)showBlankScreen:(BOOL)show
{
    UIWindow *window = [self pinAndBlankScreensWindow];
    UIView *view = [window viewWithTag:BLANK_SCREEN_TAG];
    
    if (show)
    {
        if (view == nil)
        {
            UINib *nib = [UINib nibWithNibName:@"Launch Screen" bundle:nil];
            view = [nib instantiateWithOwner:nil options:nil].firstObject;
            view.frame = window.bounds;
            view.tag = BLANK_SCREEN_TAG;
            [window addSubview:view];
            [window endEditing:YES];
        }
    }
    else
    {
        if (view)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:FADE_ANIMATION_DURATION animations:^{
                    view.alpha = 0;
                }
                 completion:^(BOOL finished) {
                     [view removeFromSuperview];
                 }];
            });
        }
    }
}

- (PinViewController *)currentPinScreen
{
    PinViewController *currentPinViewController = nil;
    UIViewController *topController = [UniversalDevice topPresentedViewController];
    
    if ([topController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *topNavigationController = (UINavigationController *)topController;
        PinViewController *pvc = topNavigationController.viewControllers.firstObject;
        
        if ([pvc isKindOfClass:[PinViewController class]])
        {
            currentPinViewController = pvc;
        }
    }
    
    return currentPinViewController;
}

- (void)hideCurrentPinViewScreenWithFlow:(PinFlow)pinFlow animated:(BOOL)animated completionBlock:(void (^)(void))completionBlock
{
    PinViewController *pvc = [self currentPinScreen];
    PinFlow currentPinFlow = [pvc pinFlow];
    
    if (pvc.navigationController && (currentPinFlow == pinFlow || currentPinFlow == PinFlowAny))
    {
        [pvc.navigationController dismissViewControllerAnimated:animated completion:completionBlock];
    }
    else
    {
        if (completionBlock)
        {
            completionBlock();
        }
    }
}

- (void)evaluatePolicy
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [TouchIDManager evaluatePolicyWithCompletionBlock:^(BOOL success, NSError *authenticationError){
            if (success)
            {
                [weakSelf hideCurrentPinViewScreenWithFlow:PinFlowEnter animated:YES completionBlock:^{
                    [weakSelf showBlankScreen:NO];
                }];
                
                if (weakSelf.pinScreenWindow && [weakSelf.pinScreenWindow isKeyWindow])
                {
                    [weakSelf switchToMainWindowWithCompletionBlock:nil];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardInPinScreenNotification object:nil];
                
                [[FileHandlerManager sharedManager] handleCachedPackage];
            }
            else
            {
                AlfrescoLogDebug(@"Touch ID error: %@", authenticationError.localizedDescription);
                
                [weakSelf showPinScreenAnimated:NO inOwnWindow: weakSelf.pinScreenWindow ? YES : NO completionBlock:^{
                    [weakSelf showBlankScreen:NO];
                }];
            }
        }];
    });
}

- (void)switchToMainWindowWithCompletionBlock:(void (^)(void))completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [((AppDelegate *)([UIApplication sharedApplication].delegate)).window makeKeyAndVisible];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(FADE_ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.pinScreenWindow.rootViewController = nil;
            self.pinScreenWindow = nil;
            
            if (completionBlock)
            {
                completionBlock();
            }
        });
    });
}

- (void)migratePINValuesInKeychain
{
    NSError *error;
    
    NSString *pin = [KeychainUtils retrieveItemForKey:kPinKey
                                                error:&error];
    if (pin.length)
    {
        [KeychainUtils deleteItemForKey:kPinKey
                                  error:&error];
        
        [KeychainUtils saveItem:pin
                         forKey:kPinKey
                        inGroup:kSharedAppGroupIdentifier
                          error:&error];
    }
}

@end

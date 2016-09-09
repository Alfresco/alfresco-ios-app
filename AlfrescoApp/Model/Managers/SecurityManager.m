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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunchingNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
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
        [self showPinScreenAnimated:YES completionBlock:nil];
        [self showBlankScreen:NO];
    }
}

- (void)applicationDidFinishLaunchingNotification:(NSNotification *)notification
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
        [self showPinScreenAnimated:YES completionBlock:nil];
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

#pragma mark - Utils

+ (void)reset
{
    NSError *error;
    [KeychainUtils deleteItemForKey:kPinKey error:&error];
    [KeychainUtils deleteItemForKey:kRemainingAttemptsKey error:&error];
}

+ (void)resetWithType:(ResetType)resetType
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
    
    UIAlertView *confirmation = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"settings.reset.confirmation.title", @"Reset Complete Title")
                                                           message:NSLocalizedString(@"settings.reset.confirmation.message", @"Reset Complete Message")
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"Close", @"Close")
                                                 otherButtonTitles:nil];
    [confirmation show];
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
    
    UIAlertView *confirmation = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"settings.reset.confirmation.title", @"Reset Complete Title")
                                                           message:NSLocalizedString(@"settings.reset.confirmation.message", @"Reset Complete Message")
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"Close", @"Close")
                                                 otherButtonTitles:nil];
    [confirmation show];
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
        
        UIViewController *topController = [UniversalDevice topPresentedViewController];
        
        if ([topController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *topNavigationController = (UINavigationController *)topController;
            PinViewController *pvc = topNavigationController.viewControllers.firstObject;
            
            if ([pvc isKindOfClass:[PinViewController class]])
            {
                [topController dismissViewControllerAnimated:NO completion:nil];
            }
        }
        
        [self showBlankScreen:NO];
        
        [[PreferenceManager sharedManager] updatePreferenceToValue:@(NO) preferenceIdentifier:kSettingsSecurityUsePasscodeLockIdentifier];
        [SecurityManager reset];
    }
    
    return shouldReset;
}

#pragma mark -

- (void)showPinScreenAnimated:(BOOL)animated completionBlock:(void (^)())completionBlock
{
    UIViewController *topController = [UniversalDevice topPresentedViewController];
    
    if ([topController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *topNavigationController = (UINavigationController *)topController;
        PinViewController *pvc = topNavigationController.viewControllers.firstObject;
        
        if ([pvc isKindOfClass:[PinViewController class]])
        {
            if ([pvc pinFlow] == PinFlowEnter)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardInPinScreenNotification object:nil];
                return;
            }
        }
    }
    
    UINavigationController *navController = [PinViewController pinNavigationViewControllerWithFlow:PinFlowEnter completionBlock:^(PinFlowCompletionStatus status){
        switch (status)
        {
            case PinFlowCompletionStatusSuccess:
            {
                [[FileHandlerManager sharedManager] handleCachedPackage];
            }
                break;
            case PinFlowCompletionStatusReset:
            {
                [SecurityManager resetWithType:ResetTypeEntireApp];
            }
                break;
                
            default:
                break;
        }
    }];
    [topController presentViewController:navController animated:animated completion:completionBlock];
}

- (void)showBlankScreen:(BOOL)show
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIView *view = [delegate.window viewWithTag:BLANK_SCREEN_TAG];
    
    if (show)
    {
        if (view == nil)
        {
            UINib *nib = [UINib nibWithNibName:@"Launch Screen" bundle:nil];
            view = [nib instantiateWithOwner:nil options:nil].firstObject;
            view.frame = delegate.window.bounds;
            view.tag = BLANK_SCREEN_TAG;
            [delegate.window addSubview:view];
            [delegate.window endEditing:YES];
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

- (void)evaluatePolicy
{
    [TouchIDManager evaluatePolicyWithCompletionBlock:^(BOOL success, NSError *authenticationError){
        if (success)
        {
            [self showBlankScreen:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardInPinScreenNotification object:nil];
            
            [[FileHandlerManager sharedManager] handleCachedPackage];
        }
        else
        {
            AlfrescoLogDebug(@"Touch ID error: %@", authenticationError.localizedDescription);
            
            [self showPinScreenAnimated:NO completionBlock:^{
                [self showBlankScreen:NO];
            }];
        }
    }];
}

@end
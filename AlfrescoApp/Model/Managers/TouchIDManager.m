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

#import "TouchIDManager.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "PreferenceManager.h"

@implementation TouchIDManager

+ (BOOL)isTouchIDAvailable
{
    LAContext *context = [[LAContext alloc] init];
    NSError *error;
    
    // Test if we can evaluate the policy; this test will tell us if Touch ID is available and enrolled.
    BOOL success = [context canEvaluatePolicy: LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    NSString *message = success ? @"Touch ID is available." : [NSString stringWithFormat:@"Touch ID is not available. Error: %@", error.localizedDescription];
    AlfrescoLogDebug(@"%@", message);
    
    return success;
}

+ (BOOL)shouldUseTouchID
{
    BOOL isTouchIDAvailable = [TouchIDManager isTouchIDAvailable];
    BOOL isTouchIDSwitchOn = [[[PreferenceManager sharedManager] preferenceForIdentifier:kSettingsPasscodeTouchIDIdentifier] boolValue];
    return isTouchIDAvailable && isTouchIDSwitchOn;
}

+ (void)evaluatePolicyWithCompletionBlock:(void (^)(BOOL success, NSError *authenticationError))completionBlock
{
    LAContext *context = [[LAContext alloc] init];
    context.localizedFallbackTitle = @"";
    
    // Show the authentication UI with the localized reason string.
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            localizedReason:NSLocalizedString(@"settings.security.passcode.touch.id.description", @"Allow your fingerprint to unlock the Alfresco app.")
                      reply:^(BOOL success, NSError *authenticationError){
         completionBlock (success, authenticationError);
     }];
}

@end

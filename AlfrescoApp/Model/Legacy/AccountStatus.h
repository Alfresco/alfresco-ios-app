/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  AccountStatus.h
//
// Stores information about an account status.
// Currently it's used to store the status enum (active, inactive, error, etc.)
// and also to store the last account's successful request timestamp

#import <Foundation/Foundation.h>

typedef enum
{
    FDAccountStatusActive,
    FDAccountStatusAwaitingVerification,
    FDAccountStatusInactive,
    FDAccountStatusConnectionError,
    FDAccountStatusInvalidCredentials,
    FDAccountStatusInvalidCertificate
} FDAccountStatus;

@interface AccountStatus : NSObject <NSCoding>

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) FDAccountStatus accountStatus;
@property (nonatomic, assign) NSTimeInterval successTimestamp;

/*
 A short message describing the current status of the account
 Used as a cell subtitle for an account (Manage Account)
 */
- (NSString *)shortMessage;
/*
 The color for the short message text
 */
- (UIColor *)shortMessageTextColor;
/*
 A detailed message for the account status.
 Used in the Account detail screen
 */
- (NSString *)detailedMessage;

- (BOOL)isError;
- (BOOL)isActive;

@end

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

#import <Foundation/Foundation.h>
#import "AccountCertificate.h"

@class AlfrescoOAuthData;

typedef NS_ENUM(NSInteger, UserAccountType)
{
    UserAccountTypeOnPremise = 0,
    UserAccountTypeCloud,
    UserAccountTypeAIMS
};

typedef NS_ENUM(NSInteger, UserAccountStatus)
{
    UserAccountStatusActive,
    UserAccountStatusAwaitingVerification,
    UserAccountStatusConnectionError,
    UserAccountStatusInvalidCredentials
};

@interface UserAccount : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong, readonly) NSString *accountIdentifier;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *accountDescription;
@property (nonatomic, strong) NSString *serverAddress;
@property (nonatomic, strong) NSString *serverPort;
@property (nonatomic, strong) NSString *protocol;
@property (nonatomic, strong) NSString *serviceDocument;
@property (nonatomic, strong) NSString *contentAddress;
@property (nonatomic, strong) NSString *realm;
@property (nonatomic, strong) NSString *clientID;
@property (nonatomic, strong) NSString *redirectURI;
@property (nonatomic, assign) UserAccountType accountType;
@property (nonatomic, strong) AlfrescoOAuthData *oauthData;

@property (nonatomic, strong) AccountCertificate *accountCertificate;
@property (nonatomic, assign) BOOL isSelectedAccount;
@property (nonatomic, assign) BOOL isSyncOn;
@property (nonatomic, assign) BOOL didAskToSync;
@property (nonatomic, strong) NSString *selectedNetworkId;
@property (nonatomic, strong) NSArray *accountNetworks;
@property (nonatomic, assign) UserAccountStatus accountStatus;


// Cloud sign-up properties, needed for refreshing Account Statuses and resending sign-up request
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *cloudAccountId;
@property (nonatomic, strong) NSString *cloudAccountKey;

// Paid account tracking
@property (nonatomic, assign, getter = isPaidAccount) BOOL paidAccount;

// Configuration
@property (nonatomic, strong) NSString *selectedProfileIdentifier;
@property (nonatomic, strong) NSString *selectedProfileName;

// SAML
@property (nonatomic, strong) AlfrescoSAMLData *samlData;

- (instancetype)initWithAccountType:(UserAccountType)accountType;

@end

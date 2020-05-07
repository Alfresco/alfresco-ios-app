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

#import "UserAccountWrapper.h"
#import "UserAccount.h"

@interface UserAccountWrapper ()

@property (nonatomic, strong) UserAccount *userAccount;

@end

@implementation UserAccountWrapper

- (instancetype)initWithUserAccount:(UserAccount *)userAccount
{
    self = [self init];
    if (self)
    {
        self.identifier = userAccount.accountIdentifier;
        self.username = userAccount.username;
        self.password = userAccount.password;
        self.accountDescription = userAccount.accountDescription;
        self.serverAddress = userAccount.serverAddress;
        self.serverPort = userAccount.serverPort;
        self.protocol = userAccount.protocol;
        self.serviceDocument = userAccount.serviceDocument;
        self.contentAddress = userAccount.contentAddress;
        self.realm = userAccount.realm;
        self.clientID = userAccount.clientID;
        self.redirectURI = userAccount.redirectURI;
        self.selectedNetworkIdentifier = userAccount.selectedNetworkId;
        self.networkIdentifiers = userAccount.accountNetworks;
        self.oAuthData = userAccount.oauthData;
        self.samlData = userAccount.samlData;
        self.isOnPremiseAccount = (userAccount.accountType == UserAccountTypeOnPremise);
        self.userAccount = userAccount;
    }
    return self;
}

@end

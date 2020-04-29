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
 
#import "UserAccount.h"

static NSString * const kAccountIdentifier = @"kAccountIdentifier";
static NSString * const kAccountUsername = @"kAccountUsername";
static NSString * const kAccountPassword = @"kAccountPassword";
static NSString * const kAccountDescription = @"kAccountDescription";
static NSString * const kAccountServerAddress = @"kAccountServerAddress";
static NSString * const kAccountServerPort= @"kAccountServerPort";
static NSString * const kAccountProtocol= @"kAccountProtocol";
static NSString * const kAccountServiceDocument = @"kAccountServiceDocument";
static NSString * const kAccountContentAddress = @"kAccountContentAddress";
static NSString * const kAccountRealm = @"kAccountRealm";
static NSString * const kAccountClientID = @"kAccountClientID";
static NSString * const kAccountRedirectURI = @"kAccountRedirectURI";
static NSString * const kAccountType = @"kAccountType";
static NSString * const kAlfrescoOAuthData = @"kAlfrescoOAuthData";
static NSString * const kAccountCertificate = @"kAccountCertificate";
static NSString * const kAccountIsSelected = @"kAccountIsSelected";
static NSString * const kAccountIsSyncOn = @"kAccountIsSyncOn";
static NSString * const kAccountDidAskToSync = @"kAccountDidAskToSync";
static NSString * const kAccountNetworks = @"kAccountNetworks";
static NSString * const kSelectedNetworkId = @"kSelectedNetworkId";
static NSString * const kAccountStatus = @"kAccountStatus";
// Cloud sign-up
static NSString * const kUserFirstName = @"kUserFirstName";
static NSString * const kUserLastName = @"kUserLastName";
static NSString * const kCloudAccountId = @"kCloudAccountId";
static NSString * const kCloudAccountKey = @"kCloudAccountKey";
// Paid account tracking
static NSString * const kAccountIsPaid = @"kAccountIsPaid";
// Configuration
static NSString * const kAccountSelectedProfileIdentifierKey = @"kAccountSelectedProfileIdentifierKey";
static NSString * const kAccountSelectedProfileNameKey = @"kAccountSelectedProfileNameKey";
// SAML
static NSString * const kAlfrescoSAMLData = @"kAlfrescoSAMLData";

@interface UserAccount ()
@property (nonatomic, strong, readwrite) NSString *accountIdentifier;
@end

@implementation UserAccount

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.accountIdentifier = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (instancetype)initWithAccountType:(UserAccountType)accountType
{
    self = [self init];
    if (self)
    {
        _accountType = accountType;
        _isSyncOn = YES;
        _realm = kAlfrescoDefaultAIMSRealmString;
        _clientID = kAlfrescoDefaultAIMSClientIDString;
        _redirectURI = kAlfrescoDefaultAIMSRedirectURI;
    }
    return self;
}

#pragma mark - NSCoding Functions

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.accountIdentifier forKey:kAccountIdentifier];
    [aCoder encodeObject:self.username forKey:kAccountUsername];
    [aCoder encodeObject:self.password forKey:kAccountPassword];
    [aCoder encodeObject:self.firstName forKey:kUserFirstName];
    [aCoder encodeObject:self.lastName forKey:kUserLastName];
    [aCoder encodeObject:self.accountDescription forKey:kAccountDescription];
    [aCoder encodeObject:self.serverAddress forKey:kAccountServerAddress];
    [aCoder encodeObject:self.serverPort forKey:kAccountServerPort];
    [aCoder encodeObject:self.protocol forKey:kAccountProtocol];
    [aCoder encodeObject:self.serviceDocument forKey:kAccountServiceDocument];
    [aCoder encodeObject:self.contentAddress forKey:kAccountContentAddress];
    [aCoder encodeObject:self.realm forKey:kAccountRealm];
    [aCoder encodeObject:self.clientID forKey:kAccountClientID];
    [aCoder encodeObject:self.redirectURI forKey:kAccountRedirectURI];
    [aCoder encodeInteger:self.accountType forKey:kAccountType];
    [aCoder encodeObject:self.oauthData forKey:kAlfrescoOAuthData];
    [aCoder encodeObject:self.accountCertificate forKey:kAccountCertificate];
    [aCoder encodeInteger:self.isSelectedAccount forKey:kAccountIsSelected];
    [aCoder encodeInteger:self.isSyncOn forKey:kAccountIsSyncOn];
    [aCoder encodeInteger:self.didAskToSync forKey:kAccountDidAskToSync];
    [aCoder encodeObject:self.accountNetworks forKey:kAccountNetworks];
    [aCoder encodeObject:self.selectedNetworkId forKey:kSelectedNetworkId];
    [aCoder encodeInteger:self.accountStatus forKey:kAccountStatus];
    [aCoder encodeObject:self.cloudAccountId forKey:kCloudAccountId];
    [aCoder encodeObject:self.cloudAccountKey forKey:kCloudAccountKey];
    [aCoder encodeInteger:self.isPaidAccount forKey:kAccountIsPaid];
    [aCoder encodeObject:self.selectedProfileIdentifier forKey:kAccountSelectedProfileIdentifierKey];
    [aCoder encodeObject:self.selectedProfileName forKey:kAccountSelectedProfileNameKey];
    [aCoder encodeObject:self.samlData forKey:kAlfrescoSAMLData];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.accountIdentifier = [aDecoder decodeObjectForKey:kAccountIdentifier];
        self.username = [aDecoder decodeObjectForKey:kAccountUsername];
        self.password = [aDecoder decodeObjectForKey:kAccountPassword];
        self.firstName = [aDecoder decodeObjectForKey:kUserFirstName];
        self.lastName = [aDecoder decodeObjectForKey:kUserLastName];
        self.accountDescription = [aDecoder decodeObjectForKey:kAccountDescription];
        self.serverAddress = [aDecoder decodeObjectForKey:kAccountServerAddress];
        self.serverPort = [aDecoder decodeObjectForKey:kAccountServerPort];
        self.protocol = [aDecoder decodeObjectForKey:kAccountProtocol];
        self.serviceDocument = [aDecoder decodeObjectForKey:kAccountServiceDocument];
        self.contentAddress = [aDecoder decodeObjectForKey:kAccountContentAddress];
        self.realm = [aDecoder decodeObjectForKey:kAccountRealm];
        self.clientID = [aDecoder decodeObjectForKey:kAccountClientID];
        self.redirectURI = [aDecoder decodeObjectForKey:kAccountRedirectURI];
        self.accountType = [aDecoder decodeIntegerForKey:kAccountType];
        self.oauthData = [aDecoder decodeObjectForKey:kAlfrescoOAuthData];
        self.accountCertificate = [aDecoder decodeObjectForKey:kAccountCertificate];
        self.isSelectedAccount = [aDecoder decodeIntegerForKey:kAccountIsSelected];
        self.isSyncOn = [aDecoder decodeIntegerForKey:kAccountIsSyncOn];
        self.didAskToSync = [aDecoder decodeIntegerForKey:kAccountDidAskToSync];
        self.accountNetworks = [aDecoder decodeObjectForKey:kAccountNetworks];
        self.selectedNetworkId = [aDecoder decodeObjectForKey:kSelectedNetworkId];
        self.accountStatus = [aDecoder decodeIntegerForKey:kAccountStatus];
        self.cloudAccountId = [aDecoder decodeObjectForKey:kCloudAccountId];
        self.cloudAccountKey = [aDecoder decodeObjectForKey:kCloudAccountKey];
        self.paidAccount = [aDecoder decodeIntegerForKey:kAccountIsPaid];
        self.selectedProfileIdentifier = [aDecoder decodeObjectForKey:kAccountSelectedProfileIdentifierKey];
        self.selectedProfileName = [aDecoder decodeObjectForKey:kAccountSelectedProfileNameKey];
        self.samlData = [aDecoder decodeObjectForKey:kAlfrescoSAMLData];
    }
    return self;
}

#pragma mark - NSCopying Method

- (id)copyWithZone:(NSZone *)zone
{
    UserAccount *account = [[self class] allocWithZone:zone];
    
    if (account)
    {
        account.accountIdentifier = self.accountIdentifier;
        account.username = self.username;
        account.password = self.password;
        account.accountDescription = self.accountDescription;
        account.serverAddress = self.serverAddress;
        account.serverPort = self.serverPort;
        account.protocol = self.protocol;
        account.serviceDocument = self.serviceDocument;
        account.contentAddress = self.contentAddress;
        account.realm = self.realm;
        account.clientID = self.clientID;
        account.redirectURI = self.redirectURI;
        account.accountType = self.accountType;
        account.accountCertificate = self.accountCertificate;
        account.isSyncOn = self.isSyncOn;
        account.paidAccount = self.isPaidAccount;
        account.selectedProfileIdentifier = self.selectedProfileIdentifier;
        account.selectedProfileName = self.selectedProfileName;
    }
    return account;
}

- (NSString *)description
{
    NSMutableString *string = [NSMutableString string];
    
    [string appendFormat:@"\nidentifier: %@\n", self.accountIdentifier];
    [string appendFormat:@"username: %@\n", self.username];
    [string appendFormat:@"password: %@\n", self.password];
    [string appendFormat:@"server: %@\n", self.serverAddress];
    [string appendFormat:@"contentURL: %@\n", self.contentAddress];
    [string appendFormat:@"port: %@\n", self.serverPort];
    [string appendFormat:@"protocol: %@\n", self.protocol];
    [string appendFormat:@"serviceDocument: %@\n", self.serviceDocument];
    [string appendFormat:@"realm: %@\n", self.realm];
    [string appendFormat:@"clientID: %@\n", self.clientID];
    [string appendFormat:@"redirectURI: %@\n", self.redirectURI];
    [string appendFormat:@"clientCertificate: %@\n", self.accountCertificate.summary];
    [string appendFormat:@"accountDescription: %@\n", self.accountDescription];
    [string appendFormat:@"\n%@", self.samlData];
    [string appendFormat:@"\naddress: %p", self];
    
    return string;
}

@end

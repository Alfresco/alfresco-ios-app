//
//  Account.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "UserAccount.h"

static NSString * const kAccountIdentifier = @"kAccountIdentifier";
static NSString * const kAccountUsername = @"kAccountUsername";
static NSString * const kAccountPassword = @"kAccountPassword";
static NSString * const kAccountDescription = @"kAccountDescription";
static NSString * const kAccountServerAddress = @"kAccountServerAddress";
static NSString * const kAccountServerPort= @"kAccountServerPort";
static NSString * const kAccountProtocol= @"kAccountProtocol";
static NSString * const kAccountServiceDocument = @"kAccountServiceDocument";
static NSString * const kAccountType = @"kAccountType";
static NSString * const kAlfrescoOAuthData = @"kAlfrescoOAuthData";
static NSString * const kAccountIsSelected = @"kAccountIsSelected";
static NSString * const kAccountNetworks = @"kAccountNetworks";
static NSString * const kSelectedNetworkId = @"kSelectedNetworkId";
static NSString * const kAccountStatus = @"kAccountStatus";
static NSString * const kUserFirstName = @"kUserFirstName";
static NSString * const kUserLastName = @"kUserLastName";
static NSString * const kCloudAccountId = @"kCloudAccountId";
static NSString * const kCloudAccountKey = @"kCloudAccountKey";

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
    self = [super init];
    if (self)
    {
        self.accountType = accountType;
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
    [aCoder encodeInteger:self.accountType forKey:kAccountType];
    [aCoder encodeObject:self.oauthData forKey:kAlfrescoOAuthData];
    [aCoder encodeInteger:self.isSelectedAccount forKey:kAccountIsSelected];
    [aCoder encodeObject:self.accountNetworks forKey:kAccountNetworks];
    [aCoder encodeObject:self.selectedNetworkId forKey:kSelectedNetworkId];
    [aCoder encodeInteger:self.accountStatus forKey:kAccountStatus];
    [aCoder encodeObject:self.cloudAccountId forKey:kCloudAccountId];
    [aCoder encodeObject:self.cloudAccountKey forKey:kCloudAccountKey];
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
        self.accountType = [aDecoder decodeIntegerForKey:kAccountType];
        self.oauthData = [aDecoder decodeObjectForKey:kAlfrescoOAuthData];
        self.isSelectedAccount = [aDecoder decodeIntegerForKey:kAccountIsSelected];
        self.accountNetworks = [aDecoder decodeObjectForKey:kAccountNetworks];
        self.selectedNetworkId = [aDecoder decodeObjectForKey:kSelectedNetworkId];
        self.accountStatus = [aDecoder decodeIntegerForKey:kAccountStatus];
        self.cloudAccountId = [aDecoder decodeObjectForKey:kCloudAccountId];
        self.cloudAccountKey = [aDecoder decodeObjectForKey:kCloudAccountKey];
    }
    return self;
}

@end

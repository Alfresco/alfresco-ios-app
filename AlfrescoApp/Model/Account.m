//
//  Account.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "Account.h"

static NSString * const kAccountUsername = @"kAccountUsername";
static NSString * const kAccountPassword = @"kAccountPassword";
static NSString * const kAccountDescription = @"kAccountDescription";
static NSString * const kAccountServerAddress = @"kAccountServerAddress";
static NSString * const kAccountServerPort= @"kAccountServerPort";
static NSString * const kAccountProtocol= @"kAccountProtocol";
static NSString * const kAccountServiceDocument = @"kAccountServiceDocument";
static NSString * const kAccountRepositoryId= @"kAccountRepositoryId";
static NSString * const kAccountType = @"kAccountType";
static NSString * const kAlfrescoOAuthData = @"kAlfrescoOAuthData";

@interface Account ()

@end

@implementation Account

- (instancetype)initWithAccountType:(AccountType)accountType
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
    [aCoder encodeObject:self.username forKey:kAccountUsername];
    [aCoder encodeObject:self.password forKey:kAccountPassword];
    [aCoder encodeObject:self.accountDescription forKey:kAccountDescription];
    [aCoder encodeObject:self.serverAddress forKey:kAccountServerAddress];
    [aCoder encodeObject:self.serverPort forKey:kAccountServerPort];
    [aCoder encodeObject:self.protocol forKey:kAccountProtocol];
    [aCoder encodeObject:self.serviceDocument forKey:kAccountServiceDocument];
    [aCoder encodeObject:self.repositoryId forKey:kAccountRepositoryId];
    [aCoder encodeInteger:self.accountType forKey:kAccountType];
    [aCoder encodeObject:self.oauthData forKey:kAlfrescoOAuthData];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.username = [aDecoder decodeObjectForKey:kAccountUsername];
        self.password = [aDecoder decodeObjectForKey:kAccountPassword];
        self.accountDescription = [aDecoder decodeObjectForKey:kAccountDescription];
        self.serverAddress = [aDecoder decodeObjectForKey:kAccountServerAddress];
        self.serverPort = [aDecoder decodeObjectForKey:kAccountServerPort];
        self.protocol = [aDecoder decodeObjectForKey:kAccountProtocol];
        self.serviceDocument = [aDecoder decodeObjectForKey:kAccountServiceDocument];
        self.repositoryId = [aDecoder decodeObjectForKey:kAccountRepositoryId];
        self.accountType = [aDecoder decodeIntegerForKey:kAccountType];
        self.oauthData = [aDecoder decodeObjectForKey:kAlfrescoOAuthData];
    }
    return self;
}

@end

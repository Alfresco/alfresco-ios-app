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

@interface Account ()

@end

@implementation Account

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password description:(NSString *)description serverAddress:(NSString *)server port:(NSString *)port
{
    self = [super init];
    if (self)
    {
        self.username = username;
        self.password = password;
        self.accountDescription = description;
        self.serverAddress = server;
        self.serverPort = port;
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
    }
    return self;
}

@end

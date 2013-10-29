//
//  Account.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kAccountRepositoryId;

typedef NS_ENUM(NSInteger, AccountType)
{
    OnPremise = 0,
    Cloud
};

@interface Account : NSObject <NSCoding>

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *accountDescription;
@property (nonatomic, strong) NSString *serverAddress;
@property (nonatomic, strong) NSString *serverPort;
@property (nonatomic, strong) NSString *protocol;
@property (nonatomic, strong) NSString *serviceDocument;
@property (nonatomic, assign) AccountType accountType;
@property (nonatomic, strong) AlfrescoOAuthData *oauthData;
@property (nonatomic, strong) NSString *repositoryId;

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password description:(NSString *)description serverAddress:(NSString *)server port:(NSString *)port;

@end

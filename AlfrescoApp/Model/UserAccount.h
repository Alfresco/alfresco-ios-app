//
//  Account.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AccountType)
{
    AccountTypeOnPremise = 0,
    AccountTypeCloud
};

@interface UserAccount : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSString *accountIdentifier;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *accountDescription;
@property (nonatomic, strong) NSString *serverAddress;
@property (nonatomic, strong) NSString *serverPort;
@property (nonatomic, strong) NSString *protocol;
@property (nonatomic, strong) NSString *serviceDocument;
@property (nonatomic, assign) AccountType accountType;
@property (nonatomic, strong) AlfrescoOAuthData *oauthData;
@property (nonatomic, assign) BOOL isSelectedAccount;
@property (nonatomic, strong) NSString *selectedNetworkId;
@property (nonatomic, strong) NSArray *accountNetworks;

- (instancetype)initWithAccountType:(AccountType)accountType;

@end

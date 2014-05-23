//
//  AccountCertificate.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 03/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@interface AccountCertificate : NSObject

@property (nonatomic, readonly) SecIdentityRef identityRef;
@property (nonatomic, readonly) SecCertificateRef identityCertificateRef;
@property (nonatomic, strong, readonly) NSArray *certificateChain;
@property (nonatomic, strong, readonly) NSString *summary;
@property (nonatomic, strong, readonly) NSDate *expiryDate;
@property (nonatomic, assign, readonly) BOOL hasExpired;
@property (nonatomic, strong, readonly) NSString *certificateIssuer;

- (id)initWithIdentityData:(NSData *)data andPasscode:(NSString *)passcode;

@end

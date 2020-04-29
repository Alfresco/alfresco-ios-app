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
 
#import "AccountCertificate.h"

static NSString * const kCertificatePkcsData = @"kCertificatePkcsData";
static NSString * const kCertificatePasscode = @"kCertificatePasscode";

@interface AccountCertificate ()

@property (nonatomic, readwrite) SecIdentityRef identityRef;
@property (nonatomic, readwrite) SecCertificateRef identityCertificateRef;
@property (nonatomic, strong, readwrite) NSArray *certificateChain;
@property (nonatomic, assign, readwrite) BOOL hasExpired;
@property (nonatomic, strong, readwrite) NSString *certificateIssuer;

@property (nonatomic, strong) NSData *pkcsData;
@property (nonatomic, copy) NSString *passcode;
@property (nonatomic, assign) BOOL verifiedDate;

@end

@implementation AccountCertificate

- (id)initWithIdentityData:(NSData *)data andPasscode:(NSString *)passcode
{
    self = [super init];
    if (self)
    {
        _pkcsData = data;
        _passcode = passcode;
        [self configureCertificates];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _pkcsData = [aDecoder decodeObjectForKey:kCertificatePkcsData];
        _passcode = [aDecoder decodeObjectForKey:kCertificatePasscode];
        [self configureCertificates];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.pkcsData forKey:kCertificatePkcsData];
    [aCoder encodeObject:self.passcode forKey:kCertificatePasscode];
}

- (void)dealloc
{
    CFRelease(_identityRef);
}

#pragma mark - private Methods

- (void)configureCertificates
{
    NSArray *pkcs12 = nil;
    OSStatus importStatus = SecPKCS12Import((__bridge CFDataRef)self.pkcsData, (__bridge CFDictionaryRef)@{(__bridge id)kSecImportExportPassphrase : self.passcode}, (void *)&pkcs12);
    
    if (importStatus == errSecSuccess)
    {
        self.identityRef = (__bridge SecIdentityRef)[pkcs12[0] objectForKey:(__bridge id)kSecImportItemIdentity];
        CFRetain(self.identityRef);
        self.certificateChain = [pkcs12[0] objectForKey:(__bridge id)kSecImportItemCertChain];
        
        SecCertificateRef certificateRef = NULL;
        OSStatus certificateError = noErr;
        certificateError = SecIdentityCopyCertificate(self.identityRef, &certificateRef);
        
        if (certificateError == errSecSuccess)
        {
            self.identityCertificateRef = certificateRef;
        }
        else
        {
            AlfrescoLogDebug(@"Error Certificate Retrieval, error code: %ld", certificateError);
        }
    }
    else
    {
        AlfrescoLogDebug(@"Error importing PKCS12 data, error code: %ld", importStatus);
    }
}

- (NSString *)summary
{
    return (__bridge_transfer NSString *)SecCertificateCopySubjectSummary(self.identityCertificateRef);
}

- (BOOL)hasExpired
{
    if (!self.verifiedDate)
    {
        _hasExpired = [self verifyCertificateDate];
        self.verifiedDate = YES;
    }
    return _hasExpired;
}

- (BOOL)verifyCertificateDate
{
    SecPolicyRef myPolicy = SecPolicyCreateSSL(YES, nil);
    
    SecTrustRef myTrust = NULL;
    OSStatus status = SecTrustCreateWithCertificates((__bridge CFTypeRef)(self.certificateChain), myPolicy, &myTrust);
    
    SecTrustResultType trustResult = kSecTrustResultProceed;
    if (status == noErr)
    {
        SecTrustEvaluate(myTrust, &trustResult);
    }
    else
    {
        trustResult = kSecTrustResultInvalid;
    }
    
    if (myPolicy)
    {
        CFRelease(myPolicy);
    }
    if (myTrust)
    {
        CFRelease(myTrust);
    }
    // Assuming that any trustResult but kSecTrustResultProceed
    // means that the certificate is expired
    return trustResult != kSecTrustResultProceed;
}

- (NSString *)certificateIssuer
{
    NSString *certificateDescription = [NSString stringWithFormat:@"%@", self.identityCertificateRef];
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"i\\: (.+)>$" options:0 error:&error];
    
    NSArray *matches = [regex matchesInString:certificateDescription
                                      options:0
                                        range:NSMakeRange(0, [certificateDescription length])];
    
    NSString *issuer = nil;
    if ([matches count] > 0)
    {
        NSTextCheckingResult *match = matches[0];
        if (match)
        {
            // 1 means first the first group, 0 contains the whole match
            NSRange matchRange = [match rangeAtIndex:1];
            issuer = [certificateDescription substringWithRange:matchRange];
        }
    }
    return issuer;
}

@end

/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  FDCertificate.m
//
//

#import "FDCertificate.h"
//#import "CertificateManager.h"
#import <Security/SecCertificate.h>

NSString * const kCertificatePkcsData = @"kCertificatePkcsData";
NSString * const kCertificatePasscode = @"kCertificatePasscode";


@interface FDCertificate ()
{
    BOOL verifiedDate;
}
@property (nonatomic, readwrite) SecIdentityRef identityRef;
@property (nonatomic, readwrite) SecCertificateRef identityCertificateRef;
@property (nonatomic, readwrite) NSArray *certificateChain;

@property (nonatomic, readonly) NSDictionary *attributes;
@property (nonatomic, retain) NSData *pkcsData;
@property (nonatomic, copy) NSString *passcode;

@end

@implementation FDCertificate
@synthesize identityRef = _identityRef;
@synthesize identityCertificateRef = _identityCertificateRef;
@synthesize certificateChain = _certificateChain;
@synthesize hasExpired = _hasExpired;
// Private properties
@synthesize attributes = _attributes;
@synthesize pkcsData = _pkcsData;
@synthesize passcode = _passcode;

- (void)dealloc
{
    CFRelease(_identityRef);
    CFRelease(_identityCertificateRef);
    [_certificateChain release];

    [_attributes release];
    [_pkcsData release];
    [_passcode release];
    [super dealloc];
}

- (id)initWithIdentityData:(NSData *)data andPasscode:(NSString *)passcode;
{
    self = [super init];
    if (self)
    {
        _pkcsData = [data retain];
        _passcode = [passcode copy];
        [self configureCertificates];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _pkcsData = [[aDecoder decodeObjectForKey:kCertificatePkcsData] retain];
        _passcode = [[aDecoder decodeObjectForKey:kCertificatePasscode] copy];
        [self configureCertificates];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_pkcsData forKey:kCertificatePkcsData];
    [aCoder encodeObject:_passcode forKey:kCertificatePasscode];
}

- (NSArray *)importPKCS12
{
    NSArray *pkcs12 = nil;
    NSData *pkcsData = [self pkcsData];
    NSString *password = [self passcode];
    
    // TODO: double check for errors. we should've validated the pkcs/passcode at this point
    OSStatus err = SecPKCS12Import((CFDataRef)pkcsData,
                                   (CFDictionaryRef)[NSDictionary dictionaryWithObject:password
                                                                                forKey:(id)kSecImportExportPassphrase],
                                   (CFArrayRef *)&pkcs12);
    if (err != errSecSuccess)
    {
        AlfrescoLogDebug(@"Error importing PKCS12 data, error code: %ld", err);
    }
    
    AlfrescoLogDebug(@"Import result: %@", pkcs12);
    return pkcs12;
}

- (void)configureCertificates
{
    NSArray *importResult = [self importPKCS12];
    SecIdentityRef identity = (SecIdentityRef)[[importResult objectAtIndex:0] objectForKey:(id)kSecImportItemIdentity];
    [self setIdentityRef:identity];
    
    NSArray *certChain = [[[self importPKCS12] objectAtIndex:0] objectForKey:(id)kSecImportItemCertChain];
    [self setCertificateChain:certChain];
    
    SecCertificateRef certificateRef;
    OSStatus err;
    err = SecIdentityCopyCertificate(self.identityRef, &certificateRef);
    if (err == errSecSuccess)
    {
        // SecIdentityCopyCertificate will return a certificateRef with a retain count of one
        // no need to retain it
        [self setIdentityCertificateRef:certificateRef];
    }
}

/*
 The only way to get an identity's attributes is to retrieve it from the keychain
 so we first have to add the identity to the keychain, retrieve the attributes
 and delete the identity from the keychain.
 */
- (NSDictionary *)attributesForIdentity:(SecIdentityRef)identityRef
{
    NSDictionary *attributes = nil;
    //Deleting all the identities in the keychain
    SecItemDelete((CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                     kSecClassIdentity, kSecClass,
                                     nil
                                     ]);
    
    CFTypeRef  persistent_ref = NULL;
    const void *keys[] =   { kSecReturnPersistentRef, kSecValueRef };
    const void *values[] = { kCFBooleanTrue,          identityRef };
    CFDictionaryRef dict = CFDictionaryCreate(NULL, keys, values,
                                              2, NULL, NULL);

    OSStatus status = SecItemAdd(dict, &persistent_ref);
    
    if (dict)
        CFRelease(dict);
    
    if (status == errSecSuccess)
    {
        NSDictionary *queryDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   persistent_ref, kSecValuePersistentRef,
                                   kCFBooleanTrue, kSecReturnAttributes,
                                   kCFBooleanTrue, kSecReturnRef, nil];
        status = SecItemCopyMatching((CFDictionaryRef)queryDict,
                                  (CFTypeRef *) &attributes
                                  );
        
        if (status == errSecSuccess)
        {
            OSStatus    err;
            err = SecItemDelete((CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                                   persistent_ref, kSecValuePersistentRef,
                                                   nil
                                                   ]);
            assert(err == noErr);
        }
    }

    return [attributes autorelease];
}

- (NSString *)summary
{
    NSString *summary = (NSString *)SecCertificateCopySubjectSummary(self.identityCertificateRef);
    return [summary autorelease];
}


- (NSDate *)expiresDate
{
    return nil;
}

- (BOOL)hasExpired
{
    if (!verifiedDate)
    {
        _hasExpired = [self verifyCertificateDate];
        verifiedDate = YES;
    }
    return _hasExpired;
}

- (NSString *)issuer
{
    // Using the method below returns an issuer value that is either not encoded correctly or has some
    // extra information that is not printable
    //NSString *issuer = [[[NSString alloc] initWithData:[self.attributes objectForKey:(id)kSecAttrIssuer]
    //                                          encoding:NSUTF8StringEncoding] autorelease];
    
    // The description of a SecCertificateRef prints out the summary and the issuer in the
    // following form: <cert(0xad4b390) s: tmpalfrescozia1 i: wedcs231.edc.e>
    NSString *certificateDesc = [NSString stringWithFormat:@"%@", self.identityCertificateRef];
    NSError  *error  = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"i\\: (.+)>$"
                                  options:0
                                  error:&error];
    NSArray *matches = [regex matchesInString:certificateDesc
                                               options:0
                                                 range:NSMakeRange(0, [certificateDesc length])];
    
    NSString *issuer = nil;
    if ([matches count] > 0)
    {
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        if (match)
        {
            // 1 means first the first group, 0 contains the whole match
            NSRange matchRange = [match rangeAtIndex:1];
            issuer = [certificateDesc substringWithRange:matchRange];
        }
    }

    return issuer;
}

- (NSDictionary *)attributes
{
    if (!_attributes)
    {
        _attributes = [[self attributesForIdentity:self.identityRef] retain];
    }
    return _attributes;
}

// Source: https://developer.apple.com/library/mac/#documentation/security/conceptual/CertKeyTrustProgGuide/iPhone_Tasks/iPhone_Tasks.html
- (BOOL)verifyCertificateDate
{
    SecPolicyRef myPolicy = SecPolicyCreateSSL(YES, nil);
    
    SecTrustRef myTrust;
    OSStatus status = SecTrustCreateWithCertificates(
                                                     self.certificateChain,
                                                     myPolicy,
                                                     &myTrust);
    
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
        CFRelease(myPolicy);
    if (myTrust)
        CFRelease(myTrust);
    // Assuming that any trustResult but kSecTrustResultProceed
    // means that the certificate is expired
    return trustResult != kSecTrustResultProceed;
}

- (void)setIdentityRef:(SecIdentityRef)identityRef
{
    CFRetain(identityRef);
    if (_identityRef)
        CFRelease(_identityRef);
    _identityRef = identityRef;
}

- (void)setCertificateChain:(NSArray *)certificateChain
{
    [certificateChain retain];
    [_certificateChain release];
    _certificateChain = certificateChain;
}

#pragma mark -
#pragma mark K-V Compliance

- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

@end

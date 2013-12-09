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
@property (nonatomic, retain) NSData *pkcsData;
@property (nonatomic, copy) NSString *passcode;

@end

@implementation FDCertificate
@synthesize identityRef = _identityRef;
@synthesize identityCertificateRef = _identityCertificateRef;
@synthesize certificateChain = _certificateChain;
@synthesize hasExpired = _hasExpired;
@synthesize pkcsData = _pkcsData;
@synthesize passcode = _passcode;

- (void)dealloc
{
    CFRelease(_identityRef);
    CFRelease(_identityCertificateRef);
    [_certificateChain release];

    [_pkcsData release];
    [_passcode release];
    [super dealloc];
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

@end

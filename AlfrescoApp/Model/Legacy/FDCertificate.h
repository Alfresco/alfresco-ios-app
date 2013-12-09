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
//  FDCertificate.h
//
// Encapsulates data extration from identities and certificates
// that use a Core Fundation API and provides a clean Objective-C API
// to access certificate information
// Some functionality is specific to PKCS12 certificates and so this class
// is only used to handle those certificates.
// When encoding this object, it will save the whole PKCS12 data and its passcode

#import <Foundation/Foundation.h>

@interface FDCertificate : NSObject
@property (nonatomic, readonly) SecIdentityRef identityRef;
@property (nonatomic, readonly) SecCertificateRef identityCertificateRef;
@property (nonatomic, readonly) NSArray *certificateChain;
@property (readonly) NSString *summary;
@property (readonly) NSDate *expiresDate;
@property (nonatomic, readonly) BOOL hasExpired;
@property (readonly) NSString *issuer;

/*
 Init for a FDCertificate with the provided identity data (PKCS12) and passcode.
 */
- (id)initWithIdentityData:(NSData *)data andPasscode:(NSString *)passcode;

@end

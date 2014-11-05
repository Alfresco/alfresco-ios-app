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
//  AccountInfo.h
//

# import <Foundation/Foundation.h>
#import "AccountStatus.h"

extern NSString * const kServerAccountId;
extern NSString * const kServerVendor;
extern NSString * const kServerDescription;
extern NSString * const kServerProtocol;
extern NSString * const kServerHostName;
extern NSString * const kServerPort;
extern NSString * const kServerServiceDocumentRequestPath;
extern NSString * const kServerUsername;
extern NSString * const kServerPassword;
extern NSString * const kServerInformation;
extern NSString * const kServerMultitenant;
extern NSString * const kCloudId;
extern NSString * const kCloudKey;
extern NSString * const kIsDefaultAccount;

@interface AccountInfo : NSObject <NSCoding>
@property (nonatomic, readonly) NSString *uuid;
@property (nonatomic, retain) NSString *vendor;
@property (nonatomic, retain) NSString *summary;
@property (nonatomic, retain) NSString *protocol;
@property (nonatomic, retain) NSString *hostname;
@property (nonatomic, retain) NSString *port;
@property (nonatomic, retain) NSString *serviceDocumentRequestPath;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSMutableDictionary *infoDictionary;
@property (nonatomic, retain) NSNumber *multitenant;
@property (nonatomic, retain) NSString *cloudId;
@property (nonatomic, retain) NSString *cloudKey;
@property (nonatomic, assign) FDAccountStatus accountStatus;
@property (nonatomic, assign) BOOL isDefaultAccount;
@property (nonatomic, assign) BOOL isQualifyingAccount;
@property (nonatomic, retain) AccountStatus *accountStatusInfo;

@end

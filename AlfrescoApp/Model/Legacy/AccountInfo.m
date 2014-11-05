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
//  AccountInfo.m
//

#import "AccountInfo.h"

NSString * const kServerAccountId = @"kServerAccountId";
NSString * const kServerVendor = @"kServerVendor";
NSString * const kServerDescription = @"kServerDescription";
NSString * const kServerProtocol = @"kServerProtocol";
NSString * const kServerHostName = @"kServerHostName";
NSString * const kServerPort = @"kServerPort";
NSString * const kServerServiceDocumentRequestPath = @"kServerServiceDocumentRequestPath";
NSString * const kServerUsername = @"kServerUsername";
NSString * const kUserFirstName = @"kServerFirstName";
NSString * const kUserLastName = @"kServerLastName";
NSString * const kServerPassword = @"kServerPassword";
NSString * const kServerInformation = @"kServerInformation";
NSString * const kServerMultitenant = @"kServerMultitenant";
NSString * const kCloudId = @"kCloudId";
NSString * const kCloudKey = @"kCloudKey";
NSString * const kServerStatus = @"kServerStatus";
NSString * const kIsDefaultAccount = @"kIsDefaultAccount";
NSString * const kServerIsQualifying = @"kServerIsQualifying";

@implementation AccountInfo

#pragma mark Object Lifecycle
- (void)dealloc
{
    [_uuid release];
    [_vendor release];
    [_summary release];
    [_protocol release];
    [_hostname release];
    [_port release];
    [_serviceDocumentRequestPath release];
    [_username release];
    [_firstName release];
    [_lastName release];
    [_password release];
    [_infoDictionary release];
    [_cloudId release];
    [_cloudKey release];
    [_multitenant release];
    [_accountStatusInfo release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) 
    {
        _uuid = [aDecoder decodeObjectForKey:kServerAccountId];
        [_uuid retain];
        
        _vendor = [[aDecoder decodeObjectForKey:kServerVendor] retain];
        _summary = [[aDecoder decodeObjectForKey:kServerDescription] retain];
        _protocol = [[aDecoder decodeObjectForKey:kServerProtocol] retain];
        _hostname = [[aDecoder decodeObjectForKey:kServerHostName] retain];
        _port = [[aDecoder decodeObjectForKey:kServerPort] retain];
        _serviceDocumentRequestPath = [[aDecoder decodeObjectForKey:kServerServiceDocumentRequestPath] retain];
        _username = [[aDecoder decodeObjectForKey:kServerUsername] retain];
        _firstName = [[aDecoder decodeObjectForKey:kUserFirstName] retain];
        _lastName = [[aDecoder decodeObjectForKey:kUserLastName] retain];
        _password = [[aDecoder decodeObjectForKey:kServerPassword] retain];
        _infoDictionary = [[aDecoder decodeObjectForKey:kServerInformation] retain];
        _multitenant = [[aDecoder decodeObjectForKey:kServerMultitenant] retain];
        _cloudId = [[aDecoder decodeObjectForKey:kCloudId] retain];
        _cloudKey = [[aDecoder decodeObjectForKey:kCloudKey] retain];
        _isDefaultAccount = [[aDecoder decodeObjectForKey:kIsDefaultAccount] intValue];
        _isQualifyingAccount = [[aDecoder decodeObjectForKey:kServerIsQualifying] boolValue];

        FDAccountStatus accountStatus = [[aDecoder decodeObjectForKey:kServerStatus] intValue];
        _accountStatusInfo = [[AccountStatus alloc] init];
        [_accountStatusInfo setAccountStatus:accountStatus];
        [_accountStatusInfo setUuid:_uuid];

    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_uuid forKey:kServerAccountId];
    [aCoder encodeObject:_vendor forKey:kServerVendor];
    [aCoder encodeObject:_summary forKey:kServerDescription];
    [aCoder encodeObject:_protocol forKey:kServerProtocol];
    [aCoder encodeObject:_hostname forKey:kServerHostName];
    [aCoder encodeObject:_port forKey:kServerPort];
    [aCoder encodeObject:_serviceDocumentRequestPath forKey:kServerServiceDocumentRequestPath];
    [aCoder encodeObject:_username forKey:kServerUsername];
    [aCoder encodeObject:_firstName forKey:kUserFirstName];
    [aCoder encodeObject:_lastName forKey:kUserLastName];
    [aCoder encodeObject:_password forKey:kServerPassword];
    [aCoder encodeObject:_infoDictionary forKey:kServerInformation];
    [aCoder encodeObject:_multitenant forKey:kServerMultitenant];
    [aCoder encodeObject:_cloudId forKey:kCloudId];
    [aCoder encodeObject:_cloudKey forKey:kCloudKey];
    [aCoder encodeObject:[NSNumber numberWithBool:_isDefaultAccount] forKey:kIsDefaultAccount];
    [aCoder encodeObject:[NSNumber numberWithBool:_isQualifyingAccount] forKey:kServerIsQualifying];
}

@end

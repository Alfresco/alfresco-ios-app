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
//  AccountStatus.m
//

#import "AccountStatus.h"

@implementation AccountStatus
@synthesize uuid = _uuid;
@synthesize accountStatus = _accountStatus;
@synthesize successTimestamp = _successTimestamp;

- (void)dealloc
{
    [_uuid release];
    [super dealloc];
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) 
    {
        _accountStatus = [[aDecoder decodeObjectForKey:@"accountStatus"] intValue];
        _successTimestamp = [[aDecoder decodeObjectForKey:@"successTimestamp"] doubleValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSNumber numberWithInt:_accountStatus] forKey:@"accountStatus"];
    [aCoder encodeObject:[NSNumber numberWithDouble:_successTimestamp] forKey:@"successTimestamp"];
}

@end

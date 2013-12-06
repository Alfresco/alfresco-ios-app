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
#import "Utility.h"

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
- (id)init 
{
    // TODO static NSString objects
    
    self = [super init];
    if(self) {
        [self setSuccessTimestamp:[[NSDate date] timeIntervalSince1970]];
        [self setAccountStatus:FDAccountStatusActive];
    }
    
    return self;
}

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


- (NSString *)shortMessage
{
    if(self.accountStatus == FDAccountStatusAwaitingVerification)
    {
        return NSLocalizedString(@"account.awaiting.cell.subtitle", @"Awaiting for verification short message");
    }
    else if(self.accountStatus == FDAccountStatusInactive)
    {
        return NSLocalizedString(@"account.inactive.cell.subtitle", @"Inactive account short message");
    }
    else if(self.accountStatus == FDAccountStatusConnectionError)
    {
        return NSLocalizedString(@"account.connection-error.cell.subtitle", @"Connection error short message");
    }
    else if(self.accountStatus == FDAccountStatusInvalidCredentials)
    {
        return NSLocalizedString(@"account.invalid-credentials.cell.subtitle", @"Invalid credentials short messages");
    }
    else if(self.accountStatus == FDAccountStatusInvalidCertificate)
    {
        return NSLocalizedString(@"account.invalid-certificate.cell.subtitle", @"Invalid certificate short message");
    }
    return nil;
}

- (UIColor *)shortMessageTextColor
{
    if(self.accountStatus == FDAccountStatusInactive)
    {
        return [UIColor darkGrayColor];
    }
    else if([self isError])
    {
        return [UIColor redColor];
    }
    
    return [UIColor darkGrayColor];
}

- (NSString *)detailedMessage
{
    if(self.accountStatus == FDAccountStatusConnectionError)
    {
        NSDate *lastSuccess = [NSDate dateWithTimeIntervalSince1970:self.successTimestamp];
        return [NSString stringWithFormat:NSLocalizedString(@"accountdetails.fields.connection-error", @"Connection error message"), relativeDateFromDate(lastSuccess)];
    }
    else if(self.accountStatus == FDAccountStatusInvalidCredentials)
    {
        return NSLocalizedString(@"accountdetails.fields.invalid-credentials", @"Invalid credentials message");
    }
    else if(self.accountStatus == FDAccountStatusInvalidCertificate)
    {
        return NSLocalizedString(@"accountdetails.fields.invalid-certificate", @"Invalid Certificate message");
    }
    return nil;
}

- (BOOL)isError
{
    return self.accountStatus == FDAccountStatusConnectionError ||
        self.accountStatus == FDAccountStatusInvalidCredentials ||
        self.accountStatus == FDAccountStatusInvalidCertificate;
}

- (BOOL)isActive
{
    return self.accountStatus == FDAccountStatusActive || [self isError];
}

#pragma mark -
#pragma mark K-V Compliance

- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

@end

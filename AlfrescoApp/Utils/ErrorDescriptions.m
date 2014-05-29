//
//  ErrorDescriptions.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ErrorDescriptions.h"
#import "ConnectivityManager.h"

static NSString * const kErrorDescriptionNetworkNotAvailable = @"error.no.internet.access.message";
static NSString * const kErrorDescriptionAccessPermissions = @"error.access.permissions.message";
static NSString * const kErrorDescriptionHostUnreachable = @"error.host.unreachable.message";
static NSString * const kErrorDescriptionLoginFailed = @"error.login.failed";

@implementation ErrorDescriptions

+ (NSString *)descriptionForError:(NSError *)error
{
    NSString *errorDescription = nil;
    
    if (error.code < 0 || ![[ConnectivityManager sharedManager] hasInternetConnection])
    {
        errorDescription = NSLocalizedString(kErrorDescriptionNetworkNotAvailable, @"Network not available");
    }
    else if ([error.domain isEqualToString:kAlfrescoErrorDomainName])
    {
        errorDescription = [self descriptionForAlfrescoError:error];
    }
    else
    {
        errorDescription = error.localizedDescription;
    }
    return errorDescription;
}

+ (NSString *)descriptionForAlfrescoError:(NSError *)error
{
    NSString *errorDescription = nil;
    
    switch (error.code)
    {
        case kAlfrescoErrorCodeHTTPResponse:
            errorDescription = NSLocalizedString(kErrorDescriptionAccessPermissions, @"SDK HTTP Response error");
            break;
            
        case kAlfrescoErrorCodeNoNetworkConnection:
            errorDescription = NSLocalizedString(kErrorDescriptionHostUnreachable, @"Host unreachable");
            break;

        case kAlfrescoErrorCodeUnauthorisedAccess:
            errorDescription = NSLocalizedString(kErrorDescriptionLoginFailed, @"Login failed");
            break;

        default:
            errorDescription = error.localizedDescription;
            break;
    }
    return errorDescription;
}

@end

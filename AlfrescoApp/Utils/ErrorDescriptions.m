//
//  ErrorDescriptions.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ErrorDescriptions.h"
#import "AlfrescoErrors.h"

static NSString * const kErrorDescriptionNetworkNotAvailable = @"error.no.internet.access.message";
static NSString * const kErrorDescriptionAccessPermissions = @"error.access.permissions.message";

@implementation ErrorDescriptions

+ (NSString *)descriptionForError:(NSError *)error
{
    NSString *errorDescription = nil;
    
    if ([error.domain isEqualToString:kAlfrescoErrorDomainName])
    {
        errorDescription = [self descriptionForAlfrescoError:error];
    }
    else if (error.code < 0)
    {
        errorDescription = NSLocalizedString(kErrorDescriptionNetworkNotAvailable, @"Network not available");
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
        {
            errorDescription = NSLocalizedString(kErrorDescriptionAccessPermissions, @"SDK HTTP Response error");
            break;
        }
        default:
        {
            errorDescription = error.localizedDescription;
            break;
        }
    }
    return errorDescription;
}

@end

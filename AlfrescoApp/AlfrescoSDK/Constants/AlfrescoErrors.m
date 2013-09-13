/*******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile SDK.
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

#import "AlfrescoErrors.h"
#import "AlfrescoInternalConstants.h"

NSString * const kAlfrescoErrorDomainName = @"AlfrescoErrorDomain";

NSString * const kAlfrescoErrorDescriptionUnknown = @"Unknown Alfresco Error";
NSString * const kAlfrescoErrorDescriptionRequestedNodeNotFound = @"The requested node wasn't found";
NSString * const kAlfrescoErrorDescriptionAccessDenied = @"Access Denied";

NSString * const kAlfrescoErrorDescriptionSession = @"Session Error";
NSString * const kAlfrescoErrorDescriptionNoRepositoryFound = @"Session Error: No Alfresco repository found";
NSString * const kAlfrescoErrorDescriptionUnauthorisedAccess = @"Session Error: Unauthorised Access";
NSString * const kAlfrescoErrorDescriptionHTTPResponse= @"Session Error: the HTTP Response code suggests an error";
NSString * const kAlfrescoErrorDescriptionNoNetworkFound = @"Session Error: No Cloud network/domain found";
NSString * const kAlfrescoErrorDescriptionAPIKeyOrSecretKeyUnrecognised = @"The API or Secret Key (or both) are unrecognised";
NSString * const kAlfrescoErrorDescriptionAuthorizationCodeInvalid = @"The authentication code is invalid";
NSString * const kAlfrescoErrorDescriptionAccessTokenExpired = @"The access token has expired";
NSString * const kAlfrescoErrorDescriptionRefreshTokenExpired = @"The refresh token has expired";
NSString * const kAlfrescoErrorDescriptionNetworkRequestCancelled = @"The network request was cancelled";
NSString * const kAlfrescoErrorDescriptionRefreshTokenInvalid = @"Refresh token validation failed";

NSString * const kAlfrescoErrorDescriptionJSONParsing = @"JSON Data parsing Error";
NSString * const kAlfrescoErrorDescriptionJSONParsingNilData = @"JSON Data are nil/empty";
NSString * const kAlfrescoErrorDescriptionJSONParsingNoEntry = @"JSON Data: missing entry element";
NSString * const kAlfrescoErrorDescriptionJSONParsingNoEntries = @"JSON Data: missing entries element";

NSString * const kAlfrescoErrorDescriptionComment = @"Comment Service Error";
NSString * const kAlfrescoErrorDescriptionCommentNoCommentFound = @"Comment Service Error: No Comments were found";

NSString * const kAlfrescoErrorDescriptionSites = @"Sites Service Error";
NSString * const kAlfrescoErrorDescriptionSitesNoDocLib = @"Sites Service Error: No Document Library was found";
NSString * const kAlfrescoErrorDescriptionSitesNoSites = @"Sites Service Error: No Sites were found.";
NSString * const kAlfrescoErrorDescriptionSitesUserIsAlreadyMember = @"Sites Service Error: User is already member of this site.";
NSString * const kAlfrescoErrorDescriptionSitesUserCannotBeRemoved = @"Sites Service Error: User cannot be removed from site. Probably because he/she is the last remaining site manager.";

NSString * const kAlfrescoErrorDescriptionActivityStream =@"Activity Stream Service Error";
NSString * const kAlfrescoErrorDescriptionActivityStreamNoActivities =@"Activity Stream Service Error: No Activities were found.";

NSString * const kAlfrescoErrorDescriptionDocumentFolder = @"Document Folder Service Error";
NSString * const kAlfrescoErrorDescriptionDocumentFolderPermissions = @"Document Folder Service Error: Error retrieving Permissions";
NSString * const kAlfrescoErrorDescriptionDocumentFolderNoParent = @"Document Folder Service Error: No Parent Folder";
NSString * const kAlfrescoErrorDescriptionDocumentFolderWrongNodeType = @"Document Folder Service Error: wrong node type. Expected either folder or document.";
NSString * const kAlfrescoErrorDescriptionDocumentFolderNodeAlreadyExists = @"Node already exists";
NSString * const kAlfrescoErrorDescriptionDocumentFolderFailedToConvertNode = @"Node could not be converted to an Alfresco object";



NSString * const kAlfrescoErrorDescriptionDocumentFolderNoThumbnail = @"Document Folder Service Error: No Thumbnail found for document/folder.";

NSString * const kAlfrescoErrorDescriptionTagging = @"Tagging Service Error";
NSString * const kAlfrescoErrorDescriptionTaggingNoTags = @"Tagging Service Error: No tags were found.";

NSString * const kAlfrescoErrorDescriptionPerson = @"Person Service Error";
NSString * const kAlfrescoErrorDescriptionPersonNoAvatarFound = @"Person Service Error: no avatar for the user was found.";
NSString * const kAlfrescoErrorDescriptionPersonNotFound = @"Person Service Error: person/user wasn't found.";

NSString * const kAlfrescoErrorDescriptionSearch = @"Search Service Error";

NSString * const kAlfrescoErrorDescriptionRatings = @"Ratings Service Error";
NSString * const kAlfrescoErrorDescriptionRatingsNoRatings = @"No Ratings found";

NSString * const kAlfrescoErrorDescriptionWorkflowFunctionNotSupported = @"Function not supported on this version of Alfresco";
NSString * const kAlfrescoErrorDescriptionWorkflowNoProcessDefinitionFound = @"Workflow Process Definition Service Error: No workflow process definitions were found.";
NSString * const kAlfrescoErrorDescriptionWorkflowNoProcessFound = @"Workflow Process Service Error: No workflow processes were found.";
NSString * const kAlfrescoErrorDescriptionWorkflowNoTaskFound = @"Workflow Task Service Error: No workflow tasks were found.";

@implementation AlfrescoErrors

+ (NSError *)alfrescoErrorWithUnderlyingError:(NSError *)error andAlfrescoErrorCode:(AlfrescoErrorCodes)code
{
    if (error == nil) //shouldn't really get there
    {
        return nil;
    }
    if ([error.domain isEqualToString:kAlfrescoErrorDomainName])
    {
        return error;
    }
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
    [errorInfo setValue:[AlfrescoErrors descriptionForAlfrescoErrorCode:code] forKey:NSLocalizedDescriptionKey];
    [errorInfo setObject:error forKey:NSUnderlyingErrorKey];
    return [NSError errorWithDomain:kAlfrescoErrorDomainName code:code userInfo:errorInfo];
}


+ (NSError *)alfrescoErrorWithAlfrescoErrorCode:(AlfrescoErrorCodes)code
{
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
    [errorInfo setValue:[AlfrescoErrors descriptionForAlfrescoErrorCode:code] forKey:NSLocalizedDescriptionKey];
    NSString *standardDescription = [AlfrescoErrors descriptionForAlfrescoErrorCode:code];
    [errorInfo setValue:standardDescription forKey:NSLocalizedFailureReasonErrorKey];
    return [NSError errorWithDomain:kAlfrescoErrorDomainName code:code userInfo:errorInfo];
}

+ (NSError *)alfrescoErrorFromJSONParameters:(NSDictionary *)parameters
{
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
    id errorObj = [parameters valueForKey:kAlfrescoJSONError];
    id descriptionObj = [parameters valueForKey:kAlfrescoJSONErrorDescription];

    int code = kAlfrescoErrorCodeJSONParsing;
    if (nil != errorObj && [errorObj isKindOfClass:[NSString class]])
    {
        NSString *errorCode = (NSString *)errorObj;
        if ([errorCode hasPrefix:@"invalid_request"])
        {
            BOOL isExpired = ([descriptionObj rangeOfString:@"expired"].location != NSNotFound);
            
            if ([descriptionObj hasPrefix:@"refresh_token"])
            {
                code = isExpired ? kAlfrescoErrorCodeRefreshTokenExpired : kAlfrescoErrorCodeRefreshTokenInvalid;
            }
            else
            {
                code = kAlfrescoErrorCodeInvalidRequest;
            }
        }
        else if([errorCode hasPrefix:@"invalid_grant"])
        {
            code = kAlfrescoErrorCodeInvalidGrant;
        }
        else if ([errorCode hasPrefix:@"invalid_client"])
        {
            code = kAlfrescoErrorCodeInvalidClient;
        }
        else if ([errorCode hasPrefix:@"invalid_token_type"])
        {
            code = kAlfrescoErrorCodeRefreshTokenInvalid;
        }
    }

    if (nil != descriptionObj && [descriptionObj isKindOfClass:[NSString class]])
    {
        NSString *description = (NSString *)descriptionObj;
        [errorInfo setValue:description forKey:NSLocalizedDescriptionKey];
        [errorInfo setValue:description forKey:NSLocalizedFailureReasonErrorKey];
    }
    else
    {
        [errorInfo setValue:[AlfrescoErrors descriptionForAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing] forKey:NSLocalizedDescriptionKey];
        [errorInfo setValue:[AlfrescoErrors descriptionForAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing] forKey:NSLocalizedFailureReasonErrorKey];
    }
    return [NSError errorWithDomain:kAlfrescoErrorDomainName code:code userInfo:errorInfo];
}

+ (void)assertArgumentNotNil:(id)argument argumentName:(NSString *)argumentName
{
    if (nil == argument)
    {
        NSString * message = [NSString stringWithFormat:@"%@ must not be nil",argumentName];
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:message userInfo:nil];
        @throw exception;
    }
}

+ (void)assertStringArgumentNotNilOrEmpty:(NSString *)argument argumentName:(NSString *)argumentName
{
    if (nil == argument)
    {
        NSString * message = [NSString stringWithFormat:@"%@ must not be nil",argumentName];
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:message userInfo:nil];
        @throw exception;
    }
    else if ([argument isEqualToString:@""])
    {
        NSString * message = [NSString stringWithFormat:@"%@ must not be empty",argumentName];
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:message userInfo:nil];
        @throw exception;
    }
}

+ (NSString *)descriptionForAlfrescoErrorCode:(AlfrescoErrorCodes)code
{
    NSString *alfrescoErrorDescription = nil;
    
    switch (code)
    {
        case kAlfrescoErrorCodeUnknown:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionUnknown;
            break;
        case kAlfrescoErrorCodeHTTPResponse:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionHTTPResponse;
            break;
        case kAlfrescoErrorCodeRequestedNodeNotFound:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionRequestedNodeNotFound;
            break;
        case kAlfrescoErrorCodeAccessDenied:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionAccessDenied;
            break;
        case kAlfrescoErrorCodeSession:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionSession;
            break;
        case kAlfrescoErrorCodeNoRepositoryFound:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionNoRepositoryFound;
            break;
        case kAlfrescoErrorCodeUnauthorisedAccess:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionUnauthorisedAccess;
            break;
            
        case kAlfrescoErrorCodeAPIKeyOrSecretKeyUnrecognised:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionAPIKeyOrSecretKeyUnrecognised;
            break;
        case kAlfrescoErrorCodeAuthorizationCodeInvalid:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionAuthorizationCodeInvalid;
            break;
        case kAlfrescoErrorCodeAccessTokenExpired:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionAccessTokenExpired;
            break;
        case kAlfrescoErrorCodeRefreshTokenExpired:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionRefreshTokenExpired;
            break;
            
        case kAlfrescoErrorCodeNoNetworkFound:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionNoNetworkFound;
            break;
        case kAlfrescoErrorCodeNetworkRequestCancelled:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionNetworkRequestCancelled;
            break;
        case kAlfrescoErrorCodeRefreshTokenInvalid:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionRefreshTokenInvalid;
            break;
        case kAlfrescoErrorCodeJSONParsing:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionJSONParsing;
            break;
        case kAlfrescoErrorCodeJSONParsingNilData:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionJSONParsingNilData;
            break;
        case kAlfrescoErrorCodeJSONParsingNoEntries:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionJSONParsingNoEntries;
            break;
        case kAlfrescoErrorCodeJSONParsingNoEntry:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionJSONParsingNoEntry;
            break;
        case kAlfrescoErrorCodeComment:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionComment;
            break;
        case kAlfrescoErrorCodeCommentNoCommentFound:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionCommentNoCommentFound;
            break;
        case kAlfrescoErrorCodeSites:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionSites;
            break;
        case kAlfrescoErrorCodeSitesNoDocLib:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionSitesNoDocLib;
            break;
        case kAlfrescoErrorCodeSitesNoSites:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionSitesNoSites;
            break;
        case kAlfrescoErrorCodeSitesUserCannotBeRemoved:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionSitesUserCannotBeRemoved;
            break;
        case kAlfrescoErrorCodeSitesUserIsAlreadyMember:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionSitesUserIsAlreadyMember;
            break;
        case kAlfrescoErrorCodeActivityStream:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionActivityStream;
            break;
        case kAlfrescoErrorCodeActivityStreamNoActivities:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionActivityStreamNoActivities;
            break;
        case kAlfrescoErrorCodeDocumentFolder:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionDocumentFolder;
            break;
        case kAlfrescoErrorCodeDocumentFolderPermissions:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionDocumentFolderPermissions;
            break;
        case kAlfrescoErrorCodeDocumentFolderNodeAlreadyExists:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionDocumentFolderNodeAlreadyExists;
            break;
        case kAlfrescoErrorCodeDocumentFolderNoParent:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionDocumentFolderNoParent;
            break;
        case kAlfrescoErrorCodeDocumentFolderFailedToConvertNode:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionDocumentFolderFailedToConvertNode;
            break;
        case kAlfrescoErrorCodeDocumentFolderWrongNodeType:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionDocumentFolderWrongNodeType;
            break;
        case kAlfrescoErrorCodeDocumentFolderNoThumbnail:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionDocumentFolderNoThumbnail;
            break;
        case kAlfrescoErrorCodeTagging:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionTagging;
            break;
        case kAlfrescoErrorCodeTaggingNoTags:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionTaggingNoTags;
            break;
        case kAlfrescoErrorCodePerson:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionPerson;
            break;
        case kAlfrescoErrorCodePersonNoAvatarFound:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionPersonNoAvatarFound;
            break;
        case kAlfrescoErrorCodePersonNotFound:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionPersonNotFound;
            break;
        case kAlfrescoErrorCodeSearch:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionSearch;
            break;
        case kAlfrescoErrorCodeRatings:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionRatings;
            break;
        case kAlfrescoErrorCodeRatingsNoRatings:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionRatingsNoRatings;
            break;
        case kAlfrescoErrorCodeWorkflowFunctionNotSupported:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionWorkflowFunctionNotSupported;
            break;
        case kAlfrescoErrorCodeWorkflowNoProcessDefinitionFound:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionWorkflowNoProcessDefinitionFound;
            break;
        case kAlfrescoErrorCodeWorkflowNoProcessFound:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionWorkflowNoProcessFound;
            break;
        case kAlfrescoErrorCodeWorkflowNoTaskFound:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionWorkflowNoTaskFound;
            break;
        default:
            alfrescoErrorDescription = kAlfrescoErrorDescriptionUnknown;
            break;
    }
    return alfrescoErrorDescription;
}

@end

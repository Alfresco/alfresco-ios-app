/*
 ******************************************************************************
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
 *****************************************************************************
 */


#import <Foundation/Foundation.h>
/** The AlfrescoErrors error definitions for Mobile SDK.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

typedef enum 
{
    kAlfrescoErrorCodeUnknown = 0,
    kAlfrescoErrorCodeHTTPResponse = 1,
    kAlfrescoErrorCodeRequestedNodeNotFound = 2,
    kAlfrescoErrorCodeAccessDenied = 3,

    kAlfrescoErrorCodeSession = 100,
    kAlfrescoErrorCodeUnauthorisedAccess = 101,
    kAlfrescoErrorCodeAPIKeyOrSecretKeyUnrecognised = 102,
    kAlfrescoErrorCodeAuthorizationCodeInvalid = 103,
    kAlfrescoErrorCodeAccessTokenExpired = 104,
    kAlfrescoErrorCodeRefreshTokenExpired = 105,
    kAlfrescoErrorCodeNoRepositoryFound = 106,
    kAlfrescoErrorCodeNoNetworkFound = 107,
    kAlfrescoErrorCodeNetworkRequestCancelled = 110,
    kAlfrescoErrorCodeRefreshTokenInvalid = 111,
    kAlfrescoErrorCodeInvalidRequest = 112,
    kAlfrescoErrorCodeInvalidClient = 113,
    kAlfrescoErrorCodeInvalidGrant = 114,

    kAlfrescoErrorCodeJSONParsing = 200,
    kAlfrescoErrorCodeJSONParsingNilData = 201,
    kAlfrescoErrorCodeJSONParsingNoEntry = 202,
    kAlfrescoErrorCodeJSONParsingNoEntries = 203,
    
    kAlfrescoErrorCodeComment = 300,
    kAlfrescoErrorCodeCommentNoCommentFound = 301,

    kAlfrescoErrorCodeSites = 400,
    kAlfrescoErrorCodeSitesNoDocLib = 401,
    kAlfrescoErrorCodeSitesNoSites = 402,
    kAlfrescoErrorCodeSitesUserIsAlreadyMember = 403,
    kAlfrescoErrorCodeSitesUserCannotBeRemoved = 404,

    kAlfrescoErrorCodeActivityStream = 500,
    kAlfrescoErrorCodeActivityStreamNoActivities = 501,

    kAlfrescoErrorCodeDocumentFolder = 600,
    kAlfrescoErrorCodeDocumentFolderNodeAlreadyExists = 601,
    kAlfrescoErrorCodeDocumentFolderWrongNodeType = 602,
    kAlfrescoErrorCodeDocumentFolderPermissions = 603,
    kAlfrescoErrorCodeDocumentFolderFailedToConvertNode = 604,
    kAlfrescoErrorCodeDocumentFolderNoParent = 605,
    kAlfrescoErrorCodeDocumentFolderNoThumbnail = 606,

    kAlfrescoErrorCodeTagging = 700,
    kAlfrescoErrorCodeTaggingNoTags = 701,

    kAlfrescoErrorCodePerson = 800,
    kAlfrescoErrorCodePersonNotFound = 801,
    kAlfrescoErrorCodePersonNoAvatarFound = 802,

    kAlfrescoErrorCodeSearch = 900,

    kAlfrescoErrorCodeRatings = 1000,
    kAlfrescoErrorCodeRatingsNoRatings = 1001,
    
    kAlfrescoErrorCodeFavorites = 1100,
    
    kAlfrescoErrorCodeWorkflowFunctionNotSupported = 2000,
    kAlfrescoErrorCodeWorkflowNoProcessDefinitionFound = 2001,
    kAlfrescoErrorCodeWorkflowNoProcessFound = 2002,
    kAlfrescoErrorCodeWorkflowNoTaskFound = 2003
    
}AlfrescoErrorCodes;

extern NSString * const kAlfrescoErrorDomainName;
extern NSString * const kAlfrescoErrorDescriptionUnknown;
extern NSString * const kAlfrescoErrorDescriptionRequestedNodeNotFound;
extern NSString * const kAlfrescoErrorDescriptionAccessDenied;

extern NSString * const kAlfrescoErrorDescriptionSession;
extern NSString * const kAlfrescoErrorDescriptionNoRepositoryFound;
extern NSString * const kAlfrescoErrorDescriptionUnauthorisedAccess;
extern NSString * const kAlfrescoErrorDescriptionHTTPResponse;
extern NSString * const kAlfrescoErrorDescriptionNoNetworkFound;
extern NSString * const kAlfrescoErrorDescriptionAPIKeyOrSecretKeyUnrecognised;
extern NSString * const kAlfrescoErrorDescriptionAuthorizationCodeInvalid;
extern NSString * const kAlfrescoErrorDescriptionAccessTokenExpired;
extern NSString * const kAlfrescoErrorDescriptionRefreshTokenExpired;
extern NSString * const kAlfrescoErrorDescriptionNetworkRequestCancelled;
extern NSString * const kAlfrescoErrorDescriptionRefreshTokenInvalid;

extern NSString * const kAlfrescoErrorDescriptionJSONParsing;
extern NSString * const kAlfrescoErrorDescriptionJSONParsingNilData;
extern NSString * const kAlfrescoErrorDescriptionJSONParsingNoEntry;
extern NSString * const kAlfrescoErrorDescriptionJSONParsingNoEntries;

extern NSString * const kAlfrescoErrorDescriptionComment;
extern NSString * const kAlfrescoErrorDescriptionCommentNoCommentFound;

extern NSString * const kAlfrescoErrorDescriptionSites;
extern NSString * const kAlfrescoErrorDescriptionSitesNoDocLib;
extern NSString * const kAlfrescoErrorDescriptionSitesNoSites;
extern NSString * const kAlfrescoErrorDescriptionSitesUserIsAlreadyMember;
extern NSString * const kAlfrescoErrorDescriptionSitesUserCannotBeRemoved;
extern NSString * const kAlfrescoErrorDescriptionActivityStream;
extern NSString * const kAlfrescoErrorDescriptionActivityStreamNoActivities;

extern NSString * const kAlfrescoErrorDescriptionDocumentFolder;
extern NSString * const kAlfrescoErrorDescriptionDocumentFolderPermissions;
extern NSString * const kAlfrescoErrorDescriptionDocumentFolderNoParent;
extern NSString * const kAlfrescoErrorDescriptionDocumentFolderWrongNodeType;
extern NSString * const kAlfrescoErrorDescriptionDocumentFolderNoThumbnail;
extern NSString * const kAlfrescoErrorDescriptionDocumentFolderNodeAlreadyExists;
extern NSString * const kAlfrescoErrorDescriptionDocumentFolderFailedToConvertNode;


extern NSString * const kAlfrescoErrorDescriptionTagging;
extern NSString * const kAlfrescoErrorDescriptionTaggingNoTags;

extern NSString * const kAlfrescoErrorDescriptionPerson;
extern NSString * const kAlfrescoErrorDescriptionPersonNoAvatarFound;
extern NSString * const kAlfrescoErrorDescriptionPersonNotFound;

extern NSString * const kAlfrescoErrorDescriptionSearch;

extern NSString * const kAlfrescoErrorDescriptionRatings;
extern NSString * const kAlfrescoErrorDescriptionRatingsNoRatings;

extern NSString * const kAlfrescoErrorDescriptionWorkflowFunctionNotSupported;
extern NSString * const kAlfrescoErrorDescriptionWorkflowNoProcessDefinitionFound;
extern NSString * const kAlfrescoErrorDescriptionWorkflowNoProcessFound;
extern NSString * const kAlfrescoErrorDescriptionWorkflowNoTaskFound;


/** AlfrescoErrors is used in case an error occurs when executing an operation against the Alfresco repository.
 
 Author: Peter Schmidt (Alfresco)
 */

@interface AlfrescoErrors : NSObject

/**---------------------------------------------------------------------------------------
 * @name Error creation methods.
 *  ---------------------------------------------------------------------------------------
 */

/** Creates an error object based on another NSError instance.
 
 @param error The error that's used to create an Alfresco error instance.
 @param code the code string that represents the error type.
 @return The newly created error.
 */
+ (NSError *)alfrescoErrorWithUnderlyingError:(NSError *)error andAlfrescoErrorCode:(AlfrescoErrorCodes)code;


/** Creates an error object based on an error code and a description.
 
 @param code the code string that represents the error type.
 @return The newly created error.
 */
+ (NSError *)alfrescoErrorWithAlfrescoErrorCode:(AlfrescoErrorCodes)code;


+ (NSError *)alfrescoErrorFromJSONParameters:(NSDictionary *)parameters;

/**
 asserts that an argument is not nil. If a required argument is nil, this is considered a fatal error, and the SDK will throw an exception.
 This will most likely cause the app to exit/crash.
 @param argument
 @param argumentName
 */
+ (void)assertArgumentNotNil:(id)argument argumentName:(NSString *)argumentName;

/**
 asserts that an argument is not nil. If a required argument is nil, this is considered a fatal error, and the SDK will throw an exception.
 This will most likely cause the app to exit/crash.
 @param argument
 @param argumentName
 */
+ (void)assertStringArgumentNotNilOrEmpty:(NSString *)argument argumentName:(NSString *)argumentName;
@end

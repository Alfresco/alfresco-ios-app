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
#import "AlfrescoPagingResult.h"
#import "AlfrescoListingContext.h"
#import "AlfrescoContentFile.h"
#import "AlfrescoPermissions.h"
#import "AlfrescoPerson.h"
#import "AlfrescoSite.h"
#import "AlfrescoNode.h"
#import "AlfrescoDocument.h"
#import "AlfrescoComment.h"
#import "AlfrescoOAuthData.h"
#import "AlfrescoWorkflowProcessDefinition.h"
#import "AlfrescoWorkflowProcess.h"
#import "AlfrescoWorkflowTask.h"

@protocol AlfrescoSession;
/** The AlfrescoConstants used in the SDK.
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

/**---------------------------------------------------------------------------------------
 * @name SDK Version constants
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoSDKVersion;

/**---------------------------------------------------------------------------------------
 * @name Block definitions
 --------------------------------------------------------------------------------------- */
typedef void (^AlfrescoArrayCompletionBlock)(NSArray *array, NSError *error);
typedef void (^AlfrescoBOOLCompletionBlock)(BOOL succeeded, NSError *error);
typedef void (^AlfrescoNumberCompletionBlock)(NSNumber *count, NSError *error);
typedef void (^AlfrescoURLCompletionBlock)(NSURL *url, NSError *error);
typedef void (^AlfrescoDataCompletionBlock)(NSData *data, NSError *error);
typedef void (^AlfrescoFolderCompletionBlock)(AlfrescoFolder *folder, NSError *error);
typedef void (^AlfrescoNodeCompletionBlock)(AlfrescoNode *node, NSError *error);
typedef void (^AlfrescoDocumentCompletionBlock)(AlfrescoDocument *document, NSError *error);
typedef void (^AlfrescoPagingResultCompletionBlock)(AlfrescoPagingResult *pagingResult, NSError *error);
typedef void (^AlfrescoProgressBlock)(unsigned long long bytesTransferred, unsigned long long bytesTotal);
typedef void (^AlfrescoContentFileCompletionBlock)(AlfrescoContentFile *contentFile, NSError *error);
typedef void (^AlfrescoPermissionsCompletionBlock)(AlfrescoPermissions *permissions, NSError *error);
typedef void (^AlfrescoPersonCompletionBlock)(AlfrescoPerson *person, NSError *error);
typedef void (^AlfrescoSiteCompletionBlock)(AlfrescoSite *site, NSError *error);
typedef void (^AlfrescoSessionCompletionBlock)(id<AlfrescoSession> session, NSError *error);
typedef void (^AlfrescoCommentCompletionBlock)(AlfrescoComment *comment, NSError *error);
typedef void (^AlfrescoLikedCompletionBlock)(BOOL succeeded, BOOL isLiked, NSError *error);
typedef void (^AlfrescoOAuthCompletionBlock)(AlfrescoOAuthData * oauthData, NSError *error);
typedef void (^AlfrescoMemberCompletionBlock)(BOOL succeeded, BOOL isMember, NSError *error);
typedef void (^AlfrescoFavoritedCompletionBlock)(BOOL succeeded, BOOL isFavorited, NSError *error);
// workflow
typedef void (^AlfrescoProcessDefinitionCompletionBlock)(AlfrescoWorkflowProcessDefinition *processDefinition, NSError *error);
typedef void (^AlfrescoProcessCompletionBlock)(AlfrescoWorkflowProcess *process, NSError *error);
typedef void (^AlfrescoTaskCompletionBlock)(AlfrescoWorkflowTask *task, NSError *error);
typedef void (^AlfrescoDictionaryCompletionBlock)(NSDictionary *dictionary, NSError *error);


/**---------------------------------------------------------------------------------------
 * @name Session parameters
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoMetadataExtraction;
extern NSString * const kAlfrescoThumbnailCreation;

/**---------------------------------------------------------------------------------------
 * @name thumbnail constant (for OnPremise services)
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoThumbnailRendition;

/**---------------------------------------------------------------------------------------
 * @name sorting properties
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoSortByTitle;
extern NSString * const kAlfrescoSortByShortname;
extern NSString * const kAlfrescoSortByCreatedAt;
extern NSString * const kAlfrescoSortByModifiedAt;
extern NSString * const kAlfrescoSortByName;
extern NSString * const kAlfrescoSortByDescription;

/**---------------------------------------------------------------------------------------
 * @name capability constants
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoCapabilityLike;
extern NSString * const kAlfrescoCapabilityCommentsCount;

/**---------------------------------------------------------------------------------------
 * @name File Attribute Constants
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoFileSize;
extern NSString * const kAlfrescoFileLastModification;
extern NSString * const kAlfrescoIsFolder;

/**---------------------------------------------------------------------------------------
 * @name Custom Alfresco Network Provider
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoNetworkProvider;
extern NSString * const kAlfrescoCMISBindingURL;
extern NSString * const kAlfrescoAllowUntrustedSSLCertificate;

/**---------------------------------------------------------------------------------------
 * @name Person Profile Constants 
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoPersonPropertyFirstName;
extern NSString * const kAlfrescoPersonPropertyLastName;
extern NSString * const kAlfrescoPersonPropertyJobTitle;
extern NSString * const kAlfrescoPersonPropertyLocation;
extern NSString * const kAlfrescoPersonPropertyDescription;
extern NSString * const kAlfrescoPersonPropertyTelephoneNumber;
extern NSString * const kAlfrescoPersonPropertyMobileNumber;
extern NSString * const kAlfrescoPersonPropertyEmail;
extern NSString * const kAlfrescoPersonPropertySkypeId;
extern NSString * const kAlfrescoPersonPropertyInstantMessageId;
extern NSString * const kAlfrescoPersonPropertyGoogleId;
extern NSString * const kAlfrescoPersonPropertyStatus;
extern NSString * const kAlfrescoPersonPropertyStatusTime;
extern NSString * const kAlfrescoPersonPropertyCompanyName;
extern NSString * const kAlfrescoPersonPropertyCompanyAddressLine1;
extern NSString * const kAlfrescoPersonPropertyCompanyAddressLine2;
extern NSString * const kAlfrescoPersonPropertyCompanyAddressLine3;
extern NSString * const kAlfrescoPersonPropertyCompanyPostcode;
extern NSString * const kAlfrescoPersonPropertyCompanyTelephoneNumber;
extern NSString * const kAlfrescoPersonPropertyCompanyFaxNumber;
extern NSString * const kAlfrescoPersonPropertyCompanyEmail;

/**---------------------------------------------------------------------------------------
 * @name Workflow Constants
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoTaskComment;
extern NSString * const kAlfrescoTaskReviewOutcome;
extern NSString * const kAlfrescoTaskApprove;
extern NSString * const kAlfrescoTaskReject;
extern NSString * const kAlfrescoWorkflowProcessStateAny;
extern NSString * const kAlfrescoWorkflowProcessStateActive;
extern NSString * const kAlfrescoWorkflowProcessStateCompleted;

extern NSString * const kAlfrescoWorkflowProcessDescription;
extern NSString * const kAlfrescoWorkflowProcessPriority;
extern NSString * const kAlfrescoWorkflowProcessSendEmailNotification;
extern NSString * const kAlfrescoWorkflowProcessDueDate;
extern NSString * const kAlfrescoWorkflowProcessApprovalRate;

typedef NS_ENUM(NSInteger, AlfrescoWorkflowEngineType)
{
    AlfrescoWorkflowEngineTypeUnknown,
    AlfrescoWorkflowEngineTypeJBPM,
    AlfrescoWorkflowEngineTypeActiviti
};

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


/** Adds all required files to include the Alfresco SDK.
 
 Author: Tauseef Mughal (Alfresco)
 */

/**
 * Session
 */
#import "AlfrescoSession.h"
#import "AlfrescoCloudNetwork.h"
#import "AlfrescoCloudSession.h"
#import "AlfrescoRepositorySession.h"
#import "AlfrescoOAuthHelper.h"
#import "AlfrescoOAuthLoginDelegate.h"
#import "AlfrescoOAuthData.h"

#if TARGET_OS_IPHONE
#import "AlfrescoOAuthLoginViewController.h"
#endif

/**
 * Model
 */
#import "AlfrescoContentFile.h"
#import "AlfrescoContent.h"
#import "AlfrescoContentStream.h"
#import "AlfrescoSite.h"
#import "AlfrescoRepositoryInfo.h"
#import "AlfrescoRepositoryCapabilities.h"
#import "AlfrescoProperty.h"
#import "AlfrescoPerson.h"
#import "AlfrescoPermissions.h"
#import "AlfrescoPagingResult.h"
#import "AlfrescoNode.h"
#import "AlfrescoListingContext.h"
#import "AlfrescoKeywordSearchOptions.h"
#import "AlfrescoFolder.h"
#import "AlfrescoDocument.h"
#import "AlfrescoComment.h"
#import "AlfrescoActivityEntry.h"
#import "AlfrescoSite.h"
#import "AlfrescoTag.h"
#import "AlfrescoFileManager.h"
#import "AlfrescoCompany.h"
#import "AlfrescoWorkflowProcessDefinition.h"
#import "AlfrescoWorkflowProcess.h"
#import "AlfrescoWorkflowTask.h"
#import "AlfrescoContentStream.h"
#import "AlfrescoSearchLanguage.h"

/**
 * Services
 */
#import "AlfrescoVersionService.h"
#import "AlfrescoTaggingService.h"
#import "AlfrescoSiteService.h"
#import "AlfrescoSearchService.h"
#import "AlfrescoRatingService.h"
#import "AlfrescoPersonService.h"
#import "AlfrescoDocumentFolderService.h"
#import "AlfrescoCommentService.h"
#import "AlfrescoActivityStreamService.h"
#import "AlfrescoWorkflowServices.h"

/**
 * Utils
 */
#import "AlfrescoConstants.h"
#import "AlfrescoLog.h"
#import "AlfrescoRequest.h"
#import "AlfrescoErrors.h"
#import "AlfrescoNetworkProvider.h"

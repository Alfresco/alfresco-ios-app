/*
 ******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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

/**
 * These internal constants are available in the SDK, but not visible to the app.
 * As a result, we declare them here but not provide and let the runtime locate the appropiate values.
 */

// Alfresco SDK
extern NSString * const kAlfrescoJSONIdentifier;
extern NSString * const kAlfrescoJSONItems;
extern NSString * const kAlfrescoJSONEnable;
extern NSString * const kAlfrescoRepositoryEditionCommunity;
extern NSString * const kAlfrescoRepositoryEditionEnterprise;
extern NSString * const kAlfrescoRepositoryEditionCloud;
extern NSString * const kAlfrescoNodeAspects;
extern NSString * const kAlfrescoModelPropertyTitle;
extern NSString * const kAlfrescoModelPropertyDescription;

// This will be added to the AlfrescoErrors Enum
extern NSInteger const kAlfrescoErrorCodeConfigInitializationFailed;

// CMIS
extern NSString * const kCMISPropertyContentStreamLength;
extern NSString * const kCMISPropertyContentStreamMediaType;
extern NSString * const kCMISPropertyObjectId;
extern NSString * const kCMISPropertyName;
extern NSString * const kCMISPropertyObjectTypeId;
extern NSString * const kCMISPropertyCreatedBy;
extern NSString * const kCMISPropertyModifiedBy;
extern NSString * const kCMISPropertyCreationDate;
extern NSString * const kCMISPropertyModificationDate;
extern NSString * const kCMISPropertyObjectTypeIdValueDocument;
extern NSString * const kCMISPropertyObjectTypeId;

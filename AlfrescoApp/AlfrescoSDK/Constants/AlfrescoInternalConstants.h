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
#import "AlfrescoWorkflowInternalConstants.h"

extern NSString * const kAlfrescoClassVersion;

extern NSString * const kAlfrescoISO8601DateStringFormat;
extern NSString * const kAlfrescoCMISPropertyTypeInt;
extern NSString * const kAlfrescoCMISPropertyTypeBoolean;
extern NSString * const kAlfrescoCMISPropertyTypeDatetime;
extern NSString * const kAlfrescoCMISPropertyTypeDecimal;
extern NSString * const kAlfrescoCMISPropertyTypeId;
extern NSString * const kAlfrescoCMISSessionMode;

extern NSString * const kAlfrescoPropertyName;
extern NSString * const kAlfrescoPropertyTitle;
extern NSString * const kAlfrescoPropertyDescription;
extern NSString * const kAlfrescoTypeContent;
extern NSString * const kAlfrescoTypeFolder;

extern NSString * const kAlfrescoRepositoryName;
extern NSString * const kAlfrescoRepositoryCommunity;
extern NSString * const kAlfrescoRepositoryEnterprise;
extern NSString * const kAlfrescoRepositoryEdition;
extern NSString * const kAlfrescoCloudEdition;
extern NSString * const kAlfrescoRepositoryIdentifier;
extern NSString * const kAlfrescoRepositorySummary;
extern NSString * const kAlfrescoRepositoryVersion;
extern NSString * const kAlfrescoRepositoryMajorVersion;
extern NSString * const kAlfrescoRepositoryMinorVersion;
extern NSString * const kAlfrescoRepositoryMaintenanceVersion;
extern NSString * const kAlfrescoRepositoryBuildNumber;
extern NSString * const kAlfrescoRepositoryCapabilities;

extern NSString * const kAlfrescoSiteId;
extern NSString * const kAlfrescoSiteGUID;
extern NSString * const kAlfrescoInviteId;
extern NSString * const kAlfrescoNodeRef;
extern NSString * const kAlfrescoPersonId;
extern NSString * const kAlfrescoCommentId;
extern NSString * const kAlfrescoRenditionId;
extern NSString * const kAlfrescoOnNodeRefURL;
extern NSString * const kAlfrescoNode;
extern NSString * const kAlfrescoDefaultMimeType;
extern NSString * const kAlfrescoAspects;
extern NSString * const kAlfrescoAppliedAspects;
extern NSString * const kAlfrescoAspectProperties;
extern NSString * const kAlfrescoAspectPropertyDefinitionId;
extern NSString * const kAlfrescoPagingRequest;
extern NSString * const kAlfrescoSkipCountRequest;
extern NSString * const kAlfrescoMaxItemsRequest;
extern NSString * const kAlfrescoClientID;
extern NSString * const kAlfrescoClientSecret;
extern NSString * const kAlfrescoCode;
extern NSString * const kAlfrescoRedirectURI;
extern NSString * const kAlfrescoRefreshID;
extern NSString * const kAlfrescoMe;
extern NSString * const kAlfrescoModerated;
extern NSString * const kAlfrescoSiteConsumer;
extern NSString * const kAlfrescoMaxItems;
extern NSString * const kAlfrescoSkipCount;
extern NSString * const kAlfrescoSearchFilter;

extern NSString * const kAlfrescoSessionKeyCmisSession;
extern NSString * const kAlfrescoSessionCloudURL;
extern NSString * const kAlfrescoSessionCloudBasicAuth;
extern NSString * const kAlfrescoSessionUsername;
extern NSString * const kAlfrescoSessionPassword;
extern NSString * const kAlfrescoSessionInternalCache;

extern NSString * const kAlfrescoSiteIsFavorite;
extern NSString * const kAlfrescoSiteIsMember;
extern NSString * const kAlfrescoSiteIsPendingMember;

extern NSString * const kAlfrescoAuthenticationProviderObjectKey;

extern NSString *const kAlfrescoJSONAccessToken;
extern NSString *const kAlfrescoJSONRefreshToken;
extern NSString *const kAlfrescoJSONTokenType;
extern NSString *const kAlfrescoJSONExpiresIn;
extern NSString *const kAlfrescoJSONScope;
extern NSString *const kAlfrescoJSONError;
extern NSString *const kAlfrescoJSONErrorDescription;
extern NSString *const kAlfrescoOAuthClientID;
extern NSString *const kAlfrescoOAuthClientSecret;
extern NSString *const kAlfrescoOAuthGrantType;
extern NSString *const kAlfrescoOAuthRedirectURI;
extern NSString *const kAlfrescoOAuthCode;
extern NSString *const kAlfrescoOAuthAuthorize;
extern NSString *const kAlfrescoOAuthToken;
extern NSString *const kAlfrescoOAuthScope;
extern NSString *const kAlfrescoOAuthResponseType;
extern NSString *const kAlfrescoOAuthGrantTypeRefresh;
extern NSString *const kAlfrescoOAuthRefreshToken;

extern NSString * const kAlfrescoOnPremiseAPIPath;
extern NSString * const kAlfrescoOnPremiseCMISPath;
extern NSString * const kAlfrescoOnPremise4_xCMISPath;
extern NSString * const kAlfrescoOnPremiseActivityAPI;
extern NSString * const kAlfrescoOnPremiseActivityForSiteAPI;
extern NSString * const kAlfrescoOnPremiseRatingsAPI;
extern NSString * const kAlfrescoOnPremiseRatingsLikingSchemeAPI;
extern NSString * const kAlfrescoOnPremiseRatingsCount;
extern NSString * const kAlfrescoOnPremiseLikesSchemeRatings;
extern NSString * const kAlfrescoOnNodeRefURL;
extern NSString * const kAlfrescoOnPremiseSiteAPI;
extern NSString * const kAlfrescoOnPremiseSiteForPersonAPI;
extern NSString * const kAlfrescoOnPremiseFavoriteSiteForPersonAPI;
extern NSString * const kAlfrescoOnPremiseSitesShortnameAPI;
extern NSString * const kAlfrescoOnPremiseSiteDoclibAPI;
extern NSString * const kAlfrescoOnPremiseFavoriteSites;
extern NSString * const kAlfrescoOnPremiseCommentsAPI;
extern NSString * const kAlfrescoOnPremiseCommentForNodeAPI;
extern NSString * const kAlfrescoOnPremiseTagsAPI;
extern NSString * const kAlfrescoOnPremiseTagsForNodeAPI;
extern NSString * const kAlfrescoOnPremisePersonAPI;
extern NSString * const kAlfrescoOnPremisePersonSearchAPI;
extern NSString * const kAlfrescoOnPremiseAvatarForPersonAPI;
extern NSString * const kAlfrescoOnPremiseMetadataExtractionAPI;
extern NSString * const kAlfrescoOnPremiseThumbnailCreationAPI;
extern NSString * const kAlfrescoOnPremiseThumbnailRenditionAPI;
extern NSString * const kAlfrescoOnPremiseAddOrRemoveFavoriteSiteAPI;
extern NSString * const kAlfrescoOnPremiseJoinPublicSiteAPI;
extern NSString * const kAlfrescoOnPremiseJoinModeratedSiteAPI;
extern NSString * const kAlfrescoOnPremisePendingJoinRequestsAPI;
extern NSString * const kAlfrescoOnPremiseCancelJoinRequestsAPI;
extern NSString * const kAlfrescoOnPremiseLeaveSiteAPI;
extern NSString * const kAlfrescoOnPremiseSiteMembershipFilter;
extern NSString * const kAlfrescoOnPremiseFavoriteDocumentsAPI;
extern NSString * const kAlfrescoOnPremiseFavoriteFoldersAPI;
extern NSString * const kAlfrescoOnPremiseFavoriteDocuments;
extern NSString * const kAlfrescoOnPremiseFavoriteFolders;


extern NSString * const kAlfrescoCloudURL;
extern NSString * const kAlfrescoCloudBindingService;
extern NSString * const kAlfrescoCloudPrecursor;
extern NSString * const kAlfrescoCloudAPIPath;
extern NSString * const kAlfrescoCloudCMISPath;
extern NSString * const kAlfrescoHomeNetworkType;
extern NSString * const kAlfrescoDocumentLibrary;
extern NSString * const kAlfrescoCloudSiteAPI;
extern NSString * const kAlfrescoCloudSiteForPersonAPI;
extern NSString * const kAlfrescoCloudFavoriteSiteForPersonAPI;
extern NSString * const kAlfrescoCloudSiteForShortnameAPI;
extern NSString * const kAlfrescoCloudSiteContainersAPI;
extern NSString * const kAlfrescoCloudActivitiesAPI;
extern NSString * const kAlfrescoCloudActivitiesForSiteAPI;
extern NSString * const kAlfrescoCloudRatingsAPI;
extern NSString * const kAlfrescoCloudLikesRatingSchemeAPI;
extern NSString * const kAlfrescoCloudCommentsAPI;
extern NSString * const kAlfrescoCloudCommentForNodeAPI;
extern NSString * const kAlfrescoCloudTagsAPI;
extern NSString * const kAlfrescoCloudTagsForNodeAPI;
extern NSString * const kAlfrescoCloudPersonAPI;
extern NSString * const kAlfrescoCloudPersonSearchAPI;
extern NSString * const kAlfrescoCloudDefaultRedirectURI;
extern NSString * const kAlfrescoCloudAddFavoriteSiteAPI;
extern NSString * const kAlfrescoCloudRemoveFavoriteSiteAPI;
extern NSString * const kAlfrescoCloudJoinSiteAPI;
extern NSString * const kAlfrescoCloudCancelJoinRequestsAPI;
extern NSString * const kAlfrescoCloudLeaveSiteAPI;
extern NSString * const kAlfrescoCloudPagingAPIParameters;
extern NSString * const kAlfrescoCloudSiteMembersAPI;
extern NSString * const kAlfrescoCloudFavoriteDocumentsAPI;
extern NSString * const kAlfrescoCloudFavoriteFoldersAPI;
extern NSString * const kAlfrescoCloudFavoritesAllAPI;
extern NSString * const kAlfrescoCloudFavorite;
extern NSString * const kAlfrescoCloudAddFavoriteAPI;

extern NSString * const kAlfrescoCloudInternalAPIPath;

extern NSString * const kAlfrescoCloudJSONList;
extern NSString * const kAlfrescoCloudJSONPagination;
extern NSString * const kAlfrescoCloudJSONCount;
extern NSString * const kAlfrescoCloudJSONHasMoreItems;
extern NSString * const kAlfrescoCloudJSONTotalItems;
extern NSString * const kAlfrescoCloudJSONSkipCount;
extern NSString * const kAlfrescoCloudJSONMaxItems;
extern NSString * const kAlfrescoCloudJSONEntries;
extern NSString * const kAlfrescoCloudJSONEntry;
extern NSString * const kAlfrescoJSONIdentifier;
extern NSString * const kAlfrescoJSONStatusCode;
extern NSString * const kAlfrescoJSONActivityPostDate;
extern NSString * const kAlfrescoJSONActivityPostUserID;
extern NSString * const kAlfrescoJSONActivityPostPersonID;
extern NSString * const kAlfrescoJSONActivitySiteNetwork;
extern NSString * const kAlfrescoJSONActivityType;
extern NSString * const kAlfrescoJSONActivitySummary;
extern NSString * const kAlfrescoJSONRating;
extern NSString * const kAlfrescoJSONRatingScheme;
extern NSString * const kAlfrescoJSONLikesRatingScheme;
extern NSString * const kAlfrescoJSONDescription;
extern NSString * const kAlfrescoJSONTitle;
extern NSString * const kAlfrescoJSONShortname;
extern NSString * const kAlfrescoJSONVisibility;
extern NSString * const kAlfrescoJSONVisibilityPUBLIC;
extern NSString * const kAlfrescoJSONVisibilityPRIVATE;
extern NSString * const kAlfrescoJSONVisibilityMODERATED;
extern NSString * const kAlfrescoJSONContainers;
extern NSString * const kAlfrescoJSONNodeRef;
extern NSString * const kAlfrescoJSONSiteID;
extern NSString * const kAlfrescoJSONLikes;
extern NSString * const kAlfrescoJSONMyRating;
extern NSString * const kAlfrescoJSONAggregate;
extern NSString * const kAlfrescoJSONNumberOfRatings;
extern NSString * const kAlfrescoJSONHomeNetwork;
extern NSString * const kAlfrescoJSONIsEnabled;
extern NSString * const kAlfrescoJSONNetwork;
extern NSString * const kAlfrescoJSONPaidNetwork;
extern NSString * const kAlfrescoJSONCreationTime;
extern NSString * const kAlfrescoJSONSubscriptionLevel;
extern NSString * const kAlfrescoJSONName;
extern NSString * const kAlfrescoJSONItems;
extern NSString * const kAlfrescoJSONItem;
extern NSString * const kAlfrescoJSONCreatedOn;
extern NSString * const kAlfrescoJSONCreatedOnISO;
extern NSString * const kAlfrescoJSONAuthorUserName;
extern NSString * const kAlfrescoJSONAuthor;
extern NSString * const kAlfrescoJSONUsername;
extern NSString * const kAlfrescoJSONModifiedOn;
extern NSString * const kAlfrescoJSONModifiedOnISO;
extern NSString * const kAlfrescoJSONContent;
extern NSString * const kAlfrescoJSONIsUpdated;
extern NSString * const kAlfrescoJSONPermissionsEdit;
extern NSString * const kAlfrescoJSONPermissionsDelete;
extern NSString * const kAlfrescoJSONPermissions;
extern NSString * const kAlfrescoJSONEdit;
extern NSString * const kAlfrescoJSONDelete;
extern NSString * const kAlfrescoJSONCreatedAt;
extern NSString * const kAlfrescoJSONCreatedBy;
extern NSString * const kAlfrescoJSONCreator;
extern NSString * const kAlfrescoJSONAvatar;
extern NSString * const kAlfrescoJSONAuthority;
extern NSString * const kAlfrescoJSONModifedAt;
extern NSString * const kAlfrescoJSONEdited;
extern NSString * const kAlfrescoJSONCanEdit;
extern NSString * const kAlfrescoJSONCanDelete;
extern NSString * const kAlfrescoJSONEnabled;
extern NSString * const kAlfrescoJSONTag;
extern NSString * const kAlfrescoJSONUserName;
extern NSString * const kAlfrescoJSONFirstName;
extern NSString * const kAlfrescoJSONFullName;
extern NSString * const kAlfrescoJSONLastName;
extern NSString * const kAlfrescoJSONActionedUponNode;
extern NSString * const kAlfrescoJSONExtractMetadata;
extern NSString * const kAlfrescoJSONActionDefinitionName;
extern NSString * const kAlfrescoJSONThumbnailName;
extern NSString * const kAlfrescoJSONSite;
extern NSString * const kAlfrescoJSONPostedAt;
extern NSString * const kAlfrescoJSONAvatarId;
extern NSString * const kAlfrescoJSONJobTitle;
extern NSString * const kAlfrescoCloudJSONJobTitle;
extern NSString * const kAlfrescoJSONLocation;
extern NSString * const kAlfrescoJSONTelephoneNumber;
extern NSString * const kAlfrescoJSONMobileNumber;
extern NSString * const kAlfrescoJSONSkypeId;
extern NSString * const kAlfrescoJSONGoogleId;
extern NSString * const kAlfrescoJSONInstantMessageId;
extern NSString * const kAlfrescoJSONSkype;
extern NSString * const kAlfrescoJSONGoogle;
extern NSString * const kAlfrescoJSONInstantMessage;
extern NSString * const kAlfrescoJSONStatus;
extern NSString * const kAlfrescoJSONStatusTime;
extern NSString * const kAlfrescoJSONEmail;
extern NSString * const kAlfrescoJSONCompany;
extern NSString * const kAlfrescoJSONCompanyAddressLine1;
extern NSString * const kAlfrescoJSONCompanyAddressLine2;
extern NSString * const kAlfrescoJSONCompanyAddressLine3;
extern NSString * const kAlfrescoJSONCompanyFullAddress;
extern NSString * const kAlfrescoJSONCompanyPostcode;
extern NSString * const kAlfrescoJSONCompanyFaxNumber;
extern NSString * const kAlfrescoJSONCompanyName;
extern NSString * const kAlfrescoJSONCompanyTelephone;
extern NSString * const kAlfrescoJSONCompanyEmail;
extern NSString * const kAlfrescoJSONAddressLine1;
extern NSString * const kAlfrescoJSONPostcode;
extern NSString * const kAlfrescoJSONFaxNumber;
extern NSString * const kAlfrescoJSONPersonDescription;
extern NSString * const kAlfrescoJSONAddressLine1;
extern NSString * const kAlfrescoJSONAddressLine2;
extern NSString * const kAlfrescoJSONAddressLine3;


extern NSString * const kAlfrescoJSONOrg;
extern NSString * const kAlfrescoJSONAlfresco;
extern NSString * const kAlfrescoJSONShare;
extern NSString * const kAlfrescoJSONSites;
extern NSString * const kAlfrescoJSONFavorites;
extern NSString * const kAlfrescoJSONGUID;
extern NSString * const kAlfrescoJSONTarget;
extern NSString * const kAlfrescoJSONPerson;
extern NSString * const kAlfrescoJSONPeople;
extern NSString * const kAlfrescoJSONRole;
extern NSString * const kAlfrescoJSONInvitationType;
extern NSString * const kAlfrescoJSONInviteeUsername;
extern NSString * const kAlfrescoJSONInviteeComments;
extern NSString * const kAlfrescoJSONInviteeRolename;
extern NSString * const kAlfrescoJSONInviteId;
extern NSString * const kAlfrescoJSONData;
extern NSString * const kAlfrescoJSONResourceName;
extern NSString * const kAlfrescoJSONMessage;
extern NSString * const kAlfrescoJSONFile;
extern NSString * const kAlfrescoJSONFolder;

extern NSString * const kAlfrescoNodeAspects;
extern NSString * const kAlfrescoNodeProperties;
extern NSString * const kAlfrescoPropertyType;
extern NSString * const kAlfrescoPropertyValue;
extern NSString * const kAlfrescoPropertyIsMultiValued;

extern NSString * const kAlfrescoHTTPDelete;
extern NSString * const kAlfrescoHTTPGet;
extern NSString * const kAlfrescoHTTPPOST;
extern NSString * const kAlfrescoHTTPPut;

extern NSString * const kAlfrescoFileManagerClass;
extern NSString * const kAlfrescoCMISNetworkProvider;
extern NSString * const kAlfrescoPropertyTypeFolder;
extern NSString * const kAlfrescoPropertyTypeDocument;
extern NSString * const kAlfrescoPropertyAspect;

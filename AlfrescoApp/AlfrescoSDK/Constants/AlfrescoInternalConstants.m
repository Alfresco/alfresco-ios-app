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

#import "AlfrescoInternalConstants.h"


/**
 Class Version constants
 */
NSString * const kAlfrescoClassVersion = @"alfresco.classVersion";

NSString * const kAlfrescoISO8601DateStringFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZZZ";
/**
 CMIS constants
 */
NSString * const kAlfrescoCMISPropertyTypeInt = @"int";
NSString * const kAlfrescoCMISPropertyTypeBoolean = @"boolean";
NSString * const kAlfrescoCMISPropertyTypeDatetime = @"datetime";
NSString * const kAlfrescoCMISPropertyTypeDecimal = @"decimal";
NSString * const kAlfrescoCMISPropertyTypeId = @"id";
NSString * const kAlfrescoCMISSessionMode = @"alfresco";

/**
 Content Model constants
 */
NSString * const kAlfrescoPropertyName = @"cm:name";
NSString * const kAlfrescoPropertyTitle = @"cm:title";
NSString * const kAlfrescoPropertyDescription = @"cm:description";
NSString * const kAlfrescoTypeContent = @"cm:content";
NSString * const kAlfrescoTypeFolder = @"cm:folder";

/**
 Property name constants
 */
NSString * const kAlfrescoRepositoryName = @"name";
NSString * const kAlfrescoRepositoryCommunity = @"Community";
NSString * const kAlfrescoRepositoryEnterprise = @"Enterprise";
NSString * const kAlfrescoRepositoryEdition = @"edition";
NSString * const kAlfrescoCloudEdition = @"Alfresco in the Cloud";
NSString * const kAlfrescoRepositoryIdentifier = @"identifier";
NSString * const kAlfrescoRepositorySummary = @"summary";
NSString * const kAlfrescoRepositoryVersion = @"version";
NSString * const kAlfrescoRepositoryMajorVersion = @"majorVersion";
NSString * const kAlfrescoRepositoryMinorVersion = @"minorVersion";
NSString * const kAlfrescoRepositoryMaintenanceVersion = @"maintenanceVersion";
NSString * const kAlfrescoRepositoryBuildNumber = @"buildNumber";
NSString * const kAlfrescoRepositoryCapabilities = @"capabilities";

/**
 Parametrised strings to be used in API
 */
NSString * const kAlfrescoSiteId = @"{siteID}";
NSString * const kAlfrescoSiteGUID = @"{siteGUID}";
NSString * const kAlfrescoInviteId = @"{inviteID}";
NSString * const kAlfrescoNodeRef = @"{nodeRef}";
NSString * const kAlfrescoPersonId = @"{personID}";
NSString * const kAlfrescoCommentId = @"{commentID}";
NSString * const kAlfrescoRenditionId = @"{renditionID}";
NSString * const kAlfrescoSkipCountRequest = @"{skipCount}";
NSString * const kAlfrescoMaxItemsRequest = @"{maxItems}";
NSString * const kAlfrescoOnNodeRefURL = @"workspace://SpacesStore/{nodeRef}";
NSString * const kAlfrescoNode = @"node";
NSString * const kAlfrescoDefaultMimeType = @"application/octet-stream";
NSString * const kAlfrescoAspects = @"aspects";
NSString * const kAlfrescoAppliedAspects = @"appliedAspects";
NSString * const kAlfrescoAspectProperties = @"properties";
NSString * const kAlfrescoAspectPropertyDefinitionId = @"propertyDefinitionId";
NSString * const kAlfrescoPagingRequest = @"?skipCount={skipCount}&maxItems={maxItems}";
NSString * const kAlfrescoClientID = @"{clientID}";
NSString * const kAlfrescoClientSecret = @"{clientSecret}";
NSString * const kAlfrescoCode = @"{code}";
NSString * const kAlfrescoRedirectURI = @"{redirectURI}";
NSString * const kAlfrescoRefreshID = @"{refreshID}";
NSString * const kAlfrescoMe = @"-me-";
NSString * const kAlfrescoModerated = @"MODERATED";
NSString * const kAlfrescoSiteConsumer = @"SiteConsumer";
NSString * const kAlfrescoMaxItems = @"{maxItems}";
NSString * const kAlfrescoSkipCount = @"{skipCount}";
NSString * const kAlfrescoSearchFilter = @"{filter}";

/**
 Session data key constants
 */
NSString * const kAlfrescoSessionKeyCmisSession = @"alfresco_session_key_cmis_session";
NSString * const kAlfrescoSessionCloudURL = @"org.alfresco.mobile.internal.session.cloud.url";
NSString * const kAlfrescoSessionCloudBasicAuth = @"org.alfresco.mobile.internal.session.cloud.basic";
NSString * const kAlfrescoSessionUsername = @"org.alfresco.mobile.internal.session.username";
NSString * const kAlfrescoSessionPassword = @"org.alfresco.mobile.internal.session.password";
NSString * const kAlfrescoSessionInternalCache = @"org.alfresco.mobile.internal.cache.";

NSString * const kAlfrescoSiteIsFavorite = @"isFavorite";
NSString * const kAlfrescoSiteIsMember = @"isMember";
NSString * const kAlfrescoSiteIsPendingMember = @"isPendingMember";

/**
 Associated object key constants
 */
NSString * const kAlfrescoAuthenticationProviderObjectKey = @"AuthenticationProviderObjectKey";

/**
 OAuth Constants
 */
NSString *const kAlfrescoJSONAccessToken = @"access_token";
NSString *const kAlfrescoJSONRefreshToken = @"refresh_token";
NSString *const kAlfrescoJSONTokenType = @"token_type";
NSString *const kAlfrescoJSONExpiresIn = @"expires_in";
NSString *const kAlfrescoJSONScope = @"scope";
NSString *const kAlfrescoJSONError = @"error";
NSString *const kAlfrescoJSONErrorDescription = @"error_description";
NSString *const kAlfrescoOAuthClientID = @"client_id={clientID}";
NSString *const kAlfrescoOAuthClientSecret = @"client_secret={clientSecret}";
NSString *const kAlfrescoOAuthGrantType = @"grant_type=authorization_code";
NSString *const kAlfrescoOAuthRedirectURI = @"redirect_uri={redirectURI}";
NSString *const kAlfrescoOAuthCode = @"code={code}";
NSString *const kAlfrescoOAuthAuthorize = @"/auth/oauth/versions/2/authorize";
NSString *const kAlfrescoOAuthToken = @"/auth/oauth/versions/2/token";
NSString *const kAlfrescoOAuthScope = @"scope=pub_api";
NSString *const kAlfrescoOAuthResponseType = @"response_type=code";
NSString *const kAlfrescoOAuthGrantTypeRefresh = @"grant_type=refresh_token";
NSString *const kAlfrescoOAuthRefreshToken = @"refresh_token={refreshID}";


/**
 On Premise constants      
 */
NSString * const kAlfrescoOnPremiseAPIPath = @"/service/api/";
NSString * const kAlfrescoOnPremiseCMISPath = @"/service/cmis";
NSString * const kAlfrescoOnPremise4_xCMISPath = @"/cmisatom";
NSString * const kAlfrescoOnPremiseActivityAPI = @"activities/feed/user?format=json";
NSString * const kAlfrescoOnPremiseActivityForSiteAPI = @"activities/feed/site/{siteID}?format=json";
NSString * const kAlfrescoOnPremiseRatingsAPI = @"node/{nodeRef}/ratings";
NSString * const kAlfrescoOnPremiseRatingsLikingSchemeAPI = @"node/{nodeRef}/ratings/likesRatingScheme";
NSString * const kAlfrescoOnPremiseRatingsCount = @"data.nodeStatistics.likesRatingScheme.ratingsCount";
NSString * const kAlfrescoOnPremiseLikesSchemeRatings = @"data.ratings.likesRatingScheme.rating";
NSString * const kAlfrescoOnPremiseSiteAPI = @"sites?format=json";
NSString * const kAlfrescoOnPremiseSiteForPersonAPI = @"people/{personID}/sites";
NSString * const kAlfrescoOnPremiseFavoriteSiteForPersonAPI = @"people/{personID}/preferences?pf=org.alfresco.share.sites";
NSString * const kAlfrescoOnPremiseSitesShortnameAPI = @"sites/{siteID}";
NSString * const kAlfrescoOnPremiseSiteDoclibAPI = @"service/slingshot/doclib/containers/{siteID}";
NSString * const kAlfrescoOnPremiseFavoriteSites = @"org.alfresco.share.sites.favourites";
NSString * const kAlfrescoOnPremiseCommentsAPI = @"node/{nodeRef}/comments";
NSString * const kAlfrescoOnPremiseCommentForNodeAPI = @"comment/node/{commentID}";
NSString * const kAlfrescoOnPremiseTagsAPI = @"tags/workspace/SpacesStore";
NSString * const kAlfrescoOnPremiseTagsForNodeAPI = @"node/{nodeRef}/tags";
NSString * const kAlfrescoOnPremisePersonAPI = @"people/{personID}";
NSString * const kAlfrescoOnPremisePersonSearchAPI = @"people?filter={filter}";
NSString * const kAlfrescoOnPremiseAvatarForPersonAPI = @"/service/slingshot/profile/avatar/{personID}";
NSString * const kAlfrescoOnPremiseMetadataExtractionAPI = @"/service/api/actionQueue";
NSString * const kAlfrescoOnPremiseThumbnailCreationAPI = @"/node/{nodeRef}/content/thumbnails?as=true";
NSString * const kAlfrescoOnPremiseThumbnailRenditionAPI = @"node/{nodeRef}/content/thumbnails/{renditionID}";

NSString * const kAlfrescoOnPremiseAddOrRemoveFavoriteSiteAPI = @"people/{personID}/preferences";
NSString * const kAlfrescoOnPremiseJoinPublicSiteAPI = @"sites/{siteID}/memberships";
NSString * const kAlfrescoOnPremiseJoinModeratedSiteAPI = @"sites/{siteID}/invitations";
NSString * const kAlfrescoOnPremisePendingJoinRequestsAPI = @"invitations?inviteeUserName={personID}";
NSString * const kAlfrescoOnPremiseCancelJoinRequestsAPI = @"sites/{siteID}/invitations/{inviteID}";
NSString * const kAlfrescoOnPremiseLeaveSiteAPI = @"sites/{siteID}/memberships/{personID}";
NSString * const kAlfrescoOnPremiseSiteMembershipFilter = @"?nf={filter}&authorityType=USER";

NSString * const kAlfrescoOnPremiseFavoriteDocuments = @"org.alfresco.share.documents.favourites";
NSString * const kAlfrescoOnPremiseFavoriteFolders = @"org.alfresco.share.folders.favourites";
NSString * const kAlfrescoOnPremiseFavoriteDocumentsAPI = @"/people/{personID}/preferences?pf=org.alfresco.share.documents.favourites";
NSString * const kAlfrescoOnPremiseFavoriteFoldersAPI = @"/people/{personID}/preferences?pf=org.alfresco.share.folders.favourites";
/**
 Cloud constants     
 */
NSString * const kAlfrescoCloudURL = @"https://api.alfresco.com";
NSString * const kAlfrescoCloudBindingService = @"/alfresco/service";
NSString * const kAlfrescoCloudPrecursor = @"/alfresco/a";
NSString * const kAlfrescoCloudCMISPath = @"/public/cmis/versions/1/atom";
NSString * const kAlfrescoCloudAPIPath  = @"/public/alfresco/versions/1/";
NSString * const kAlfrescoDocumentLibrary =@"documentLibrary";
NSString * const kAlfrescoHomeNetworkType = @"homeNetwork";
NSString * const kAlfrescoCloudSiteAPI = @"sites";
NSString * const kAlfrescoCloudSiteForPersonAPI = @"people/{personID}/sites";
NSString * const kAlfrescoCloudFavoriteSiteForPersonAPI = @"people/{personID}/favorite-sites";
NSString * const kAlfrescoCloudSiteForShortnameAPI = @"sites/{siteID}";
NSString * const kAlfrescoCloudSiteContainersAPI = @"sites/{siteID}/containers";
NSString * const kAlfrescoCloudActivitiesAPI = @"people/{personID}/activities";
NSString * const kAlfrescoCloudActivitiesForSiteAPI = @"people/{personID}/activities?siteId={siteID}";
NSString * const kAlfrescoCloudRatingsAPI = @"nodes/{nodeRef}/ratings";
NSString * const kAlfrescoCloudLikesRatingSchemeAPI = @"node/{nodeRef}/ratings/likesRatingScheme";
NSString * const kAlfrescoCloudCommentsAPI = @"nodes/{nodeRef}/comments";
NSString * const kAlfrescoCloudCommentForNodeAPI = @"nodes/{nodeRef}/comments/{commentID}";
NSString * const kAlfrescoCloudTagsAPI = @"tags";
NSString * const kAlfrescoCloudTagsForNodeAPI = @"nodes/{nodeRef}/tags";
NSString * const kAlfrescoCloudPersonAPI = @"people/{personID}";
NSString * const kAlfrescoCloudPersonSearchAPI = @"people?filter={filter}";
NSString * const kAlfrescoCloudDefaultRedirectURI = @"http://www.alfresco.com/mobile-auth-callback.html";

NSString * const kAlfrescoCloudAddFavoriteSiteAPI = @"people/-me-/favorites";
NSString * const kAlfrescoCloudRemoveFavoriteSiteAPI = @"people/-me-/favorites/{siteGUID}";
NSString * const kAlfrescoCloudJoinSiteAPI = @"people/-me-/site-membership-requests";
NSString * const kAlfrescoCloudCancelJoinRequestsAPI = @"people/-me-/site-membership-requests/{siteID}";
NSString * const kAlfrescoCloudLeaveSiteAPI = @"sites/{siteID}/members/{personID}";
NSString * const kAlfrescoCloudPagingAPIParameters = @"maxItems={maxItems}&skipCount={skipCount}";
NSString * const kAlfrescoCloudSiteMembersAPI = @"sites/{siteID}/members";

NSString * const kAlfrescoCloudFavoriteDocumentsAPI = @"people/{personID}/favorites?where=(EXISTS(target/file))";
NSString * const kAlfrescoCloudFavoriteFoldersAPI = @"people/{personID}/favorites?where=(EXISTS(target/folder))";
NSString * const kAlfrescoCloudFavoritesAllAPI = @"people/{personID}/favorites?where=(EXISTS(target/file) OR EXISTS(target/folder))";
NSString * const kAlfrescoCloudFavorite = @"people/{personID}/favorites/{nodeRef}";
NSString * const kAlfrescoCloudAddFavoriteAPI = @"people/-me-/favorites";
/**
 Cloud Internals
 */
NSString * const kAlfrescoCloudInternalAPIPath = @"api/";

/**
 JSON Constants
 */
NSString * const kAlfrescoCloudJSONList = @"list";
NSString * const kAlfrescoCloudJSONPagination = @"pagination";
NSString * const kAlfrescoCloudJSONCount = @"count";
NSString * const kAlfrescoCloudJSONHasMoreItems = @"hasMoreItems";
NSString * const kAlfrescoCloudJSONTotalItems = @"totalItems";
NSString * const kAlfrescoCloudJSONSkipCount = @"skipCount";
NSString * const kAlfrescoCloudJSONMaxItems = @"maxItems";
NSString * const kAlfrescoCloudJSONEntries = @"entries";
NSString * const kAlfrescoCloudJSONEntry = @"entry";
NSString * const kAlfrescoJSONIdentifier = @"id";
NSString * const kAlfrescoJSONStatusCode = @"status.code";
NSString * const kAlfrescoJSONActivityPostDate = @"postDate";
NSString * const kAlfrescoJSONActivityPostUserID = @"postUserId";
NSString * const kAlfrescoJSONActivityPostPersonID = @"postPersonId";
NSString * const kAlfrescoJSONActivitySiteNetwork = @"siteNetwork";
NSString * const kAlfrescoJSONActivityType = @"activityType";
NSString * const kAlfrescoJSONActivitySummary = @"activitySummary";
NSString * const kAlfrescoJSONRating = @"rating";
NSString * const kAlfrescoJSONRatingScheme = @"ratingScheme";
NSString * const kAlfrescoJSONLikesRatingScheme = @"likesRatingScheme";
NSString * const kAlfrescoJSONDescription = @"description";
NSString * const kAlfrescoJSONTitle = @"title";
NSString * const kAlfrescoJSONShortname = @"shortName";
NSString * const kAlfrescoJSONVisibility = @"visibility";
NSString * const kAlfrescoJSONVisibilityPUBLIC = @"PUBLIC";
NSString * const kAlfrescoJSONVisibilityPRIVATE = @"PRIVATE";
NSString * const kAlfrescoJSONVisibilityMODERATED = @"MODERATED";
NSString * const kAlfrescoJSONContainers = @"containers";
NSString * const kAlfrescoJSONNodeRef = @"nodeRef";
NSString * const kAlfrescoJSONSiteID = @"siteId";
NSString * const kAlfrescoJSONLikes = @"likes";
NSString * const kAlfrescoJSONMyRating = @"myRating";
NSString * const kAlfrescoJSONAggregate = @"aggregate";
NSString * const kAlfrescoJSONNumberOfRatings = @"numberOfRatings";
NSString * const kAlfrescoJSONHomeNetwork = @"homeNetwork";
NSString * const kAlfrescoJSONIsEnabled = @"isEnabled";
NSString * const kAlfrescoJSONNetwork = @"network";
NSString * const kAlfrescoJSONPaidNetwork = @"paidNetwork";
NSString * const kAlfrescoJSONCreationTime = @"creationDate";
NSString * const kAlfrescoJSONSubscriptionLevel = @"subscriptionLevel";
NSString * const kAlfrescoJSONName = @"name";
NSString * const kAlfrescoJSONItems = @"items";
NSString * const kAlfrescoJSONItem = @"item";
NSString * const kAlfrescoJSONAuthorUserName = @"author.username";
NSString * const kAlfrescoJSONAuthor = @"author";
NSString * const kAlfrescoJSONUsername = @"username";
NSString * const kAlfrescoJSONCreatedOn = @"createdOn";
NSString * const kAlfrescoJSONCreatedOnISO = @"createdOnISO";
NSString * const kAlfrescoJSONModifiedOn = @"modifiedOn";
NSString * const kAlfrescoJSONModifiedOnISO = @"modifiedOnISO";
NSString * const kAlfrescoJSONContent = @"content";
NSString * const kAlfrescoJSONIsUpdated = @"isUpdated";
NSString * const kAlfrescoJSONPermissionsEdit = @"permissions.edit";
NSString * const kAlfrescoJSONPermissionsDelete = @"permissions.delete";
NSString * const kAlfrescoJSONPermissions = @"permissions";
NSString * const kAlfrescoJSONEdit = @"edit";
NSString * const kAlfrescoJSONDelete = @"delete";
NSString * const kAlfrescoJSONCreatedAt = @"createdAt";
NSString * const kAlfrescoJSONCreatedBy = @"createdBy";
NSString * const kAlfrescoJSONCreator = @"creator";
NSString * const kAlfrescoJSONAvatar = @"avatar";
NSString * const kAlfrescoJSONModifedAt = @"modifiedAt";
NSString * const kAlfrescoJSONEdited = @"edited";
NSString * const kAlfrescoJSONCanEdit = @"canEdit";
NSString * const kAlfrescoJSONCanDelete = @"canDelete";
NSString * const kAlfrescoJSONEnabled = @"enabled";
NSString * const kAlfrescoJSONTag = @"tag";
NSString * const kAlfrescoJSONUserName = @"userName";
NSString * const kAlfrescoJSONFirstName = @"firstName";
NSString * const kAlfrescoJSONLastName = @"lastName";
NSString * const kAlfrescoJSONFullName = @"fullName";
NSString * const kAlfrescoJSONActionedUponNode = @"actionedUponNode";
NSString * const kAlfrescoJSONExtractMetadata = @"extract-metadata";
NSString * const kAlfrescoJSONActionDefinitionName = @"actionDefinitionName";
NSString * const kAlfrescoJSONThumbnailName = @"thumbnailName";
NSString * const kAlfrescoJSONSite = @"site";
NSString * const kAlfrescoJSONPostedAt = @"postedAt";
NSString * const kAlfrescoJSONAvatarId = @"avatarId";
NSString * const kAlfrescoJSONAuthority = @"authority";

NSString * const kAlfrescoJSONJobTitle = @"jobtitle";
NSString * const kAlfrescoCloudJSONJobTitle = @"jobTitle";
NSString * const kAlfrescoJSONLocation = @"location";
NSString * const kAlfrescoJSONPersonDescription = @"persondescription";
NSString * const kAlfrescoJSONTelephoneNumber = @"telephone";
NSString * const kAlfrescoJSONMobileNumber = @"mobile";
NSString * const kAlfrescoJSONSkype = @"skype";
NSString * const kAlfrescoJSONGoogle = @"googleusername";
NSString * const kAlfrescoJSONInstantMessage = @"instantmsg";
NSString * const kAlfrescoJSONSkypeId = @"skypeId";
NSString * const kAlfrescoJSONGoogleId = @"googleId";
NSString * const kAlfrescoJSONInstantMessageId = @"instantMessageId";
NSString * const kAlfrescoJSONStatus = @"userStatus";
NSString * const kAlfrescoJSONStatusTime = @"userStatusTime";
NSString * const kAlfrescoJSONEmail = @"email";
NSString * const kAlfrescoJSONCompany = @"company";

NSString * const kAlfrescoJSONCompanyAddressLine1 = @"companyaddress1";
NSString * const kAlfrescoJSONCompanyAddressLine2 = @"companyaddress2";
NSString * const kAlfrescoJSONCompanyAddressLine3 = @"companyaddress3";
NSString * const kAlfrescoJSONCompanyFullAddress = @"fullAddress";
NSString * const kAlfrescoJSONCompanyPostcode = @"companypostcode";
NSString * const kAlfrescoJSONCompanyFaxNumber = @"companyfax";
NSString * const kAlfrescoJSONCompanyName = @"organization";
NSString * const kAlfrescoJSONCompanyTelephone = @"companytelephone";
NSString * const kAlfrescoJSONCompanyEmail = @"companyemail";
NSString * const kAlfrescoJSONAddressLine1 = @"address1";
NSString * const kAlfrescoJSONAddressLine2 = @"address2";
NSString * const kAlfrescoJSONAddressLine3 = @"address3";
NSString * const kAlfrescoJSONPostcode = @"postcode";
NSString * const kAlfrescoJSONFaxNumber = @"fax";

NSString * const kAlfrescoJSONOrg = @"org";
NSString * const kAlfrescoJSONAlfresco = @"alfresco";
NSString * const kAlfrescoJSONShare = @"share";
NSString * const kAlfrescoJSONSites = @"sites";
NSString * const kAlfrescoJSONFavorites = @"favourites";
NSString * const kAlfrescoJSONGUID = @"guid";
NSString * const kAlfrescoJSONTarget = @"target";
NSString * const kAlfrescoJSONPerson = @"person";
NSString * const kAlfrescoJSONPeople = @"people";
NSString * const kAlfrescoJSONRole = @"role";
NSString * const kAlfrescoJSONInvitationType = @"invitationType";
NSString * const kAlfrescoJSONInviteeUsername = @"inviteeUserName";
NSString * const kAlfrescoJSONInviteeComments = @"inviteeComments";
NSString * const kAlfrescoJSONInviteeRolename = @"inviteeRoleName";
NSString * const kAlfrescoJSONInviteId = @"inviteId";
NSString * const kAlfrescoJSONData = @"data";
NSString * const kAlfrescoJSONResourceName = @"resourceName";
NSString * const kAlfrescoJSONMessage = @"message";
NSString * const kAlfrescoJSONFile = @"file";
NSString * const kAlfrescoJSONFolder = @"folder";




NSString * const kAlfrescoNodeAspects = @"cmis.aspects";
NSString * const kAlfrescoNodeProperties = @"cmis.properties";
NSString * const kAlfrescoPropertyType = @"type";
NSString * const kAlfrescoPropertyValue = @"value";
NSString * const kAlfrescoPropertyIsMultiValued = @"isMultiValued";

NSString * const kAlfrescoHTTPDelete = @"DELETE";
NSString * const kAlfrescoHTTPGet = @"GET";
NSString * const kAlfrescoHTTPPOST = @"POST";
NSString * const kAlfrescoHTTPPut = @"PUT";

NSString * const kAlfrescoFileManagerClass = @"AlfrescoFileManagerClassName";
NSString * const kAlfrescoCMISNetworkProvider = @"org.alfresco.mobile.internal.session.cmis.networkprovider";
NSString * const kAlfrescoPropertyTypeFolder = @"F:";
NSString * const kAlfrescoPropertyTypeDocument = @"D:";
NSString * const kAlfrescoPropertyAspect = @"P:";



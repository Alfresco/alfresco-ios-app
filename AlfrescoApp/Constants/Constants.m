//
//  Constants.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "Constants.h"

NSInteger const kMaxItemsPerListingRetrieve = 25;

NSString * const kLicenseDictionaries = @"thirdPartyLibraries";

NSString * const kImageMappingPlist = @"ImageMapping";

// NSUserDefaults Keys
NSString * const kIsAppFirstLaunch = @"IsAppFirstLaunch";

// Request Handler
NSInteger const kRequestTimeOutInterval = 60;
NSString * const kProtocolHTTP = @"http";
NSString * const kProtocolHTTPS = @"https";
NSString * const kHTTPMethodPOST = @"POST";
NSString * const kHTTPMethodGET = @"GET";

// Notificiations
NSString * const kAlfrescoSessionReceivedNotification = @"AlfrescoSessionReceivedNotification";
NSString * const kAlfrescoAccessDeniedNotification = @"AlfrescoUnauthorizedAccessNotification";
NSString * const kAlfrescoApplicationPolicyUpdatedNotification = @"AlfrescoApplicationPolicyUpdatedNotification";
NSString * const kAlfrescoDocumentDownloadedNotification = @"AlfrescoDocumentDownloadedNotification";
NSString * const kAlfrescoConnectivityChangedNotification = @"AlfrescoConnectivityChangedNotification";
NSString * const kAlfrescoDocumentUpdatedOnServerNotification = @"AlfrescoDocumentUpdatedOnServerNotification";
NSString * const kAlfrescoDocumentUpdatedLocallyNotification = @"AlfrescoDocumentUpdatedLocallyNotification";
NSString * const kAlfrescoDocumentUpdatedDocumentParameterKey = @"AlfrescoDocumentUpdatedDocumentParameterKey";
NSString * const kAlfrescoDocumentUpdatedFilenameParameterKey = @"AlfrescoDocumentUpdatedFilenameParameterKey";
NSString * const kAlfrescoDocumentDownloadedIdentifierKey = @"AlfrescoDocumentDownloadedIdentifierKey";

// Accounts
NSString * const kAlfrescoAccountAddedNotification = @"AlfrescoAccountAddedNotification";
NSString * const kAlfrescoAccountRemovedNotification = @"AlfrescoAccountRemovedNotification";
NSString * const kAlfrescoAccountUpdatedNotification = @"AlfrescoAccountUpdatedNotification";
NSString * const kAlfrescoAccountsListEmptyNotification = @"AlfrescoAccountsListEmptyNotification";

// Application policy constants
NSString * const kApplicationPolicySettings = @"ApplicationPolicySettings";
NSString * const kApplicationPolicyAudioVideo = @"ApplicationPolicyAudioVideo";
NSString * const kApplicationPolicyServer = @"ApplicationPolicySettingServer";
NSString * const kApplicationPolicyUsernameGenerationFormat = @"ApplicationPolicySettingUsernameGenerationFormat";
NSString * const kApplicationPolicyServerDisplayName = @"ApplicationPolicySettingServerDisplayName";
NSString * const kApplicationPolicySettingAudioEnabled = @"ApplicationPolicySettingAudioEnabled";
NSString * const kApplicationPolicySettingVideoEnabled = @"ApplicationPolicySettingVideoEnabled";

// Sync
NSString * const kSyncObstaclesKey = @"syncObstacles";
NSInteger const kDefaultMaximumAllowedDownloadSize = 20 * 1024 * 1024; // 20 MB
NSString * const kSyncPreference = @"SyncNodes";
NSString * const kSyncOnCellular = @"SyncOnCellular";

// Sync Notification constants
NSString * const kSyncStatusChangeNotification = @"kSyncStatusChangeNotification";
NSString * const kSyncObstaclesNotification = @"kSyncObstaclesNotification";

// Confirmation Options
NSUInteger const kConfirmationOptionYes = 0;
NSUInteger const kConfirmationOptionNo = 1;

// User settings keychain constants
NSString * const kApplicationRepositoryUsername = @"ApplictionRepositoryUsername";
NSString * const kApplicationRepositoryPassword = @"ApplictionRepositoryPassword";

// The maximum number of file suffixes that are attempted to avoid file overwrites
NSUInteger const kFileSuffixMaxAttempts = 1000;

// Custom NSError codes (use Bundle Identifier for error domain)
NSInteger const kErrorFileSuffixMaxAttempts = 101;

// Upload image quality setting
CGFloat const kUploadJPEGCompressionQuality = 1.0f;

// MultiSelect Actions
NSString * const kMultiSelectDelete = @"deleteAction";

// Favourites notifications
NSString * const kFavouritesDidAddNodeNotification = @"FavouritesDidAddNodeNotification";
NSString * const kFavouritesDidRemoveNodeNotification = @"FavouritesDidRemoveNodeNotification";

// cache
NSInteger const kNumberOfDaysToKeepCachedData = 7;

// Good Services
NSString * const kFileTransferServiceName = @"com.good.gdservice.transfer-file";
NSString * const kFileTransferServiceVersion = @"1.0.0.0";
NSString * const kFileTransferServiceMethod = @"transferFile";
NSString * const kEditFileServiceName = @"com.good.gdservice.edit-file";
NSString * const kEditFileServiceVersion = @"1.0.0.0";
NSString * const kEditFileServiceMethod = @"editFile";
NSString * const kSaveEditFileServiceName = @"com.good.gdservice.save-edited-file";
NSString * const kSaveEditFileServiceVersion = @"1.0.0.1";
NSString * const kSaveEditFileServiceSaveEditMethod = @"saveEdit";
NSString * const kSaveEditFileServiceReleaseEditMethod = @"releaseEdit";
// keys to parameters passed to the editFile service
NSString * const kEditFileServiceParameterKey = @"identificationData"; // defined by Good Service - DO NOT CHANGE VALUE
NSString * const kEditFileServiceParameterAlfrescoDocument = @"alfrescoDocumentNode";
NSString * const kEditFileServiceParameterAlfrescoDocumentIsDownloaded = @"documentIsDownloaded";
NSString * const kEditFileServiceParameterDocumentFileName = @"documentFileName";

NSString * const kAlfrescoOnPremiseServerURLTemplate = @"%@://%@:%@/alfresco";

// Cloud Sign Up
NSString * const kCloudAPIHeaderKey = @"key";
NSString * const kAlfrescoCloudAPISignUpUrl = @"https://a.alfresco.me/alfresco/a/-default-/internal/cloud/accounts/signupqueue";
NSString * const kAlfrescoCloudTermOfServiceUrl = @"http://www.alfresco.com/legal/agreements/cloud/";
NSString * const kAlfrescoCloudPrivacyPolicyUrl = @"http://www.alfresco.com/privacy/";
NSString * const kAlfrescoCloudCustomerCareUrl = @"https://getsatisfaction.com/alfresco/products/alfresco_alfresco_mobile_app";

// Cloud Account Status
NSString * const kCloudAccountIdValuePath = @"registration.id";
NSString * const kCloudAccountKeyValuePath = @"registration.key";
NSString * const kCloudAccountStatusValuePath = @"isActivated";
NSString * const kAlfrescoCloudAPIAccountStatusUrl = @"https://a.alfresco.me/alfresco/a/-default-/internal/cloud/accounts/signupqueue/{AccountId}?key={AccountKey}";
NSString * const kAlfrescoCloudAPIAccountKey = @"{AccountKey}";
NSString * const kAlfrescoCloudAPIAccountID = @"{AccountId}";

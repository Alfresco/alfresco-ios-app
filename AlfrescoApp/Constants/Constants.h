//
//  Constants.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ImageCompletionBlock)(UIImage *image, NSError *error);

extern NSInteger const kMaxItemsPerListingRetrieve;

extern NSString * const kLicenseDictionaries;

extern NSString * const kSmallThumbnailImageMappingPlist;
extern NSString * const kLargeThumbnailImageMappingPlist;

extern NSString * const kRenditionImageDocLib;
extern NSString * const kRenditionImageImagePreview;

extern NSInteger const kRequestTimeOutInterval;
extern NSString * const kProtocolHTTP;
extern NSString * const kProtocolHTTPS;
extern NSString * const kHTTPMethodPOST;
extern NSString * const kHTTPMethodGET;

// NSUserDefault Keys
extern NSString * const kIsAppFirstLaunch;

// App Configuration
extern NSString * const kAppConfigurationFileLocationOnServer;
extern NSString * const kAppConfigurationActivitiesKey;
extern NSString * const kAppConfigurationFavoritesKey;
extern NSString * const kAppConfigurationLocalFilesKey;
extern NSString * const kAppConfigurationNotificationsKey;
extern NSString * const kAppConfigurationRepositoryKey;
extern NSString * const kAppConfigurationSearchKey;
extern NSString * const kAppConfigurationSitesKey;
extern NSString * const kAppConfigurationTasksKey;
extern NSString * const kAppConfigurationMyFilesKey;
extern NSString * const kAppConfigurationSharedFilesKey;

// App Configuration Notifications
extern NSString * const kAlfrescoAppConfigurationUpdatedNotification;

// Notificiations
extern NSString * const kAlfrescoSessionReceivedNotification;
extern NSString * const kAlfrescoAccessDeniedNotification;
extern NSString * const kAlfrescoApplicationPolicyUpdatedNotification;
extern NSString * const kAlfrescoDocumentDownloadedNotification;
extern NSString * const kAlfrescoConnectivityChangedNotification;
extern NSString * const kAlfrescoDocumentUpdatedOnServerNotification;
extern NSString * const kAlfrescoDocumentUpdatedLocallyNotification;
extern NSString * const kAlfrescoDocumentDeletedOnServerNotification;
extern NSString * const kAlfrescoNodeAddedOnServerNotification;
// parameter keys used in the dictionary of notification object
extern NSString * const kAlfrescoDocumentUpdatedDocumentParameterKey;
extern NSString * const kAlfrescoDocumentUpdatedFilenameParameterKey;
extern NSString * const kAlfrescoDocumentDownloadedIdentifierKey;
extern NSString * const kAlfrescoNodeAddedOnServerParentFolderKey;
extern NSString * const kAlfrescoNodeAddedOnServerSubNodeKey;

// Accounts
extern NSString * const kAlfrescoAccountAddedNotification;
extern NSString * const kAlfrescoAccountRemovedNotification;
extern NSString * const kAlfrescoAccountUpdatedNotification;
extern NSString * const kAlfrescoAccountsListEmptyNotification;

// Application policy constants
extern NSString * const kApplicationPolicySettings;
extern NSString * const kApplicationPolicyAudioVideo;
extern NSString * const kApplicationPolicyServer;
extern NSString * const kApplicationPolicyUsernameGenerationFormat;
extern NSString * const kApplicationPolicyServerDisplayName;
extern NSString * const kApplicationPolicySettingAudioEnabled;
extern NSString * const kApplicationPolicySettingVideoEnabled;

// Sync
extern NSString * const kSyncObstaclesKey;
extern NSInteger const kDefaultMaximumAllowedDownloadSize;
extern NSString * const kSyncPreference;
extern NSString * const kSyncOnCellular;

// Sync notification constants
extern NSString * const kSyncStatusChangeNotification;
extern NSString * const kSyncObstaclesNotification;

// Local Files Notification
extern NSString * const kAlfrescoLocalDocumentNewName;
extern NSString * const kAlfrescoDeleteLocalDocumentNotification;
extern NSString * const kAlfrescoLocalDocumentRenamedNotification;

// Confirmation Options
extern NSUInteger const kConfirmationOptionYes;
extern NSUInteger const kConfirmationOptionNo;

// User settings keychain constants
extern NSString * const kApplicationRepositoryUsername;
extern NSString * const kApplicationRepositoryPassword;

// The maximum number of file suffixes that are attempted to avoid file overwrites
extern NSUInteger const kFileSuffixMaxAttempts;

// Custom NSError codes (use Bundle Identifier for error domain)
extern NSInteger const kErrorFileSuffixMaxAttempts;

// Upload image quality setting
extern CGFloat const kUploadJPEGCompressionQuality;

// MultiSelect Actions
extern NSString * const kMultiSelectDelete;

// Favourites notifications
extern NSString * const kFavouritesDidAddNodeNotification;
extern NSString * const kFavouritesDidRemoveNodeNotification;

// Cache
extern NSInteger const kNumberOfDaysToKeepCachedData;

extern NSString * const kAlfrescoOnPremiseServerURLTemplate;

// Cloud Sign Up
extern NSString * const kCloudAPIHeaderKey;
extern NSString * const kAlfrescoCloudAPISignUpUrl;
extern NSString * const kAlfrescoCloudTermOfServiceUrl;
extern NSString * const kAlfrescoCloudPrivacyPolicyUrl;
extern NSString * const kAlfrescoCloudCustomerCareUrl;

// Cloud Account Status
extern NSString * const kCloudAccountIdValuePath;
extern NSString * const kCloudAccountKeyValuePath;
extern NSString * const kCloudAccountStatusValuePath;
extern NSString * const kAlfrescoCloudAPIAccountStatusUrl;
extern NSString * const kAlfrescoCloudAPIAccountKey;
extern NSString * const kAlfrescoCloudAPIAccountID;

// Help/Documentation
extern NSString * const kAlfrescoHelpURLString;

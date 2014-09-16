/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
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
  
typedef NS_ENUM(NSUInteger, TaskFilter)
{
    TaskFilterTask = 0,
    TaskFilterProcess
};

typedef NS_ENUM(NSInteger, InAppDocumentLocation)
{
    InAppDocumentLocationFilesAndFolders = 0,
    InAppDocumentLocationSync,
    InAppDocumentLocationLocalFiles
};

typedef NS_ENUM(NSUInteger, MainMenuType)
{
    MainMenuTypeAccounts = 0,
    MainMenuTypeActivities,
    MainMenuTypeRepository,
    MainMenuTypeSites,
    MainMenuTypeTasks,
    MainMenuTypeSync,
    MainMenuTypeMyFiles,
    MainMenuTypeSharedFiles,
    MainMenuTypeDownloads,
    MainMenuTypeSettings,
    MainMenuTypeAbout,
    MainMenuTypeHelp,
    MainMenuType_MAX_ENUM    // <-- Ensure this is the last entry
};

typedef void (^ImageCompletionBlock)(UIImage *image, NSError *error);
typedef void (^LoginAuthenticationCompletionBlock)(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error);

extern NSTimeInterval const kRateLimitForRequestsOnCloud;

extern int const kMaxItemsPerListingRetrieve;

extern NSString * const kLicenseDictionaries;

extern NSString * const kSmallThumbnailImageMappingPlist;
extern NSString * const kLargeThumbnailImageMappingPlist;

extern NSString * const kRenditionImageDocLib;
extern NSString * const kRenditionImageImagePreview;

extern NSString * const kRepositoryEditionEnterprise;
extern NSString * const kRepositoryEditionCommunity;

extern NSString * const kEditableDocumentExtensions;
extern NSString * const kEditableDocumentMimeTypes;

// "No Files" font size
extern CGFloat const kEmptyListLabelFontSize;

extern NSInteger const kRequestTimeOutInterval;
extern NSString * const kProtocolHTTP;
extern NSString * const kProtocolHTTPS;
extern NSString * const kHTTPMethodPOST;
extern NSString * const kHTTPMethodGET;

// App RevealController
extern CGFloat const kRevealControllerMasterViewWidth;

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

// Notifications
extern NSString * const kAlfrescoSessionReceivedNotification;
extern NSString * const kAlfrescoSiteRequestsCompletedNotification;
extern NSString * const kAlfrescoAccessDeniedNotification;
extern NSString * const kAlfrescoApplicationPolicyUpdatedNotification;
extern NSString * const kAlfrescoDocumentDownloadedNotification;
extern NSString * const kAlfrescoConnectivityChangedNotification;
extern NSString * const kAlfrescoDocumentUpdatedOnServerNotification;
extern NSString * const kAlfrescoDocumentUpdatedLocallyNotification;
extern NSString * const kAlfrescoDocumentDeletedOnServerNotification;
extern NSString * const kAlfrescoNodeAddedOnServerNotification;
// parameter keys used in the dictionary of notification object
extern NSString * const kAlfrescoDocumentUpdatedFromDocumentParameterKey;
extern NSString * const kAlfrescoDocumentUpdatedFilenameParameterKey;
extern NSString * const kAlfrescoDocumentDownloadedIdentifierKey;
extern NSString * const kAlfrescoNodeAddedOnServerParentFolderKey;
extern NSString * const kAlfrescoNodeAddedOnServerSubNodeKey;
extern NSString * const kAlfrescoNodeAddedOnServerContentLocationLocally;
extern NSString * const kAlfrescoWorkflowTaskListDidChangeNotification;
extern NSString * const kAlfrescoDocumentEditedNotification;
// Saveback
extern NSString * const kAlfrescoSaveBackLocalComplete;
extern NSString * const kAlfrescoSaveBackRemoteComplete;

// Accounts
extern NSString * const kAlfrescoAccountAddedNotification;
extern NSString * const kAlfrescoAccountRemovedNotification;
extern NSString * const kAlfrescoAccountUpdatedNotification;
extern NSString * const kAlfrescoAccountsListEmptyNotification;
extern NSString * const kAlfrescoFirstPaidAccountAddedNotification;
extern NSString * const kAlfrescoLastPaidAccountRemovedNotification;

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
extern NSString * const kFavoritesListUpdatedNotification;
extern NSString * const kSyncProgressViewVisiblityChangeNotification;

// Download Status Notifications
extern NSString * const kDocumentPreviewManagerWillStartDownloadNotification;
extern NSString * const kDocumentPreviewManagerProgressNotification;
extern NSString * const kDocumentPreviewManagerDocumentDownloadCompletedNotification;
extern NSString * const kDocumentPreviewManagerDocumentDownloadCancelledNotification;
extern NSString * const kDocumentPreviewManagerWillStartLocalDocumentDownloadNotification;

// Download Detail Keys
extern NSString * const kDocumentPreviewManagerDocumentIdentifierNotificationKey;
extern NSString * const kDocumentPreviewManagerProgressBytesRecievedNotificationKey;
extern NSString * const kDocumentPreviewManagerProgressBytesTotalNotificationKey;

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

// Pickers
extern CGFloat const kPickerMultiSelectToolBarHeight;

// Favourites notifications
extern NSString * const kFavouritesDidAddNodeNotification;
extern NSString * const kFavouritesDidRemoveNodeNotification;

// Cache
extern NSInteger const kNumberOfDaysToKeepCachedData;

extern NSString * const kAlfrescoOnPremiseServerURLTemplate;

// Cloud Configuration
extern NSString * const kCloudConfigFile;
extern NSString * const kCloudConfigParamURL;
extern NSString * const kCloudConfigParamAPIKey;
extern NSString * const kCloudConfigParamSecretKey;
extern NSString * const kInternalSessionCloudURL;

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

// Workflow
extern NSString * const kAlfrescoWorkflowActivitiEngine;
extern NSString * const kAlfrescoWorkflowJBPMEngine;
extern NSString * const kJBPMReviewTask;
extern NSString * const kActivitiReviewTask;

// Google Quickoffice
extern NSString * const kQuickofficeApplicationSecretUUIDKey;
extern NSString * const kQuickofficeApplicationInfoKey;
extern NSString * const kQuickofficeApplicationIdentifierKey;
extern NSString * const kQuickofficeApplicationDocumentExtension;
extern NSString * const kQuickofficeApplicationDocumentExtensionKey;
extern NSString * const kQuickofficeApplicationDocumentUTI;
extern NSString * const kQuickofficeApplicationDocumentUTIKey;
// Custom
extern NSString * const kQuickofficeApplicationBundleIdentifierPrefix;
extern NSString * const kAlfrescoInfoMetadataKey;
extern NSString * const kAppIdentifier;

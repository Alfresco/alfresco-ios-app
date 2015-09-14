/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

#import <Foundation/Foundation.h>
#import "SharedConstants.h"

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

typedef NS_ENUM(NSInteger, SearchViewControllerDataSourceType)
{
    SearchViewControllerDataSourceTypeLandingPage = 0,
    SearchViewControllerDataSourceTypeSearchFiles,
    SearchViewControllerDataSourceTypeSearchFolders,
    SearchViewControllerDataSourceTypeSearchSites,
    SearchViewControllerDataSourceTypeSearchUsers
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
extern NSString * const kSearchTypeFiles;
extern NSString * const kSearchTypeFolders;
extern NSString * const kSearchTypeSites;
extern NSString * const kSearchTypeUsers;

// Settings Bundle Keys
extern NSString * const kSettingsBundlePreferenceAppVersionKey;
extern NSString * const kSettingsBundlePreferenceSafeModeKey;

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
extern NSString * const kAlfrescoEnableMainMenuAutoItemSelection;
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
extern NSString * const kAlfrescoDefaultHTTPPortString;
extern NSString * const kAlfrescoDefaultHTTPSPortString;
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
extern NSString * const kAlfrescoDeletedLocalDocumentsFolderNotification;

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
extern NSString * const kCloudAPIHeaderKey;

// Cloud Account Status
extern NSString * const kCloudAccountIdValuePath;
extern NSString * const kCloudAccountKeyValuePath;
extern NSString * const kCloudAccountStatusValuePath;
extern NSString * const kAlfrescoCloudAPIAccountStatusUrl;
extern NSString * const kAlfrescoCloudAPIAccountKey;
extern NSString * const kAlfrescoCloudAPIAccountID;

// Help/Documentation
extern NSString * const kAlfrescoHelpURLPlistFilename;
extern NSString * const kAlfrescoHelpURLString;
extern NSString * const kAlfrescoISO6391EnglishCode;
extern NSString * const kAlfrescoISO6391GermanCode;
extern NSString * const kAlfrescoISO6391FrenchCode;
extern NSString * const kAlfrescoISO6391SpanishCode;
extern NSString * const kAlfrescoISO6391ItalianCode;
extern NSString * const kAlfrescoISO6391JapaneseCode;
extern NSString * const kAlfrescoISO6391ChineseCode;

// Workflow
extern NSString * const kAlfrescoWorkflowActivitiEngine;
extern NSString * const kAlfrescoWorkflowJBPMEngine;
extern NSString * const kJBPMReviewTask;
extern NSString * const kActivitiReviewTask;
extern NSString * const kJBPMInvitePendingTask;
extern NSString * const kActivitiInvitePendingTask;
extern NSString * const kJBPMInviteAcceptedTask;
extern NSString * const kActivitiInviteAcceptedTask;
extern NSString * const kJBPMInviteRejectedTask;
extern NSString * const kActivitiInviteRejectedTask;

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

// MDM User Defaults
extern NSString * const kAppleManagedConfigurationKey;
extern NSString * const kMobileIronManagedConfigurationKey;

// MDM Server Keys
extern NSString * const kAlfrescoMDMRepositoryURLKey;
extern NSString * const kAlfrescoMDMUsernameKey;
extern NSString * const kAlfrescoMDMDisplayNameKey;

// PagedScrollView Notifications
extern NSString * const kAlfrescoPagedScrollViewLayoutSubviewsNotification;

// Main Menu
///
extern NSString * const kAlfrescoEmbeddedConfigurationFileName;
/// Notifications
extern NSString * const kAlfrescoConfigurationFileDidUpdateNotification;
extern NSString * const kAlfrescoConfigurationShouldUpdateMainMenuNotification;
extern NSString * const kAlfrescoConfigurationProfileDidChangeNotification;
/// Keys
extern NSString * const kAlfrescoConfigurationProfileDidChangeForAccountKey;
/// Menu Item Identifiers
extern NSString * const kAlfrescoMainMenuItemAccountsIdentifier;
extern NSString * const kAlfrescoMainMenuItemCompanyHomeIdentifier;
extern NSString * const kAlfrescoMainMenuItemSitesIdentifier;
extern NSString * const kAlfrescoMainMenuItemSyncIdentifier;
extern NSString * const kAlfrescoMainMenuItemSettingsIdentifier;
extern NSString * const kAlfrescoMainMenuItemHelpIdentifier;
/// View Types
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeActivities;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeRepository;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeSiteBrowser;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeTasks;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeFavourites;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeSync;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeLocal;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypePersonProfile;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypePeople;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeGallery;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeDocumentDetails;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeSite;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeSearchRepository;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeSearch;
extern NSString * const kAlfrescoMainMenuConfigurationViewTypeSearchAdvanced;
// View Parameter Keys
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterSiteShortNameKey;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterPathKey;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterNodeRefKey;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterShowKey;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterTypeKey;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterKeywordsKey;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterIsExactKey;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterFullTextKey;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterSearchFolderOnlyKey;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterStatementKey;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterUsernameKey;
// View Parameter Values
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterMySitesValue;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterFavouriteSitesValue;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterAllSitesValue;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterAdvancedSearchPerson;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterAdvancedSearchDocument;
extern NSString * const kAlfrescoMainMenuConfigurationViewParameterAdvancedSearchFolder;

// App Configuration
//// Notifictaions
extern NSString * const kAppConfigurationAccountsConfigurationUpdatedNotification;
//// Keys
extern NSString * const kAppConfigurationCanAddAccountsKey;
extern NSString * const kAppConfigurationCanEditAccountsKey;
extern NSString * const kAppConfigurationCanRemoveAccountsKey;
///// Main Menu
extern NSString * const kAppConfigurationUserCanEditMainMenuKey;

// Person Profile
extern NSString * const kPhoneURLScheme;
extern NSString * const kMapsURLScheme;
extern NSString * const kMapsURLSchemeQueryParameter;
extern NSString * const kSkypeURLScheme;
extern NSString * const kSkypeURLCommunicationTypeCall;
extern NSString * const kSkypeURLCommunicationTypeChat;
extern NSString * const kSkypeAppStoreiPhoneURL;
extern NSString * const KSkypeAppStoreiPadURL;

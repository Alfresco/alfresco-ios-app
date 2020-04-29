/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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
 
#import "Constants.h"

// Time delay used in workaround for Cloud API rate limiting issues (comments and version history requests)
NSTimeInterval const kRateLimitForRequestsOnCloud = 1.0;

int const kMaxItemsPerListingRetrieve = 25;

NSString * const kLicenseDictionaries = @"thirdPartyLibraries";

NSString * const kSmallThumbnailImageMappingPlist = @"SmallThumbnailImageMapping";
NSString * const kLargeThumbnailImageMappingPlist = @"LargeThumbnailImageMapping";

NSString * const kRenditionImageDocLib = @"doclib";
NSString * const kRenditionImageImagePreview = @"imgpreview";

NSString * const kRepositoryEditionEnterprise = @"Enterprise";
NSString * const kRepositoryEditionCommunity = @"Community";

NSString * const kEditableDocumentExtensions = @"txt,htm,html,xml,css,js,ftl,java,properties";
// In addition, all "text/..." mimetypes are allowed to be edited
NSString * const kEditableDocumentMimeTypes = @"application/xml,application/javascript";

// "No Files" font size
CGFloat const kEmptyListLabelFontSize = 24.0f;

// App RevealController
CGFloat const kRevealControllerMasterViewWidth = 300.0f;

// Expand control animation speed (e.g. Site Cell)
CGFloat const kExpandButtonRotationSpeed = 0.2f;

// UISegmentControl metrics
CGFloat kUISegmentControlHorizontalPadding = 10.0f;
CGFloat kUISegmentControlVerticalPadding = 10.0f;
CGFloat kUISegmentControllerHeight = 40.0f;

// UICollectionView Header height
CGFloat kCollectionViewHeaderHight = 56.0f;

// NSUserDefaults Keys
NSString * const kSearchTypeFiles = @"ALFSearchTypeFiles";
NSString * const kSearchTypeFolders = @"ALFSearchTypeFolders";
NSString * const kSearchTypeSites = @"ALFSearchTypeSites";
NSString * const kSearchTypeUsers = @"ALFSearchTypeUsers";
NSString * const kHasCoreDataMigrationOccurred = @"hasMigrationOccurred";
NSString * const kWasSyncInfoPanelShown = @"wasSyncInfoPanelShown";
NSString * const kVersionOfLastRun = @"kVersionOfLastRun";
NSString * const kCloudTerminationAlertShownKey = @"CloudTerminationAlertShown";
NSString * const kHasAccountMigrationOccured = @"hasAccountMigrationOccured";
NSString * const kPersistenceStackSessionParameter = @"AlfrescoSession";
NSString * const kPersistenceStackCredentialParameter = @"AlfrescoCredential";

// errors
int const kAFALoginSSOViewModelCancelErrorCode = -3;

// Settings Bundle Keys
NSString * const kSettingsBundlePreferenceAppVersionKey = @"Prefs_AppVersion";
NSString * const kSettingsBundlePreferenceSafeModeKey = @"Prefs_SafeMode";

// App Configuration Notifications
NSString * const kAlfrescoAppConfigurationUpdatedNotification = @"AlfrescoAppConfigurationUpdatedNotification";

// Request Handler
NSInteger const kRequestTimeOutInterval = 60;
NSString * const kProtocolHTTP = @"http";
NSString * const kProtocolHTTPS = @"https";
NSString * const kHTTPMethodPOST = @"POST";
NSString * const kHTTPMethodGET = @"GET";

// Notifications
NSString * const kAlfrescoSessionReceivedNotification = @"AlfrescoSessionReceivedNotification";
NSString * const kAlfrescoSessionRefreshedNotification = @"AlfrescoSessionRefreshedNotification";
NSString * const kAlfrescoTokenExpiredNotification = @"AlfrescoTokenExpiredNotification";
NSString * const kAlfrescoSiteRequestsCompletedNotification = @"AlfrescoSiteRequestsCompletedNotification";
NSString * const kAlfrescoAccessDeniedNotification = @"AlfrescoUnauthorizedAccessNotification";
NSString * const kAlfrescoApplicationPolicyUpdatedNotification = @"AlfrescoApplicationPolicyUpdatedNotification";
NSString * const kAlfrescoDocumentDownloadedNotification = @"AlfrescoDocumentDownloadedNotification";
NSString * const kAlfrescoConnectivityChangedNotification = @"AlfrescoConnectivityChangedNotification";
NSString * const kAlfrescoDocumentUpdatedOnServerNotification = @"AlfrescoDocumentUpdatedOnServerNotification";
NSString * const kAlfrescoDocumentUpdatedLocallyNotification = @"AlfrescoDocumentUpdatedLocallyNotification";
NSString * const kAlfrescoDocumentDeletedOnServerNotification = @"AlfrescoDocumentDeletedOnServerNotification";
NSString * const kAlfrescoNodeAddedOnServerNotification = @"AlfrescoNodeAddedOnServerNotification";
NSString * const kAlfrescoDocumentUpdatedFromDocumentParameterKey = @"AlfrescoDocumentUpdatedFromDocumentParameterKey";
NSString * const kAlfrescoDocumentUpdatedFilenameParameterKey = @"AlfrescoDocumentUpdatedFilenameParameterKey";
NSString * const kAlfrescoDocumentDownloadedIdentifierKey = @"AlfrescoDocumentDownloadedIdentifierKey";
NSString * const kAlfrescoNodeAddedOnServerParentFolderKey = @"AlfrescoNodeAddedOnServerParentFolderKey";
NSString * const kAlfrescoNodeAddedOnServerSubNodeKey = @"AlfrescoNodeAddedOnServerSubNodeKey";
NSString * const kAlfrescoNodeAddedOnServerContentLocationLocally = @"AlfrescoNodeAddedOnServerContentLocationLocally";
NSString * const kAlfrescoWorkflowTaskListDidChangeNotification = @"AlfrescoWorkflowTaskListDidChange";
NSString * const kAlfrescoDocumentEditedNotification = @"AlfrescoDocumentEditedNotification";
NSString * const kAlfrescoEnableMainMenuAutoItemSelection = @"AlfrescoEnableMainMenuAutoItemSelection";
NSString * const kAlfrescoShowAccountPickerNotification = @"AlfrescoShowAccountPickerNotification";

// Saveback
NSString * const kAlfrescoSaveBackLocalComplete = @"AlfrescoSaveBackLocalComplete";
NSString * const kAlfrescoSaveBackRemoteComplete = @"AlfrescoSaveBackRemoteComplete";

// Accounts
NSString * const kAlfrescoDefaultHTTPPortString = @"80";
NSString * const kAlfrescoDefaultHTTPSPortString = @"443";
NSString * const kAlfrescoAccountAddedNotification = @"AlfrescoAccountAddedNotification";
NSString * const kAlfrescoAccountRemovedNotification = @"AlfrescoAccountRemovedNotification";
NSString * const kAlfrescoAccountUpdatedNotification = @"AlfrescoAccountUpdatedNotification";
NSString * const kAlfrescoAccountsListEmptyNotification = @"AlfrescoAccountsListEmptyNotification";
NSString * const kAlfrescoFirstPaidAccountAddedNotification = @"AlfrescoFirstPaidAccountAddedNotification";
NSString * const kAlfrescoLastPaidAccountRemovedNotification = @"AlfrescoLastPaidAccountRemovedNotification";
NSString * const kAlfrescoDefaultAIMSClientIDString = @"alfresco-ios-acs-app";
NSString * const kAlfrescoDefaultAIMSRealmString = @"alfresco";
NSString * const kAlfrescoDefaultAIMSRedirectURI = @"iosacsapp://aims/auth";
NSInteger const kAlfrescoDefaultAIMSAccessTokenRefreshTimeBuffer = 10;

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
NSString * const kFavoritesListUpdatedNotification = @"kFavoritesListUpdatedNotification";
NSString * const kSyncProgressViewVisiblityChangeNotification = @"kSyncProgressViewVisiblityChangeNotification";
NSString * const kTopLevelSyncDidAddNodeNotification = @"TopLevelSyncDidAddNodeNotification";
NSString * const kTopLevelSyncDidRemoveNodeNotification = @"TopLevelSyncDidRemoveNodeNotification";

// Download Notifications
NSString * const kDocumentPreviewManagerWillStartDownloadNotification = @"DocumentPreviewManagerWillStartDownloadNotification";
NSString * const kDocumentPreviewManagerProgressNotification = @"DocumentPreviewManagerProgressNotification";
NSString * const kDocumentPreviewManagerDocumentDownloadCompletedNotification = @"DocumentPreviewManagerDocumentDownloadCompletedNotification";
NSString * const kDocumentPreviewManagerDocumentDownloadCancelledNotification = @"DocumentPreviewManagerDocumentDownloadCancelledNotification";
NSString * const kDocumentPreviewManagerWillStartLocalDocumentDownloadNotification = @"DocumentPreviewManagerWillStartLocalDocumentDownloadNotification";

// Download Notification Keys
NSString * const kDocumentPreviewManagerDocumentIdentifierNotificationKey = @"DocumentPreviewManagerDocumentIdentifierNotificationKey";
NSString * const kDocumentPreviewManagerProgressBytesRecievedNotificationKey = @"DocumentPreviewManagerProgressBytesRecievedNotificationKey";
NSString * const kDocumentPreviewManagerProgressBytesTotalNotificationKey = @"DocumentPreviewManagerProgressBytesTotalNotificationKey";

// Local Files Notification
NSString * const kAlfrescoLocalDocumentNewName = @"AlfrescoLocalDocumentNewName";
NSString * const kAlfrescoDeleteLocalDocumentNotification = @"AlfrescoDeleteDocumentFileNotification";
NSString * const kAlfrescoLocalDocumentRenamedNotification = @"AlfrescoLocalDocumentRenamedNotification";
NSString * const kAlfrescoDeletedLocalDocumentsFolderNotification = @"AlfrescoDeletedLocalDocumentsFolderNotification";

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

// Pickers
CGFloat const kPickerMultiSelectToolBarHeight = 44.0f;

// Favourites notifications
NSString * const kFavouritesDidAddNodeNotification = @"FavouritesDidAddNodeNotification";
NSString * const kFavouritesDidRemoveNodeNotification = @"FavouritesDidRemoveNodeNotification";

// Cache
NSInteger const kNumberOfDaysToKeepCachedData = 7;

// Cloud Configuration
NSString * const kCloudConfigFile = @"cloud-config.plist";
NSString * const kCloudConfigParamURL = @"oauth_url";
NSString * const kCloudConfigParamAPIKey = @"apikey";
NSString * const kCloudConfigParamSecretKey = @"apisecret";
NSString * const kInternalSessionCloudURL = @"org.alfresco.mobile.internal.session.cloud.url";
NSString * const kCloudAPIHeaderKey = @"key";

// Cloud Account Status
NSString * const kCloudAccountIdValuePath = @"registration.id";
NSString * const kCloudAccountKeyValuePath = @"registration.key";
NSString * const kCloudAccountStatusValuePath = @"isActivated";
NSString * const kAlfrescoCloudAPIAccountStatusUrl = @"https://a.alfresco.me/alfresco/a/-default-/internal/cloud/accounts/signupqueue/{AccountId}?key={AccountKey}";
NSString * const kAlfrescoCloudAPIAccountKey = @"{AccountKey}";
NSString * const kAlfrescoCloudAPIAccountID = @"{AccountId}";

// Help/Documentation
NSString * const kAlfrescoHelpURLPlistFilename = @"HelpURLKeys";
NSString * const kAlfrescoHelpURLString = @"http://docs.alfresco.com/%@/topics/mobile-overview.html";
NSString * const kAlfrescoISO6391EnglishCode = @"en";
NSString * const kAlfrescoISO6391GermanCode = @"de";
NSString * const kAlfrescoISO6391FrenchCode = @"fr";
NSString * const kAlfrescoISO6391SpanishCode = @"es";
NSString * const kAlfrescoISO6391ItalianCode = @"it";
NSString * const kAlfrescoISO6391JapaneseCode = @"ja";
NSString * const kAlfrescoISO6391ChineseCode = @"zh";

// Workflow
NSString * const kAlfrescoWorkflowActivitiEngine = @"activiti$";
NSString * const kAlfrescoWorkflowJBPMEngine = @"jbpm$";
NSString * const kJBPMReviewTask = @"wf:reviewTask";
NSString * const kActivitiReviewTask = @"wf:activitiReviewTask";
NSString * const kJBPMInvitePendingTask = @"inwf:invitePendingTask";
NSString * const kActivitiInvitePendingTask = @"inwf:activitiInvitePendingTask";
NSString * const kJBPMInviteAcceptedTask = @"inwf:acceptInviteTask";
NSString * const kActivitiInviteAcceptedTask = @"inwf:acceptInviteTask";
NSString * const kJBPMInviteRejectedTask = @"inwf:rejectInviteTask";
NSString * const kActivitiInviteRejectedTask = @"inwf:rejectInviteTask";

// Google Quickoffice
NSString * const kQuickofficeApplicationSecretUUIDKey = @"PartnerApplicationSecretUUID";
NSString * const kQuickofficeApplicationInfoKey = @"PartnerApplicationInfo";
NSString * const kQuickofficeApplicationIdentifierKey = @"PartnerApplicationIdentifier";
NSString * const kQuickofficeApplicationDocumentExtension = @"alf01";
NSString * const kQuickofficeApplicationDocumentExtensionKey = @"PartnerApplicationDocumentExtension";
NSString * const kQuickofficeApplicationDocumentUTI = @"com.alfresco.mobile.qpa";
NSString * const kQuickofficeApplicationDocumentUTIKey = @"PartnerApplicationDocumentUTI";
// Custom
NSString * const kQuickofficeApplicationBundleIdentifierPrefix = @"com.quickoffice.";
NSString * const kAlfrescoInfoMetadataKey = @"AlfrescoInfoMetadataKey";
NSString * const kAppIdentifier = @"AlfrescoMobileApp";

// MDM User Defaults
NSString * const kAppleManagedConfigurationKey = @"com.apple.configuration.managed";
NSString * const kMobileIronManagedConfigurationKey = @"com.alfresco.mobileiron.managed";

// MDM Server Keys
NSString * const kAlfrescoMDMRepositoryURLKey = @"AlfrescoRepositoryURL";
NSString * const kAlfrescoMDMUsernameKey = @"AlfrescoUserName";
NSString * const kAlfrescoMDMDisplayNameKey = @"AlfrescoDisplayName";

// PagedScrollView Notifications
NSString * const kAlfrescoPagedScrollViewLayoutSubviewsNotification = @"AlfrescoPagedScrollViewLayoutSubviewsNotification";

// Main Menu
///
NSString * const kAlfrescoEmbeddedConfigurationFileName = @"configuration.json";
NSString * const kAlfrescoNoAccountConfigurationFileName = @"noAccountsConfiguration.json";
/// Notifications
NSString * const kAlfrescoConfigFileDidUpdateNotification = @"AlfrescoConfigurationFileDidUpdateNotification";
NSString * const kAlfrescoConfigShouldUpdateMainMenuNotification = @"AlfrescoConfigurationShouldUpdateMainMenuNotification";
NSString * const kAlfrescoConfigProfileDidChangeNotification = @"AlfrescoConfigurationProfileDidChangeNotification";
/// Keys
NSString * const kAlfrescoConfigProfileDidChangeForAccountKey = @"AlfrescoConfigurationProfileDidChangeForAccountKey";
/// Menu Item Identifiers
NSString * const kAlfrescoMainMenuItemAccountsIdentifier = @"org.alfresco.com.mobile.main.menu.accounts.identifier";
NSString * const kAlfrescoMainMenuItemCompanyHomeIdentifier = @"org.alfresco.com.mobile.main.menu.company.home.identifier";
NSString * const kAlfrescoMainMenuItemSitesIdentifier = @"org.alfresco.com.mobile.main.menu.sites.identifier";
NSString * const kAlfrescoMainMenuItemFavoritesIdentifier = @"org.alfresco.com.mobile.main.menu.favorites.identifier";
NSString * const kAlfrescoMainMenuItemSyncIdentifier = @"org.alfresco.com.mobile.main.menu.sync.identifier";
NSString * const kAlfrescoMainMenuItemSettingsIdentifier = @"org.alfresco.com.mobile.main.menu.settings.identifier";
NSString * const kAlfrescoMainMenuItemHelpIdentifier = @"org.alfresco.com.mobile.main.menu.help.identifier";
// Features
NSString * const kAlfrescoConfigFeatureTypeAnalytics = @"org.alfresco.client.feature.analytics";

// App Configuration
//// Notifications
NSString * const kAppConfigurationAccountsConfigurationUpdatedNotification = @"AppConfigurationAccountsConfigurationUpdatedNotification";
//// Keys
NSString * const kAppConfigurationCanAddAccountsKey = @"AppConfigurationCanAddAccounts";
NSString * const kAppConfigurationCanEditAccountsKey = @"AppConfigurationCanEditAccounts";
NSString * const kAppConfigurationCanRemoveAccountsKey = @"AppConfigurationCanRemoveAccounts";
//// Main Menu
NSString * const kAppConfigurationUserCanEditMainMenuKey = @"AppConfigurationUserCanEditMainMenuKey";

// Person Profile
NSString * const kPhoneURLScheme = @"tel://";
NSString * const kMapsURLScheme = @"http://maps.apple.com/";
NSString * const kMapsURLSchemeQueryParameter = @"q";
NSString * const kSkypeURLScheme = @"skype:";
NSString * const kSkypeURLCommunicationTypeCall = @"call";
NSString * const kSkypeURLCommunicationTypeChat = @"chat";
NSString * const kSkypeAppStoreiPhoneURL = @"http://itunes.apple.com/app/skype-for-iphone/id304878510?mt=8";
NSString * const KSkypeAppStoreiPadURL = @"http://itunes.apple.com/app/skype-for-ipad/id442012681?mt=8";

NSString * const kSyncViewIdentifier = @"view-sync-default";
NSString * const kLocalViewIdentifier = @"view-local-default";

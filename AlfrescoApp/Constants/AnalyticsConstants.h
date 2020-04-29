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

#import <Foundation/Foundation.h>

#pragma mark - Screens

// Account
extern NSString * const kAnalyticsViewAccountCreateTypePicker;
extern NSString * const kAnalyticsViewAccountCreateServer;
extern NSString * const kAnalyticsViewAccountCreateCredentials;
extern NSString * const kAnalyticsViewAccountCreateDiagnostics;
extern NSString * const kAnalyticsViewAccountEdit;
extern NSString * const kAnalyticsViewAccountEditActiveProfile;
extern NSString * const kAnalyticsViewAccountEditEditMainMenu;
extern NSString * const kAnalyticsViewAccountEditAccountDetails;
extern NSString * const kAnalyticsViewAccountOAuth;
extern NSString * const kAnalyticsViewAccountSAML;

// Menu
extern NSString * const kAnalyticsViewMenuActivities;
extern NSString * const kAnalyticsViewMenuRepository;
extern NSString * const kAnalyticsViewMenuSharedFiles;
extern NSString * const kAnalyticsViewMenuMyFiles;
extern NSString * const kAnalyticsViewMenuSites;
extern NSString * const kAnalyticsViewMenuFavorites;
extern NSString * const kAnalyticsViewMenuSyncedContent;
extern NSString * const kAnalyticsViewMenuSearch;
extern NSString * const kAnalyticsViewMenuLocalFiles;
extern NSString * const kAnalyticsViewMenuTasks;
extern NSString * const kAnalyticsViewMenuAccounts;

// Site
extern NSString * const kAnalyticsViewSiteListingMy;
extern NSString * const kAnalyticsViewSiteListingFavorites;
extern NSString * const kAnalyticsViewSiteListingSearch;
extern NSString * const kAnalyticsViewSiteListingAll;
extern NSString * const kAnalyticsViewSiteMembers;

// Document
extern NSString * const kAnalyticsViewDocumentListing;
extern NSString * const kAnalyticsViewDocumentDetailsProperties;
extern NSString * const kAnalyticsViewDocumentDetailsPreview;
extern NSString * const kAnalyticsViewDocumentDetailsComments;
extern NSString * const kAnalyticsViewDocumentDetailsVersions;
extern NSString * const kAnalyticsViewDocumentDetailsMap;
extern NSString * const kAnalyticsViewDocumentCreateTextFile;
extern NSString * const kAnalyticsViewDocumentCreateUploadForm;
extern NSString * const kAnalyticsViewDocumentCreateUpdateForm;
extern NSString * const kAnalyticsViewDocumentGallery;

// Task
extern NSString * const kAnalyticsViewTaskListingTasksAssignedToMe;
extern NSString * const kAnalyticsViewTaskListingTasksIVeStarted;
extern NSString * const kAnalyticsViewTaskDetails;
extern NSString * const kAnalyticsViewTaskCreateType;
extern NSString * const kAnalyticsViewTaskCreateForm;

// Search
extern NSString * const kAnalyticsViewSearchFiles;
extern NSString * const kAnalyticsViewSearchFolders;
extern NSString * const kAnalyticsViewSearchPeople;
extern NSString * const kAnalyticsViewSearchSites;
extern NSString * const kAnalyticsViewSearchResultFiles;
extern NSString * const kAnalyticsViewSearchResultFolders;
extern NSString * const kAnalyticsViewSearchResultPeople;
extern NSString * const kAnalyticsViewSearchResultSites;

// Text Editor
extern NSString * const kAnalyticsViewTextEditorEditor;

// Settings
extern NSString * const kAnalyticsViewSettingsDetails;
extern NSString * const kAnalyticsViewSettingsPasscode;

// User
extern NSString * const kAnalyticsViewUserListing;
extern NSString * const kAnalyticsViewUserDetails;

// Help
extern NSString * const kAnalyticsViewHelp;

// About
extern NSString * const kAnalyticsViewAbout;

#pragma mark - Events

// Categories;
extern NSString * const kAnalyticsEventCategoryAccount;
extern NSString * const kAnalyticsEventCategorySession;
extern NSString * const kAnalyticsEventCategoryDM;
extern NSString * const kAnalyticsEventCategoryUser;
extern NSString * const kAnalyticsEventCategorySite;
extern NSString * const kAnalyticsEventCategoryBPM;
extern NSString * const kAnalyticsEventCategorySearch;
extern NSString * const kAnalyticsEventCategorySync;
extern NSString * const kAnalyticsEventCategorySettings;
extern NSString * const kAnalyticsEventCategoryDocumentProvider;

// Actions
extern NSString * const kAnalyticsEventActionCreate;
extern NSString * const kAnalyticsEventActionDelete;
extern NSString * const kAnalyticsEventActionUpdateMenu;
extern NSString * const kAnalyticsEventActionChangeAuthentication;
extern NSString * const kAnalyticsEventActionInfo;
extern NSString * const kAnalyticsEventActionSwitch;
extern NSString * const kAnalyticsEventActionQuickAction;
extern NSString * const kAnalyticsEventActionFullScreenView;
extern NSString * const kAnalyticsEventActionUpdate;
extern NSString * const kAnalyticsEventActionDownload;
extern NSString * const kAnalyticsEventActionOpen;
extern NSString * const kAnalyticsEventActionSync;
extern NSString * const kAnalyticsEventActionUnSync;
extern NSString * const kAnalyticsEventActionEmail;
extern NSString * const kAnalyticsEventActionEmailLink;
extern NSString * const kAnalyticsEventActionSendForReview;
extern NSString * const kAnalyticsEventActionComment;
extern NSString * const kAnalyticsEventActionFavorite;
extern NSString * const kAnalyticsEventActionUnfavorite;
extern NSString * const kAnalyticsEventActionLike;
extern NSString * const kAnalyticsEventActionUnlike;
extern NSString * const kAnalyticsEventActionPrint;
extern NSString * const kAnalyticsEventActionCall;
extern NSString * const kAnalyticsEventActionSkype;
extern NSString * const kAnalyticsEventActionShowInMaps;
extern NSString * const kAnalyticsEventActionMembership;
extern NSString * const kAnalyticsEventActionReassign;
extern NSString * const kAnalyticsEventActionComplete;
extern NSString * const kAnalyticsEventActionRunSimple;
extern NSString * const kAnalyticsEventActionRun;
extern NSString * const kAnalyticsEventActionHistory;
extern NSString * const kAnalyticsEventActionAnalytics;
extern NSString * const kAnalyticsEventActionClearData;

// Labels
extern NSString * const kAnalyticsEventLabelOnPremise;
extern NSString * const kAnalyticsEventLabelOnPremiseSAML;
extern NSString * const kAnalyticsEventLabelBasic;
extern NSString * const kAnalyticsEventLabelSAML;
extern NSString * const kAnalyticsEventLabelCloud;
extern NSString * const kAnalyticsEventLabelNetwork;
extern NSString * const kAnalyticsEventLabelProfile;
extern NSString * const kAnalyticsEventLabelDocumentMimetype;
extern NSString * const kAnalyticsEventLabelFolder;
extern NSString * const kAnalyticsEventLabelTakePhotoOrVideo;
extern NSString * const kAnalyticsEventLabelRecordAudio;
extern NSString * const kAnalyticsEventLabelPhone;
extern NSString * const kAnalyticsEventLabelMobile;
extern NSString * const kAnalyticsEventLabelEnterprise;
extern NSString * const kAnalyticsEventLabelSMS;
extern NSString * const kAnalyticsEventLabelChat;
extern NSString * const kAnalyticsEventLabelCall;
extern NSString * const kAnalyticsEventLabelVideoCall;
extern NSString * const kAnalyticsEventLabelUser;
extern NSString * const kAnalyticsEventLabelCompany;
extern NSString * const kAnalyticsEventLabelJoin;
extern NSString * const kAnalyticsEventLabelLeave;
extern NSString * const kAnalyticsEventLabelCancel;
extern NSString * const kAnalyticsEventLabelEnable;
extern NSString * const kAnalyticsEventLabelDisable;
extern NSString * const kAnalyticsEventLabelFiles;
extern NSString * const kAnalyticsEventLabelFolders;
extern NSString * const kAnalyticsEventLabelSites;
extern NSString * const kAnalyticsEventLabelPeople;
extern NSString * const kAnalyticsEventLabelSyncedFolders;
extern NSString * const kAnalyticsEventLabelSyncedFiles;
extern NSString * const kAnalyticsEventLabelDisableConfig;
extern NSString * const kAnalyticsEventLabelPartial;
extern NSString * const kAnalyticsEventLabelFull;

#pragma mark - Custom Metrics

// These values MUST match the index values in the Google Analytics config (Admin -> Custom Definitions -> Custom Metrics)
typedef NS_ENUM(NSUInteger, AnalyticsMetric)
{
    AnalyticsMetricNone                = 0,
    AnalyticsMetricAccounts            = 1,
    AnalyticsMetricDataProtection      = 2,
    AnalyticsMetricPasscode            = 3,
    AnalyticsMetricLocalFiles          = 4,
    AnalyticsMetricSyncedFolders       = 5,
    AnalyticsMetricSyncedFiles         = 6,
    AnalyticsMetricSyncedFileSize      = 7,
    AnalyticsMetricSessionCreated      = 8,
    AnalyticsMetricSyncStarted         = 9,
    AnalyticsMetricFileSize            = 10,
    AnalyticsMetricProfilesCount       = 11,
    AnalyticsMetricFullContentSearch   = 12,
    AnalyticsMetricSyncOnCellular      = 13
};

// These values MUST match the index values in the Google Analytics config (Admin -> Custom Definitions -> Custom Dimensions)
typedef NS_ENUM(NSUInteger, AnalyticsDimension)
{
    AnalyticsDimensionServerType        = 1,
    AnalyticsDimensionServerVersion     = 2,
    AnalyticsDimensionServerEdition     = 3,
    AnalyticsDimensionAccounts          = 4,
    AnalyticsDimensionProfiles          = 5
};

//
//  AnalyticsConstants.h
//  AlfrescoApp
//
//  Created by Alexandru Posmangiu on 05/02/16.
//  Copyright © 2016 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Screens

// Acount
extern NSString * const kAnalyticsViewAccountCreateTypePicker;  // AccountTypeSelectionViewController
extern NSString * const kAnalyticsViewAccountCreateCredentials; // NewAccountViewController
extern NSString * const kAnalyticsViewAccountCreateDiagnostics; // ConnectionDiagnosticViewController
extern NSString * const kAnalyticsViewAccountEdit;              // AccountInfoViewController
extern NSString * const kAnalyticsViewAccountEditActiveProfile; // ProfileSelectionViewController
extern NSString * const kAnalyticsViewAccountEditEditMainMenu;  // MainMenuReorderViewController
extern NSString * const kAnalyticsViewAccountEditAccountDetails;// AccountInfoDetailsViewController

// Menu
extern NSString * const kAnalyticsViewMenuActivities;       // ActivitiesViewController
extern NSString * const kAnalyticsViewMenuRepository;       // FileFolderCollectionViewController
extern NSString * const kAnalyticsViewMenuSharedFiles;      // FileFolderCollectionViewController
extern NSString * const kAnalyticsViewMenuMyFiles;          // FileFolderCollectionViewController
extern NSString * const kAnalyticsViewMenuSites;            // SitesViewController
extern NSString * const kAnalyticsViewMenuFavorites;        // SyncViewController
extern NSString * const kAnalyticsViewMenuSyncedContent;    // SyncViewController
extern NSString * const kAnalyticsViewMenuSearch;           // SearchViewController
extern NSString * const kAnalyticsViewMenuLocalFiles;       // DownloadsViewController
extern NSString * const kAnalyticsViewMenuTasks;            // TaskViewController
extern NSString * const kAnalyticsViewMenuAccounts;         // AccountsViewController

// Site
extern NSString * const kAnalyticsViewSiteListingMy;        // SitesViewController
extern NSString * const kAnalyticsViewSiteListingFavorites; // SitesViewController
extern NSString * const kAnalyticsViewSiteListingSearch;    // SitesViewController
extern NSString * const kAnalyticsViewSiteListingAll;       //
extern NSString * const kAnalyticsViewSiteMembers;          // SiteMembersViewController

// Document
extern NSString * const kAnalyticsViewDocumentListing;              // FileFolderCollectionViewController
extern NSString * const kAnalyticsViewDocumentDetailsProperties;    // DocumentPreviewViewController
extern NSString * const kAnalyticsViewDocumentDetailsPreview;       // DocumentPreviewViewController
extern NSString * const kAnalyticsViewDocumentDetailsComments;      // DocumentPreviewViewController
extern NSString * const kAnalyticsViewDocumentDetailsVersions;      // DocumentPreviewViewController
extern NSString * const kAnalyticsViewDocumentDetailsMap;           // DocumentPreviewViewController
extern NSString * const kAnalyticsViewDocumentCreateTextFile;       // TextFileViewController
extern NSString * const kAnalyticsViewDocumentCreateUploadForm;     // UploadFormViewController
extern NSString * const kAnalyticsViewDocumentCreateUpdateForm;     // NewVersionViewController
extern NSString * const kAnalyticsViewDocumentGallery;              // FileFolderCollectionViewController

// Task
extern NSString * const kAnalyticsViewTaskListingTasksAssignedToMe; // TaskViewController
extern NSString * const kAnalyticsViewTaskListingTasksIVeStarted;   // TaskViewController
extern NSString * const kAnalyticsViewTaskDetails;                  // TaskDetailsViewController
extern NSString * const kAnalyticsViewTaskCreateType;               // TaskTypeViewController
extern NSString * const kAnalyticsViewTaskCreateForm;               // CreateTaskViewController

// Search
extern NSString * const kAnalyticsViewSearchFiles;          // SearchViewController
extern NSString * const kAnalyticsViewSearchFolders;        // SearchViewController
extern NSString * const kAnalyticsViewSearchPeople;         // SearchViewController
extern NSString * const kAnalyticsViewSearchSites;          // SearchViewController
extern NSString * const kAnalyticsViewSearchResultFiles;    // SearchResultsTableViewController
extern NSString * const kAnalyticsViewSearchResultFolders;  // SearchResultsTableViewController
extern NSString * const kAnalyticsViewSearchResultPeople;   // SearchResultsTableViewController
extern NSString * const kAnalyticsViewSearchResultSites;    // SitesTableListViewController

// Text Editor
extern NSString * const kAnalyticsViewTextEditorEditor; // TextFileViewController

// Settings
extern NSString * const kAnalyticsViewSettingsDetails;      // SettingsViewController
//extern NSString * const kAnalyticsViewSettingsPasscode;   // 2.3

// User
extern NSString * const kAnalyticsViewUserListing;  // PeoplePickerViewController
extern NSString * const kAnalyticsViewUserDetails;  // PersonProfileViewController

// Help
extern NSString * const kAnalyticsViewHelp;     // WebBrowserViewController

// About
extern NSString * const kAnalyticsViewAbout;    // AboutViewController

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
extern NSString * const kAnalyticsEventActionInfo;
extern NSString * const kAnalyticsEventActionSwitch;
extern NSString * const kAnalyticsEventActionQuickAction;
extern NSString * const kAnalyticsEventActionFullScreenView;
extern NSString * const kAnalyticsEventActionUpdate;
extern NSString * const kAnalyticsEventActionDownload;
extern NSString * const kAnalyticsEventActionOpen;
extern NSString * const kAnalyticsEventActionSync; // 2.3
extern NSString * const kAnalyticsEventActionShare;
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
extern NSString * const kAnalyticsEventActionAnalytics;
extern NSString * const kAnalyticsEventActionClearData;

// Labels
extern NSString * const kAnalyticsEventLabelOnPremise;
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

typedef NS_ENUM(NSUInteger, AnalyticsMetric)
{
    AnalyticsMetricNone                = 0,
    AnalyticsMetricAccounts            = 1, // Number of accounts. -> 1..n
    AnalyticsMetricDataProtection      = 2, // Is data protection enabled? -> 1|0
    AnalyticsMetricPasscode            = 3, // Is passcode enabled? -> 1|0
    AnalyticsMetricLocalFiles          = 4, // The number of local files. -> 1..n
    AnalyticsMetricSyncedFolders       = 5,
    AnalyticsMetricSyncedFiles         = 6,
    AnalyticsMetricSyncedFileSize      = 7,
    AnalyticsMetricSessionCreated      = 8, // 1
    AnalyticsMetricSyncStarted         = 9,
    AnalyticsMetricFileSize            = 10,
    AnalyticsMetricProfilesCounts      = 11,// The number of profiles. -> 1..n
    AnalyticsMetricFullContentSearch   = 12,
    AnalyticsMetricSyncOnCellular      = 13
};

typedef NS_ENUM(NSUInteger, AnalyticsDimension)
{
    AnalyticsDimensionServerType        = 1,
    AnalyticsDimensionServerVersion     = 2,
    AnalyticsDimensionServerEdition     = 3,
//    AnalyticsDimensionSyncFileCount     = 4,
//    AnalyticsDimensionAccountCount      = 5
};

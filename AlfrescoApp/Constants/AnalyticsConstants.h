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
extern NSString * const kAnalyticsViewAccountCreateTypePicker;
extern NSString * const kAnalyticsViewAccountCreateCredentials;
extern NSString * const kAnalyticsViewAccountCreateDiagnostics;
extern NSString * const kAnalyticsViewAccountEdit;
extern NSString * const kAnalyticsViewAccountEditActiveProfile;
extern NSString * const kAnalyticsViewAccountEditEditMainMenu;
extern NSString * const kAnalyticsViewAccountEditAccountDetails;

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
extern NSString * const kAnalyticsViewSearchSited;
extern NSString * const kAnalyticsViewSearchResultFiles;
extern NSString * const kAnalyticsViewSearchResultFolders;
extern NSString * const kAnalyticsViewSearchResultPeople;
extern NSString * const kAnalyticsViewSearchResultSites;

// Text Editor
extern NSString * const kAnalyticsViewTextEditorEditor;

// Settings
extern NSString * const kAnalyticsViewSettingsDetails;
//extern NSString * const kAnalyticsViewSettingsPasscode; // 2.3

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
extern NSString * const kAnalyticsEventActionSwitch;
extern NSString * const kAnalyticsEventActionUpdateContent;
extern NSString * const kAnalyticsEventActionDownload;
extern NSString * const kAnalyticsEventActionOpen;
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
extern NSString * const kAnalyticsEventActionMembers;
extern NSString * const kAnalyticsEventActionReassign;
extern NSString * const kAnalyticsEventActionComplete;
extern NSString * const kAnalyticsEventActionRunSimple;
extern NSString * const kAnalyticsEventActionDataProtection;
extern NSString * const kAnalyticsEventActionAnalytics;
extern NSString * const kAnalyticsEventActionFullContentSearch;
extern NSString * const kAnalyticsEventActionSyncMobile;
extern NSString * const kAnalyticsEventActionClearData;
extern NSString * const kAnalyticsEventActionCreateFile;
extern NSString * const kAnalyticsEventActionOpenFile;
extern NSString * const kAnalyticsEventActionUpdateFile;

// Labels
extern NSString * const kAnalyticsEventLabelOnPremise;
extern NSString * const kAnalyticsEventLabelCloud;
extern NSString * const kAnalyticsEventLabelNetwork;
extern NSString * const kAnalyticsEventLabelProfile;
extern NSString * const kAnalyticsEventLabelDocumentMimetype;
extern NSString * const kAnalyticsEventLabelFolder;
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
extern NSString * const kAnalyticsEventLabelRequest;
extern NSString * const kAnalyticsEventLabelCancel;
extern NSString * const kAnalyticsEventLabelEnable;
extern NSString * const kAnalyticsEventLabelDisable;
extern NSString * const kAnalyticsEventLabelList;
extern NSString * const kAnalyticsEventLabelTaskType;
extern NSString * const kAnalyticsEventLabelFiles;
extern NSString * const kAnalyticsEventLabelFolders;
extern NSString * const kAnalyticsEventLabelSites;
extern NSString * const kAnalyticsEventLabelPeople;
extern NSString * const kAnalyticsEventLabelSyncedFiles;
extern NSString * const kAnalyticsEventLabelPartial;
extern NSString * const kAnalyticsEventLabelFull;

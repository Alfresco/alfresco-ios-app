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

#import "SharedConstants.h"

// Shared Group
NSString * const kSharedAppGroupIdentifier = @"group.com.alfresco.mobile";

// App Configuration
NSString * const kAppConfigurationFileLocationOnServer = @"Mobile/configuration.json";
NSString * const kAppConfigurationActivitiesKey = @"com.alfresco.activities";
NSString * const kAppConfigurationFavoritesKey = @"com.alfresco.favorites";
NSString * const kAppConfigurationLocalFilesKey = @"com.alfresco.localFiles";
NSString * const kAppConfigurationNotificationsKey = @"com.alfresco.notifications";
NSString * const kAppConfigurationRepositoryKey = @"com.alfresco.repository";
NSString * const kAppConfigurationSearchKey = @"com.alfresco.search";
NSString * const kAppConfigurationSitesKey = @"com.alfresco.sites";
NSString * const kAppConfigurationTasksKey = @"com.alfresco.tasks";
NSString * const kAppConfigurationMyFilesKey = @"com.alfresco.repository.userhome";
NSString * const kAppConfigurationSharedFilesKey = @"com.alfresco.repository.shared";

NSString * const kPinKey = @"PinCodeKey";
NSString * const kRemainingAttemptsKey = @"RemainingAttemptsKey";

NSString * const kSettingsSecurityUsePasscodeLockIdentifier = @"SettingsSecurityUsePasscodeLockIdentifier";

NSString * const kAlfrescoMobileGroup = @"group.com.alfresco.mobile";
NSString * const kShouldResetEntireAppKey = @"ShouldResetEntireApp";
NSString * const kIsAppFirstLaunch = @"IsAppFirstLaunch";

NSString * const kHasSyncedContentMigrationOccurred = @"hasSyncedContentMigrationOccurred";

// View Types
NSString * const kAlfrescoConfigViewTypeActivities = @"org.alfresco.client.view.activities";
NSString * const kAlfrescoConfigViewTypeRepository = @"org.alfresco.client.view.repository";
NSString * const kAlfrescoConfigViewTypeSiteBrowser = @"org.alfresco.client.view.site-browser";
NSString * const kAlfrescoConfigViewTypeTasks = @"org.alfresco.client.view.tasks";
NSString * const kAlfrescoConfigViewTypeFavourites = @"org.alfresco.client.view.favorites";
NSString * const kAlfrescoConfigViewTypeSync = @"org.alfresco.client.view.sync";
NSString * const kAlfrescoConfigViewTypeLocal = @"org.alfresco.client.view.local";
NSString * const kAlfrescoConfigViewTypePersonProfile = @"org.alfresco.client.view.person-profile";
NSString * const kAlfrescoConfigViewTypePeople = @"org.alfresco.client.view.people";
NSString * const kAlfrescoConfigViewTypeGallery = @"org.alfresco.client.view.preview-carousel";
NSString * const kAlfrescoConfigViewTypeDocumentDetails = @"org.alfresco.client.view.document-details";
NSString * const kAlfrescoConfigViewTypeSite = @"org.alfresco.client.view.sites";
NSString * const kAlfrescoConfigViewTypeSearchRepository = @"org.alfresco.client.view.repository-search";
NSString * const kAlfrescoConfigViewTypeSearch = @"org.alfresco.client.view.search";
NSString * const kAlfrescoConfigViewTypeSearchAdvanced = @"org.alfresco.client.view.search-advanced";
// View Parameter Keys
NSString * const kAlfrescoConfigViewParameterSiteShortNameKey = @"siteShortName";
NSString * const kAlfrescoConfigViewParameterPathKey = @"path";
NSString * const kAlfrescoConfigViewParameterNodeRefKey = @"nodeRef";
NSString * const kAlfrescoConfigViewParameterShowKey = @"show";
NSString * const kAlfrescoConfigViewParameterTypeKey = @"type";
NSString * const kAlfrescoConfigViewParameterKeywordsKey = @"keywords";
NSString * const kAlfrescoConfigViewParameterIsExactKey = @"isExact";
NSString * const kAlfrescoConfigViewParameterFullTextKey = @"fullText";
NSString * const kAlfrescoConfigViewParameterSearchFolderOnlyKey = @"searchFolderOnly";
NSString * const kAlfrescoConfigViewParameterStatementKey = @"statement";
NSString * const kAlfrescoConfigViewParameterUsernameKey = @"userName";
NSString * const kAlfrescoConfigViewParameterFolderTypeKey = @"folderTypeId";
NSString * const kAlfrescoConfigViewParameterTaskFiltersKey = @"filters";
NSString * const kAlfrescoConfigViewParameterTaskFiltersStatusKey = @"status";
NSString * const kAlfrescoConfigViewParameterTaskFiltersDueKey = @"due";
NSString * const kAlfrescoConfigViewParameterTaskFiltersPriorityKey = @"priority";
NSString * const kAlfrescoConfigViewParameterTaskFiltersAssigneeKey = @"assignee";
NSString * const kAlfrescoConfigViewParameterFavoritesFiltersKey = @"filters";
NSString * const kAlfrescoConfigViewParameterFavoritesFiltersModeKey = @"mode";
NSString * const kAlfrescoConfigViewParameterPaginationKey = @"pagination";
NSString * const kAlfrescoConfigViewParameterPaginationMaxItemsKey = @"maxItems";
NSString * const kAlfrescoConfigViewParameterPaginationSkipCountKey = @"skipCount";
// View Parameter Values
NSString * const kAlfrescoConfigViewParameterMySitesValue = @"my";
NSString * const kAlfrescoConfigViewParameterFavouriteSitesValue = @"favorites";
NSString * const kAlfrescoConfigViewParameterAllSitesValue = @"all";
NSString * const kAlfrescoConfigViewParameterAdvancedSearchPerson = @"person";
NSString * const kAlfrescoConfigViewParameterAdvancedSearchDocument = @"document";
NSString * const kAlfrescoConfigViewParameterAdvancedSearchFolder = @"folder";
NSString * const kAlfrescoConfigViewParameterFolderTypeMyFiles = @"userhome";
NSString * const kAlfrescoConfigViewParameterFolderTypeShared = @"shared";
NSString * const kAlfrescoConfigViewParameterTaskFiltersStatusAny = @"any";
NSString * const kAlfrescoConfigViewParameterTaskFiltersStatusActive = @"active";
NSString * const kAlfrescoConfigViewParameterTaskFiltersStatusComplete = @"complete";
NSString * const kAlfrescoConfigViewParameterTaskFiltersDueToday = @"today";
NSString * const kAlfrescoConfigViewParameterTaskFiltersDueTomorrow = @"tomorrow";
NSString * const kAlfrescoConfigViewParameterTaskFiltersDueWeek = @"week";
NSString * const kAlfrescoConfigViewParameterTaskFiltersDueOverdue = @"overdue";
NSString * const kAlfrescoConfigViewParameterTaskFiltersDueNone = @"none";
NSString * const kAlfrescoConfigViewParameterTaskFiltersPriorityLow = @"low";
NSString * const kAlfrescoConfigViewParameterTaskFiltersPriorityMedium = @"medium";
NSString * const kAlfrescoConfigViewParameterTaskFiltersPriorityHigh = @"high";
NSString * const kAlfrescoConfigViewParameterTaskFiltersAssigneeMe = @"me";
NSString * const kAlfrescoConfigViewParameterTaskFiltersAssigneeUnassigned = @"unassigned";
NSString * const kAlfrescoConfigViewParameterTaskFiltersAssigneeAll = @"all";
NSString * const kAlfrescoConfigViewParameterTaskFiltersAssigneeNone = @"none";
NSString * const kAlfrescoConfigViewParameterFavoritesFiltersAll = @"all";
NSString * const kAlfrescoConfigViewParameterFavoritesFiltersFolders = @"folders";
NSString * const kAlfrescoConfigViewParameterFavoritesFiltersFiles = @"files";

// Realm sync exceptions
NSString * const kFailedToCreateRealmDatabase = @"FailedToCreateRealmDatabase";
NSString * const kRealmSyncErrorKey = @"RealmSyncErrorKey";

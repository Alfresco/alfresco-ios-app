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

// Shared Group
extern NSString * const kSharedAppGroupIdentifier;

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

extern NSString * const kPinKey;
extern NSString * const kRemainingAttemptsKey;

extern NSString * const kSettingsSecurityUsePasscodeLockIdentifier;

extern NSString * const kAlfrescoMobileGroup;
extern NSString * const kShouldResetEntireAppKey;
extern NSString * const kIsAppFirstLaunch;

extern NSString * const kHasSyncedContentMigrationOccurred;

/// View Types
extern NSString * const kAlfrescoConfigViewTypeActivities;
extern NSString * const kAlfrescoConfigViewTypeRepository;
extern NSString * const kAlfrescoConfigViewTypeSiteBrowser;
extern NSString * const kAlfrescoConfigViewTypeTasks;
extern NSString * const kAlfrescoConfigViewTypeFavourites;
extern NSString * const kAlfrescoConfigViewTypeSync;
extern NSString * const kAlfrescoConfigViewTypeLocal;
extern NSString * const kAlfrescoConfigViewTypePersonProfile;
extern NSString * const kAlfrescoConfigViewTypePeople;
extern NSString * const kAlfrescoConfigViewTypeGallery;
extern NSString * const kAlfrescoConfigViewTypeDocumentDetails;
extern NSString * const kAlfrescoConfigViewTypeSite;
extern NSString * const kAlfrescoConfigViewTypeSearchRepository;
extern NSString * const kAlfrescoConfigViewTypeSearch;
extern NSString * const kAlfrescoConfigViewTypeSearchAdvanced;
// View Parameter Keys
extern NSString * const kAlfrescoConfigViewParameterSiteShortNameKey;
extern NSString * const kAlfrescoConfigViewParameterPathKey;
extern NSString * const kAlfrescoConfigViewParameterNodeRefKey;
extern NSString * const kAlfrescoConfigViewParameterShowKey;
extern NSString * const kAlfrescoConfigViewParameterTypeKey;
extern NSString * const kAlfrescoConfigViewParameterKeywordsKey;
extern NSString * const kAlfrescoConfigViewParameterIsExactKey;
extern NSString * const kAlfrescoConfigViewParameterFullTextKey;
extern NSString * const kAlfrescoConfigViewParameterSearchFolderOnlyKey;
extern NSString * const kAlfrescoConfigViewParameterStatementKey;
extern NSString * const kAlfrescoConfigViewParameterUsernameKey;
extern NSString * const kAlfrescoConfigViewParameterFolderTypeKey;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersKey;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersStatusKey;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersDueKey;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersPriorityKey;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersAssigneeKey;
extern NSString * const kAlfrescoConfigViewParameterFavoritesFiltersKey;
extern NSString * const kAlfrescoConfigViewParameterFavoritesFiltersModeKey;
extern NSString * const kAlfrescoConfigViewParameterPaginationKey;
extern NSString * const kAlfrescoConfigViewParameterPaginationMaxItemsKey;
extern NSString * const kAlfrescoConfigViewParameterPaginationSkipCountKey;

// View Parameter Values
extern NSString * const kAlfrescoConfigViewParameterMySitesValue;
extern NSString * const kAlfrescoConfigViewParameterFavouriteSitesValue;
extern NSString * const kAlfrescoConfigViewParameterAllSitesValue;
extern NSString * const kAlfrescoConfigViewParameterAdvancedSearchPerson;
extern NSString * const kAlfrescoConfigViewParameterAdvancedSearchDocument;
extern NSString * const kAlfrescoConfigViewParameterAdvancedSearchFolder;
extern NSString * const kAlfrescoConfigViewParameterFolderTypeMyFiles;
extern NSString * const kAlfrescoConfigViewParameterFolderTypeShared;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersStatusAny;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersStatusActive;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersStatusComplete;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersDueToday;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersDueTomorrow;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersDueWeek;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersDueOverdue;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersDueNone;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersPriorityLow;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersPriorityMedium;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersPriorityHigh;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersAssigneeMe;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersAssigneeUnassigned;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersAssigneeAll;
extern NSString * const kAlfrescoConfigViewParameterTaskFiltersAssigneeNone;
extern NSString * const kAlfrescoConfigViewParameterFavoritesFiltersAll;
extern NSString * const kAlfrescoConfigViewParameterFavoritesFiltersFolders;
extern NSString * const kAlfrescoConfigViewParameterFavoritesFiltersFiles;

// Realm sync exceptions
extern NSString * const kFailedToCreateRealmDatabase;
extern NSString * const kRealmSyncErrorKey;

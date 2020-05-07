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

#import "RepositoryCollectionViewDataSource.h"

@interface FolderCollectionViewDataSource : RepositoryCollectionViewDataSource

- (instancetype)initWithFolder:(AlfrescoFolder *)folder folderDisplayName:(NSString *)folderDisplayName folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext;

- (instancetype)initWithFolderPath:(NSString *)folderPath folderDisplayName:(NSString *)folderDisplayName folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext;

- (instancetype)initWithCustomFolderType:(CustomFolderServiceFolderType)folderType folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext;

@end

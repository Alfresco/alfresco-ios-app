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
#import "AlfrescoNode+Sync.h"
#import "AlfrescoNode+Networking.h"
#import "FileFolderCollectionViewCell.h"

@interface RepositoryCollectionViewDataSource ()

@property (nonatomic, strong) AlfrescoNode *parentNode;
@property (nonatomic, strong) NSMutableArray *dataSourceCollection;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) NSMutableDictionary *nodesPermissions;

- (void)setupWithParentNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate;

- (void)retrieveContentsOfParentNode;
- (void)retrievePermissionsForNode:(AlfrescoNode *)node;
- (void)retrieveAndSetPermissionsOfCurrentFolder;
- (void)reloadCollectionViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error;

@end

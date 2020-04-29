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

#import "AFPServerEnumerator.h"
#import "AFPItemIdentifier.h"
#import "AFPAccountManager.h"
#import "AFPDataManager.h"
#import "AFPItem.h"
#import "AFPPage.h"
#import "CustomFolderService.h"

@interface AFPServerEnumerator()

@property (nonatomic, strong) NSFileProviderItemIdentifier itemIdentifier;
@property (nonatomic, strong) id<NSFileProviderEnumerationObserver> observer;
@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) CustomFolderService *customFolderService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AFPAccountManager *accountManager;
@property (atomic) BOOL networkOperationsComplete;
@property (nonatomic, strong) NSMutableArray *childrenIdentifiers;

- (void)setupSessionWithCompletionBlock:(void (^)(id<AlfrescoSession> session))completionBlock;
- (void)handleEnumeratedCustomFolder:(AlfrescoNode *)node skipCount:(int)skipCount error:(NSError *)error;
- (void)enumerateItemsInFolder:(AlfrescoFolder *)folder skipCount:(int)skipCount;
- (void)handleEnumeratedFolderWithPagingResult:(AlfrescoPagingResult *)pagingResult skipCount:(int)skipCount error:(NSError *)error;

@end

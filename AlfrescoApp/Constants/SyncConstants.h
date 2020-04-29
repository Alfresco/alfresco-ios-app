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

extern NSString * const kLastDownloadedDateKey;
extern NSString * const kSyncNodeKey;
extern NSString * const kSyncContentPathKey;
extern NSString * const kSyncReloadContentKey;

extern NSString * const kDocumentsRemovedFromSyncOnServerWithLocalChanges;
extern NSString * const kDocumentsDeletedOnServerWithLocalChanges;

static NSString * const kAlfrescoNodeVersionSeriesIdKey = @"cmis:versionSeriesId";
static NSString * const kDocumentsToBeDeletedLocallyAfterUpload = @"toBeDeletedLocallyAfterUpload";

static NSUInteger const kSyncMaxConcurrentOperations = 2;

static NSUInteger const kSyncOperationCancelledErrorCode = 1800;

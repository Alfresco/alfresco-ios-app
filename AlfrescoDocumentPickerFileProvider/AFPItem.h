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

#import <FileProvider/FileProvider.h>
@class UserAccount;
@class AFPItemMetadata;
@class RealmSyncNodeInfo;

@interface AFPItem : NSObject <NSFileProviderItem>

@property (nonatomic, readonly, copy) NSString *itemIdentifier;
@property (nonatomic, readonly, copy) NSString *parentItemIdentifier;
@property (nonatomic, readonly, copy) NSString *filename;
@property (nonatomic, readonly, copy) NSDate *creationDate;
@property (nonatomic, readonly, copy) NSDate *contentModificationDate;
@property (nonatomic, readonly, copy) NSNumber *documentSize;
@property (nonatomic, readonly, copy) NSString *typeIdentifier;
@property(nonatomic, readonly, getter=isDownloaded) BOOL downloaded;
@property(nonatomic, readonly, getter=isMostRecentVersionDownloaded) BOOL mostRecentVersionDownloaded;
@property(nonatomic, copy) NSData *tagData;

- (instancetype)initWithRootContainterItem;
- (instancetype)initWithUserAccount:(UserAccount *)account;
- (instancetype)initWithItemMetadata:(AFPItemMetadata *)accountInfo;
- (instancetype)initWithLocalFilesPath:(NSString *)path;
- (instancetype)initWithSyncedNode:(RealmSyncNodeInfo *)node parentItemIdentifier:(NSFileProviderItemIdentifier)parentItemIdentifier;
- (instancetype)initWithImportedDocumentAtURL:(NSURL *)fileURL resourceValues:(NSDictionary *)resourceValues parentItemIdentifier:(NSFileProviderItemIdentifier)parentItemIdentifier;
- (NSURL *)fileURL;

@end

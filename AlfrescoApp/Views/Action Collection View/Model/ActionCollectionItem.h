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
  
extern NSString * const kActionCollectionItemUpdateNotification;
extern NSString * const kActionCollectionItemUpdateItemTitleKey;
extern NSString * const kActionCollectionItemUpdateItemImageKey;
extern NSString * const kActionCollectionItemUpdateItemIndentifier;

extern NSString * const kActionCollectionIdentifierEmail;
extern NSString * const kActionCollectionIdentifierOpenIn;
extern NSString * const kActionCollectionIdentifierLike;
extern NSString * const kActionCollectionIdentifierUnlike;
extern NSString * const kActionCollectionIdentifierFavourite;
extern NSString * const kActionCollectionIdentifierUnfavourite;
extern NSString * const kActionCollectionIdentifierComment;
extern NSString * const kActionCollectionIdentifierEdit;
extern NSString * const kActionCollectionIdentifierDownload;
extern NSString * const kActionCollectionIdentifierEmailAsLink;
extern NSString * const kActionCollectionIdentifierPrint;
extern NSString * const kActionCollectionIdentifierDelete;
extern NSString * const kActionCollectionIdentifierRename;
extern NSString * const kActionCollectionIdentifierCreateSubfolder;
extern NSString * const kActionCollectionIdentifierUploadDocument;
extern NSString * const kActionCollectionIdentifierSendForReview;
extern NSString * const kActionCollectionIdentifierUploadNewVersion;
extern NSString * const kActionCollectionIdentifierSync;
extern NSString * const kActionCollectionIdentifierUnsync;

@interface ActionCollectionItem : NSObject

@property (nonatomic, strong, readonly) NSString *itemIdentifier;
@property (nonatomic, strong, readonly) UIImage *itemImage;
@property (nonatomic, strong, readonly) NSString *itemTitle;
@property (nonatomic, strong, readonly) UIImage *itemImageHighlightedImage;
@property (nonatomic, strong, readonly) UIColor *itemTitleHighlightedColor;
@property (nonatomic, strong, readonly) NSString *accessibilityIdentifier;

+ (ActionCollectionItem *)emailItem;
+ (ActionCollectionItem *)emailAsLinkItem;
+ (ActionCollectionItem *)openInItem;
+ (ActionCollectionItem *)likeItem;
+ (ActionCollectionItem *)favouriteItem;
+ (ActionCollectionItem *)commentItem;
+ (ActionCollectionItem *)editItem;
+ (ActionCollectionItem *)downloadItem;
+ (ActionCollectionItem *)printItem;
+ (ActionCollectionItem *)deleteItem;
+ (ActionCollectionItem *)renameItem;
+ (ActionCollectionItem *)subfolderItem;
+ (ActionCollectionItem *)uploadItem;
+ (ActionCollectionItem *)sendForReview;
+ (ActionCollectionItem *)uploadNewVersion;
+ (ActionCollectionItem *)syncItem;
+ (ActionCollectionItem *)unsyncItem;
- (instancetype)initWithImage:(UIImage *)itemImage title:(NSString *)itemTitle identifier:(NSString *)itemIdentifier;

@end

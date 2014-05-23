//
//  ActionCollectionItem.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

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

@interface ActionCollectionItem : NSObject

@property (nonatomic, strong, readonly) NSString *itemIdentifier;
@property (nonatomic, strong, readonly) UIImage *itemImage;
@property (nonatomic, strong, readonly) NSString *itemTitle;
@property (nonatomic, strong, readonly) UIImage *itemImageHighlightedImage;
@property (nonatomic, strong, readonly) UIColor *itemTitleHighlightedColor;

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
- (instancetype)initWithImage:(UIImage *)itemImage title:(NSString *)itemTitle identifier:(NSString *)itemIdentifier;

@end

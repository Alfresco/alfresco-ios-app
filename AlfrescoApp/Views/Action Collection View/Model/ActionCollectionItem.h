//
//  ActionCollectionItem.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

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
extern NSString * const kActionCollectionIdentifierDownload;
extern NSString * const kActionCollectionIdentifierEmailAsLink;
extern NSString * const kActionCollectionIdentifierPrint;

@interface ActionCollectionItem : NSObject

@property (nonatomic, strong, readonly) NSString *itemIdentifier;
@property (nonatomic, strong, readonly) UIImage *itemImage;
@property (nonatomic, strong, readonly) NSString *itemTitle;

+ (instancetype)emailItem;
+ (instancetype)emailAsLinkItem;
+ (instancetype)openInItem;
+ (instancetype)likeItem;
+ (instancetype)favouriteItem;
+ (instancetype)commentItem;
+ (instancetype)downloadItem;
+ (instancetype)printItem;
- (instancetype)initWithImage:(UIImage *)itemImage title:(NSString *)itemTitle identifier:(NSString *)itemIdentifier;

@end

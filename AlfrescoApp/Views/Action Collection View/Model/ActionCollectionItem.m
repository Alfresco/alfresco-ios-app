//
//  ActionCollectionItem.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActionCollectionItem.h"

NSString * const kActionCollectionItemUpdateNotification = @"ActionCollectionItemUpdateNotification";
NSString * const kActionCollectionItemUpdateItemTitleKey = @"ActionCollectionItemUpdateItemTitleKey";
NSString * const kActionCollectionItemUpdateItemImageKey = @"ActionCollectionItemUpdateItemImageKey";
NSString * const kActionCollectionItemUpdateItemIndentifier = @"ActionCollectionItemUpdateItemIndentifier";

NSString * const kActionCollectionIdentifierEmail = @"ActionCollectionIdentifierEmail";
NSString * const kActionCollectionIdentifierOpenIn = @"ActionCollectionIdentifierOpenIn";
NSString * const kActionCollectionIdentifierLike = @"ActionCollectionIdentifierLike";
NSString * const kActionCollectionIdentifierUnlike = @"ActionCollectionIdentifierUnlike";
NSString * const kActionCollectionIdentifierFavourite = @"ActionCollectionIdentifierFavourite";
NSString * const kActionCollectionIdentifierUnfavourite = @"ActionCollectionIdentifierUnfavourite";
NSString * const kActionCollectionIdentifierComment = @"ActionCollectionIdentifierComment";
NSString * const kActionCollectionIdentifierEdit = @"ActionCollectionIdentifierEdit";
NSString * const kActionCollectionIdentifierDownload = @"ActionCollectionIdentifierDownload";
NSString * const kActionCollectionIdentifierEmailAsLink = @"ActionCollectionIdentifierEmailAsLink";
NSString * const kActionCollectionIdentifierPrint = @"ActionCollectionIdentifierPrint";
NSString * const kActionCollectionIdentifierDelete = @"ActionCollectionIdentifierDelete";
NSString * const kActionCollectionIdentifierRename = @"ActionCollectionIdentifierRename";
NSString * const kActionCollectionIdentifierCreateSubfolder = @"ActionCollectionIdentifierCreateSubfolder";
NSString * const kActionCollectionIdentifierUploadDocument = @"ActionCollectionIdentifierUploadDocument";
NSString * const kActionCollectionIdentifierSendForReview = @"ActionCollectionIdentifierSendForReview";
NSString * const kActionCollectionIdentifierUploadNewVersion = @"ActionCollectionIdentifierUploadNewVersion";

@interface ActionCollectionItem ()

@property (nonatomic, strong, readwrite) NSString *itemIdentifier;
@property (nonatomic, strong, readwrite) UIImage *itemImage;
@property (nonatomic, strong, readwrite) NSString *itemTitle;
@property (nonatomic, strong, readwrite) UIImage *itemImageHighlightedImage;
@property (nonatomic, strong, readwrite) UIColor *itemTitleHighlightedColor;
@end

@implementation ActionCollectionItem

+ (ActionCollectionItem *)emailItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-email.png"] title:NSLocalizedString(@"action.email", @"Email") identifier:kActionCollectionIdentifierEmail];
}

+ (ActionCollectionItem *)emailAsLinkItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-link.png"] title:NSLocalizedString(@"action.emailAsLink", @"Email As Link") identifier:kActionCollectionIdentifierEmailAsLink];
}

+ (ActionCollectionItem *)openInItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-open-in.png"] title:NSLocalizedString(@"action.open.in", @"Open In") identifier:kActionCollectionIdentifierOpenIn];
}

+ (ActionCollectionItem *)likeItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-like.png"] title:NSLocalizedString(@"action.like", @"Like") identifier:kActionCollectionIdentifierLike];
}

+ (ActionCollectionItem *)unlikeItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-unlike.png"] title:NSLocalizedString(@"action.unlike", @"Unlike") identifier:kActionCollectionIdentifierUnlike];
}

+ (ActionCollectionItem *)favouriteItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-favorite.png"] title:NSLocalizedString(@"action.favourite", @"Favourite") identifier:kActionCollectionIdentifierFavourite];
}

+ (ActionCollectionItem *)unfavouriteItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-unfavorite.png"] title:NSLocalizedString(@"action.unfavourite", @"Unfavourite") identifier:kActionCollectionIdentifierUnfavourite];
}

+ (ActionCollectionItem *)commentItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-comment.png"] title:NSLocalizedString(@"action.comment", @"Comment") identifier:kActionCollectionIdentifierComment];
}

+ (ActionCollectionItem *)editItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-edit.png"] title:NSLocalizedString(@"action.edit", @"Edit") identifier:kActionCollectionIdentifierEdit];
}

+ (ActionCollectionItem *)downloadItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-download.png"] title:NSLocalizedString(@"action.download", @"Download") identifier:kActionCollectionIdentifierDownload];
}

+ (ActionCollectionItem *)printItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-print.png"] title:NSLocalizedString(@"action.print", @"Print") identifier:kActionCollectionIdentifierPrint];
}

+ (ActionCollectionItem *)deleteItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-delete.png"] title:NSLocalizedString(@"action.delete", @"Delete") identifier:kActionCollectionIdentifierDelete];
}

+ (ActionCollectionItem *)renameItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-edit.png"] title:NSLocalizedString(@"action.rename", @"Rename") identifier:kActionCollectionIdentifierRename];
}

+ (ActionCollectionItem *)subfolderItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-folder.png"] title:NSLocalizedString(@"action.subfolder", @"subfolder") identifier:kActionCollectionIdentifierCreateSubfolder];
}

+ (ActionCollectionItem *)uploadItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-upload.png"] title:NSLocalizedString(@"action.upload", @"Upload") identifier:kActionCollectionIdentifierUploadDocument];
}

+ (ActionCollectionItem *)sendForReview
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-review.png"] title:NSLocalizedString(@"action.review", @"Send For Review") identifier:kActionCollectionIdentifierSendForReview];
}

+ (ActionCollectionItem *)uploadNewVersion
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"actionsheet-upload.png"] title:NSLocalizedString(@"action.new.version", @"Upload New Version") identifier:kActionCollectionIdentifierUploadNewVersion];
}

- (instancetype)initWithImage:(UIImage *)itemImage title:(NSString *)itemTitle identifier:(NSString *)itemIdentifier
{
    self = [super init];
    if (self)
    {
        self.itemIdentifier = itemIdentifier;
        self.itemImage = itemImage;
        self.itemImage = [itemImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.itemTitle = itemTitle;
        self.itemImageHighlightedImage = [self highlightedImageFromImage:itemImage];
        self.itemTitleHighlightedColor = [UIColor documentActionsHighlightColor];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:kActionCollectionItemUpdateNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)handleUpdateNotification:(NSNotification *)notification
{
    NSString *updateIdentifier = (NSString *)notification.object;
    NSDictionary *updateToDictionary = (NSDictionary *)notification.userInfo;
    
    if ([updateIdentifier isEqualToString:self.itemIdentifier])
    {
        NSString *imageName = [updateToDictionary objectForKey:kActionCollectionItemUpdateItemImageKey];
        NSString *title = [updateToDictionary objectForKey:kActionCollectionItemUpdateItemTitleKey];
        NSString *identifier = [updateToDictionary objectForKey:kActionCollectionItemUpdateItemIndentifier];
        [self updateToImageWithName:imageName title:title identifier:identifier];
    }
}

- (void)updateToImageWithName:(NSString *)imageName title:(NSString *)localisedTitle identifier:(NSString *)identifer
{
    self.itemIdentifier = identifer;
    self.itemImage = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.itemTitle = localisedTitle;
    self.itemImageHighlightedImage = [self highlightedImageFromImage:self.itemImage];
}

- (UIImage *)highlightedImageFromImage:(UIImage *)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGRect drawRect = CGRectMake(0, 0, image.size.width, image.size.height);
    [image drawInRect:drawRect];
    [[UIColor documentActionsHighlightColor] set];
    UIRectFillUsingBlendMode(drawRect, kCGBlendModeSourceAtop);
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tintedImage;
}

@end

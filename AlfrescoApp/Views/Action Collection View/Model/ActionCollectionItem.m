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

@interface ActionCollectionItem ()

@property (nonatomic, strong, readwrite) NSString *itemIdentifier;
@property (nonatomic, strong, readwrite) UIImage *itemImage;
@property (nonatomic, strong, readwrite) NSString *itemTitle;

@end

@implementation ActionCollectionItem

+ (instancetype)emailItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"sync-status-success.png"] title:NSLocalizedString(@"action.email", @"Email") identifier:kActionCollectionIdentifierEmail];
}

+ (instancetype)openInItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"repository.png"] title:NSLocalizedString(@"action.open.in", @"Open In") identifier:kActionCollectionIdentifierOpenIn];
}

+ (instancetype)likeItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"sync-status-success.png"] title:NSLocalizedString(@"action.like", @"Like") identifier:kActionCollectionIdentifierLike];
}

+ (instancetype)unlikeItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"sync-status-success.png"] title:NSLocalizedString(@"action.unlike", @"Unlike") identifier:kActionCollectionIdentifierUnlike];
}

+ (instancetype)favouriteItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"sync-status-success.png"] title:NSLocalizedString(@"action.favourite", @"Favourite") identifier:kActionCollectionIdentifierFavourite];
}

+ (instancetype)unfavouriteItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"sync-status-success.png"] title:NSLocalizedString(@"action.unfavourite", @"Unfavourite") identifier:kActionCollectionIdentifierUnfavourite];
}

+ (instancetype)commentItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"sync-status-success.png"] title:NSLocalizedString(@"action.comment", @"Comment") identifier:kActionCollectionIdentifierComment];
}

- (instancetype)initWithImage:(UIImage *)itemImage title:(NSString *)itemTitle identifier:(NSString *)itemIdentifier
{
    self = [super init];
    if (self)
    {
        self.itemIdentifier = itemIdentifier;
        self.itemImage = itemImage;
        self.itemTitle = itemTitle;
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
    self.itemImage = [UIImage imageNamed:imageName];
    self.itemTitle = localisedTitle;
}

@end

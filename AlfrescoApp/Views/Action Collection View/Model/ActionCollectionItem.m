//
//  ActionCollectionItem.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActionCollectionItem.h"

NSString * const kActionCollectionIdentifierEmail = @"ActionCollectionIdentifierEmail";
NSString * const kActionCollectionIdentifierOpenIn = @"ActionCollectionIdentifierOpenIn";

@interface ActionCollectionItem ()

@property (nonatomic, strong, readwrite) NSString *itemIdentifier;
@property (nonatomic, strong, readwrite) UIImage *itemImage;
@property (nonatomic, strong, readwrite) NSString *itemTitle;

@end

@implementation ActionCollectionItem

+ (instancetype)emailItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"sync-status-success.png"] title:NSLocalizedString(@"email", @"Email") identifier:kActionCollectionIdentifierEmail];
}

+ (instancetype)openInItem
{
    return [[self alloc] initWithImage:[UIImage imageNamed:@"repository.png"] title:NSLocalizedString(@"open.in", @"Open In") identifier:kActionCollectionIdentifierOpenIn];
}

- (instancetype)initWithImage:(UIImage *)itemImage title:(NSString *)itemTitle identifier:(NSString *)itemIdentifier
{
    self = [super init];
    if (self)
    {
        self.itemIdentifier = itemIdentifier;
        self.itemImage = itemImage;
        self.itemTitle = itemTitle;
    }
    return self;
}

@end

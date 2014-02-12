//
//  AvatarImageCache.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "AvatarImageCache.h"

@implementation AvatarImageCache

@dynamic identifier;
@dynamic avatarImageData;
@dynamic dateAdded;

- (UIImage *)avatarImage
{
    UIImage *avatarImage = nil;
    if (self.avatarImageData)
    {
        avatarImage = [UIImage imageWithData:self.avatarImageData];
    }
    return avatarImage;
}

@end

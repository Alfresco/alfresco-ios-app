//
//  AvatarImageCache.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

@interface AvatarImageCache : NSManagedObject

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSData *avatarImageData;
@property (nonatomic, retain) NSDate *dateAdded;

- (UIImage *)avatarImage;

@end

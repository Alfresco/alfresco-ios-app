//
//  DocLibImageCache.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

@interface DocLibImageCache : NSManagedObject

@property (nonatomic, retain) NSData *docLibImageData;
@property (nonatomic, retain) NSDate *dateAdded;
@property (nonatomic, retain) NSString *identifier;

- (UIImage *)docLibImage;

@end

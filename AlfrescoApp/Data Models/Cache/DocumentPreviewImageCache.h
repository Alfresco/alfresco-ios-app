//
//  DocumentPreviewImageCache.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DocumentPreviewImageCache : NSManagedObject

@property (nonatomic, retain) NSData * documentPreviewImageData;
@property (nonatomic, retain) NSDate * dateAdded;
@property (nonatomic, retain) NSString * identifier;

- (UIImage *)documentPreviewImage;

@end

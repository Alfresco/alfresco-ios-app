//
//  CoreDataCacheHelper.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "CoreDataHelper.h"
#import "AvatarImageCache.h"
#import "DocLibImageCache.h"
#import "DocumentPreviewImageCache.h"

@interface CoreDataCacheHelper : CoreDataHelper

- (AvatarImageCache *)createAvatarObjectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (AvatarImageCache *)retrieveAvatarForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (DocLibImageCache *)createDocLibObjectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (DocLibImageCache *)retrieveDocLibForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (DocumentPreviewImageCache *)createDocumentPreviewObjectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (DocumentPreviewImageCache *)retrieveDocumentPreviewForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

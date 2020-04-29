/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
  
#import "CoreDataHelper.h"
#import "AvatarImageCache.h"
#import "DocLibImageCache.h"
#import "DocumentPreviewImageCache.h"

@interface CoreDataCacheHelper : CoreDataHelper

- (AvatarImageCache *)createAvatarObjectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (AvatarImageCache *)retrieveAvatarForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (DocLibImageCache *)createDocLibObjectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (DocLibImageCache *)retrieveDocLibForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (DocLibImageCache *)retrieveDocLibForDocument:(AlfrescoDocument *)document inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (DocumentPreviewImageCache *)createDocumentPreviewObjectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (DocumentPreviewImageCache *)retrieveDocumentPreviewForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (DocumentPreviewImageCache *)retrieveDocumentPreviewForDocument:(AlfrescoDocument *)document inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)removeAllCachedDataOlderThanNumberOfDays:(NSNumber *)numberOfDays;
- (void)removeAllAvatarDataInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (void)removeAllDocLibImageDataInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (void)removeAllDocumentPreviewImageDataInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

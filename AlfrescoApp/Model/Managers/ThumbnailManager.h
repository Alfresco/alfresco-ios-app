//
//  ThumbnailManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@interface ThumbnailManager : NSObject

/*
 * Returns the shared object.
 */
+ (id)sharedManager;

/*
 * Returns the cached image for the given document identifier.
 *
 * If the image is not cached, nil will be returned.
 */
- (UIImage *)thumbnailForDocumentIdentifier:(NSString *)documentIdentifier renditionType:(NSString *)renditionType;

/*
 * Returns the cached image for the given document. Both the document identifier and modified date are matched.
 *
 * If the image is not cached, nil will be returned.
 */
- (UIImage *)thumbnailForDocument:(AlfrescoDocument *)document renditionType:(NSString *)renditionType;

/*
 * Retrieves the image for the given document. If it is currently cached, the completion block is called, otherwise a network request
 * to the server is made. Multiple calls to this function for the same document will not result in multiple network requests. Instead,
 * all completion blocks will be called once the call is completed.
 *
 * Once complete, the image is cached and the completion block is called.
 */
- (void)retrieveImageForDocument:(AlfrescoDocument *)document renditionType:(NSString *)renditionType session:(id<AlfrescoSession>)session completionBlock:(ImageCompletionBlock)completionBlock;

@end

//
//  ThumbnailDownloader.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@class AlfrescoDocument;
@protocol AlfrescoSession;

@interface ThumbnailDownloader : NSObject

+ (id)sharedManager;
- (UIImage *)thumbnailForDocument:(AlfrescoDocument *)document renditionType:(NSString *)renditionType;
- (void)retrieveImageForDocument:(AlfrescoDocument *)document renditionType:(NSString *)renditionType session:(id<AlfrescoSession>)session completionBlock:(ImageCompletionBlock)completionBlock;

@end

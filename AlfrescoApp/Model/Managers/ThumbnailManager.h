//
//  ThumbnailManager.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 23/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ThumbnailDownloader.h"

@interface ThumbnailManager : NSObject

- (UIImage *)thumbnailFromDiskForDocument:(AlfrescoDocument *)document;
- (void)saveThumbnailMappingForFolder:(AlfrescoNode *)folder;
- (UIImage *)thumbnailForNode:(AlfrescoDocument *)document withParentNode:(AlfrescoNode *)parentNode session:(id<AlfrescoSession>)session completionBlock:(ThumbnailCompletionBlock)completionBlock;

+ (ThumbnailManager *)sharedManager;

@end

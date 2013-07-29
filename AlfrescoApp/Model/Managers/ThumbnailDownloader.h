//
//  ThumbnailDownloader.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AlfrescoDocument;
@protocol AlfrescoSession;

typedef void (^ThumbnailCompletionBlock) (NSString *savedFileName, NSError *error);

@interface ThumbnailDownloader : NSObject

+ (id)sharedManager;
- (void)retrieveImageForDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session completionBlock:(ThumbnailCompletionBlock)completionBlock;
- (BOOL)thumbnailHasBeenRequestedForDocument:(AlfrescoDocument *)document;

@end

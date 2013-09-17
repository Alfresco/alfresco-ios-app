//
//  SyncManager.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SyncManager : NSObject

/**
 * Returns the shared singleton
 */
+ (SyncManager *)sharedManager;

- (NSArray *)syncDocumentsAndFoldersForSession:(id<AlfrescoSession>)alfrescoSession withCompletionBlock:(void (^)(NSArray *syncedNodes))completionBlock;

@end

//
//  PersistentQueueStore.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 20/02/2015.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PersistentQueueStore : NSObject

@property (nonatomic, strong, readonly) NSArray *queue;

/*
 Retrieves the queue from a given group identifier.
 If the queue doesn't currently exist, and empty queue is returned.
 */
- (instancetype)initWithGroupContainerIdentifier:(NSString *)groupIdentifier;

/*
 Retrieves the queue for a given identifier in the given group identifier.
 If the queue doesn't currently exist, an empty queue is returned.
 */
- (instancetype)initWithQueueIdentifier:(NSString *)queueIdentifier groupContainerIdentifier:(NSString *)groupIdentifier;

// Methods
- (void)saveQueue;
- (void)addObjectToQueue:(id)obj;
- (void)removeObjectFromQueue:(id)obj;
- (void)replaceObjectInQueueAtIndex:(NSUInteger)index withObject:(id)object;
- (void)clearQueue; // clears the queue and writes an empty queue to the file system
- (void)deleteQueue; // deletes the persisted queue completely

@end

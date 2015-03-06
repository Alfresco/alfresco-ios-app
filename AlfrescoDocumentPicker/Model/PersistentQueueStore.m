//
//  PersistentQueueStore.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 20/02/2015.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import "PersistentQueueStore.h"

static NSString * const kDefaultPersistentQueueIdentifier = @"DefaultPersistentQueue";

@interface PersistentQueueStore ()

@property (nonatomic, strong) NSString *queueIdentifier;
@property (nonatomic, strong) NSString *groupIdentifier;
@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) NSMutableArray *persistedQueue;

@end

@implementation PersistentQueueStore

- (instancetype)initWithGroupContainerIdentifier:(NSString *)groupIdentifier
{
    return [self initWithQueueIdentifier:kDefaultPersistentQueueIdentifier groupContainerIdentifier:groupIdentifier];
}

- (instancetype)initWithQueueIdentifier:(NSString *)queueIdentifier groupContainerIdentifier:(NSString *)groupIdentifier
{
    self = [self init];
    if (self)
    {
        self.queueIdentifier = queueIdentifier;
        self.groupIdentifier = groupIdentifier;
        self.defaults = [[NSUserDefaults alloc] initWithSuiteName:groupIdentifier];
        self.persistedQueue = [self persistedQueueForIdentifier:queueIdentifier groupIdentifier:groupIdentifier];
    }
    return self;
}

#pragma mark - Private Methods

- (NSMutableArray *)persistedQueueForIdentifier:(NSString *)queueIdentifier groupIdentifier:(NSString *)groupIdentifier;
{
    NSData *queueData = [self.defaults valueForKey:queueIdentifier];
    NSMutableArray *queue = nil;
    
    if (queueData)
    {
        queue = [NSKeyedUnarchiver unarchiveObjectWithData:queueData];
    }
    
    if (!queue)
    {
        queue = [NSMutableArray array];
    }
    
    return queue;
}

#pragma mark - Custom Getters and Setters

- (NSArray *)queue
{
    return self.persistedQueue;
}

#pragma mark - Public Methods

- (void)saveQueue
{
    NSData *queueData = [NSKeyedArchiver archivedDataWithRootObject:self.persistedQueue];
    [self.defaults setObject:queueData forKey:self.queueIdentifier];
}

- (void)addObjectToQueue:(id)obj
{
    [self.persistedQueue addObject:obj];
}

- (void)removeObjectFromQueue:(id)obj
{
    [self.persistedQueue removeObject:obj];
}

- (void)replaceObjectInQueueAtIndex:(NSUInteger)index withObject:(id)object
{
    [self.persistedQueue replaceObjectAtIndex:index withObject:object];
}

- (void)clearQueue
{
    [self.persistedQueue removeAllObjects];
    [self saveQueue];
}

- (void)deleteQueue
{
    [self.persistedQueue removeAllObjects];
    [self.defaults removeObjectForKey:self.queueIdentifier];
}

@end

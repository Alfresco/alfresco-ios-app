//
//  SyncAccount.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 18/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SyncNodeInfo;

@interface SyncAccount : NSManagedObject

@property (nonatomic, retain) NSString * accountId;
@property (nonatomic, retain) NSSet *nodes;
@end

@interface SyncAccount (CoreDataGeneratedAccessors)

- (void)addNodesObject:(SyncNodeInfo *)value;
- (void)removeNodesObject:(SyncNodeInfo *)value;
- (void)addSyncNodes:(NSSet *)values;
- (void)removeSyncNodes:(NSSet *)values;

@end

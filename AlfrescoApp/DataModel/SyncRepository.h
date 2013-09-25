//
//  SyncRepository.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SyncNodeInfo;

@interface SyncRepository : NSManagedObject

@property (nonatomic, retain) NSString *repositoryId;
@property (nonatomic, retain) NSSet *nodes;
@end

@interface SyncRepository (CoreDataGeneratedAccessors)

- (void)addNodesObject:(SyncNodeInfo *)value;
- (void)removeNodesObject:(SyncNodeInfo *)value;
- (void)addNodes:(NSSet *)values;
- (void)removeNodes:(NSSet *)values;

@end

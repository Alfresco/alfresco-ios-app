//
//  SyncNodeInfo.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SyncNodeInfo, SyncRepository;

@interface SyncNodeInfo : NSManagedObject

@property (nonatomic, retain) NSNumber *isFolder;
@property (nonatomic, retain) NSNumber *isUnfavoritedHasLocalChanges;
@property (nonatomic, retain) NSNumber *isTopLevelSyncNode;
@property (nonatomic, retain) NSDate *lastDownloadedDate;
@property (nonatomic, retain) NSData *node;
@property (nonatomic, retain) NSString *syncName;
@property (nonatomic, retain) NSString *syncNodeInfoId;
@property (nonatomic, retain) NSSet *nodes;
@property (nonatomic, retain) SyncNodeInfo *parentNode;
@property (nonatomic, retain) SyncRepository *repository;
@end

@interface SyncNodeInfo (CoreDataGeneratedAccessors)

- (void)addNodesObject:(SyncNodeInfo *)value;
- (void)removeNodesObject:(SyncNodeInfo *)value;
- (void)addNodes:(NSSet *)values;
- (void)removeNodes:(NSSet *)values;

@end

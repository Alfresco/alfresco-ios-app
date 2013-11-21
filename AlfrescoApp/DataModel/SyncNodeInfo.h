//
//  SyncNodeInfo.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 18/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SyncError, SyncNodeInfo, SyncAccount;

@interface SyncNodeInfo : NSManagedObject

@property (nonatomic, retain) NSNumber *isFolder;
@property (nonatomic, retain) NSNumber *isTopLevelSyncNode;
@property (nonatomic, retain) NSNumber *isRemovedFromSyncHasLocalChanges;
@property (nonatomic, retain) NSDate *lastDownloadedDate;
@property (nonatomic, retain) NSData *node;
@property (nonatomic, retain) NSNumber *reloadContent;
@property (nonatomic, retain) NSString *syncContentPath;
@property (nonatomic, retain) NSString *syncNodeInfoId;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) SyncAccount *account;
@property (nonatomic, retain) NSSet *nodes;
@property (nonatomic, retain) SyncNodeInfo *parentNode;
@property (nonatomic, retain) SyncError *syncError;
@end

@interface SyncNodeInfo (CoreDataGeneratedAccessors)

- (void)addNodesObject:(SyncNodeInfo *)value;
- (void)removeNodesObject:(SyncNodeInfo *)value;
- (void)addNodes:(NSSet *)values;
- (void)removeNodes:(NSSet *)values;

@end

//
//  SyncError.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 18/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@class SyncNodeInfo;

@interface SyncError : NSManagedObject

@property (nonatomic, retain) NSNumber *errorCode;
@property (nonatomic, retain) NSString *errorDescription;
@property (nonatomic, retain) NSString *errorId;
@property (nonatomic, retain) SyncNodeInfo *nodeInfo;

@end

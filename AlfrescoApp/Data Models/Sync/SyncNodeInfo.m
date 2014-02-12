//
//  SyncNodeInfo.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 18/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncNodeInfo.h"
#import "SyncError.h"
#import "SyncNodeInfo.h"
#import "SyncAccount.h"


@implementation SyncNodeInfo

@dynamic isFolder;
@dynamic isTopLevelSyncNode;
@dynamic isRemovedFromSyncHasLocalChanges;
@dynamic lastDownloadedDate;
@dynamic node;
@dynamic permissions;
@dynamic reloadContent;
@dynamic syncContentPath;
@dynamic syncNodeInfoId;
@dynamic title;
@dynamic account;
@dynamic nodes;
@dynamic parentNode;
@dynamic syncError;

@end

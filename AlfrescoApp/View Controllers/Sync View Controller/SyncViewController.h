//
//  SyncViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 30/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ParentListViewController.h"

@interface SyncViewController : ParentListViewController

- (id)initWithParentNode:(AlfrescoNode *)node andSession:(id<AlfrescoSession>)session;

@end

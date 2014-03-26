//
//  TaskTypeViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "FileFolderListViewController.h"

@interface TaskTypeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithSession:(id<AlfrescoSession>)session;

@end

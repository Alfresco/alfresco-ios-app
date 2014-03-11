//
//  NodePickerListViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 27/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NodePicker.h"
#import "PeoplePicker.h"

@interface NodePickerListViewController : UITableViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session items:(NSMutableArray *)items nodePickerController:(id)picker;
- (void)refreshListWithItems:(NSArray *)items;

@end

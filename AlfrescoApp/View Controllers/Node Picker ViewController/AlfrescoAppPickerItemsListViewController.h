//
//  AlfrescoAppPickerItemsListViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 27/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlfrescoAppPicker.h"

typedef NS_ENUM(NSInteger, AlfrescoAppPickerItemsListType)
{
    PickerItemsListTypeNodesMultiSelection,
    PickerItemsListTypePeopleSelection
};

@interface AlfrescoAppPickerItemsListViewController : UITableViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session pickerListType:(AlfrescoAppPickerItemsListType)listType items:(NSMutableArray *)items nodePickerController:(AlfrescoAppPicker *)nodePicker;
- (void)refreshListWithItems:(NSArray *)items;

@end

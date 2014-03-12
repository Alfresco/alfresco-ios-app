//
//  NodePickerScopeViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 11/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NodePicker.h"

@interface NodePickerScopeViewController : UITableViewController

- (id)initWithSession:(id<AlfrescoSession>)session nodePickerController:(NodePicker *)nodePicker;

@end

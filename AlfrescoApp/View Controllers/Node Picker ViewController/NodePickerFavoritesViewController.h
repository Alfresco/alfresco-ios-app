//
//  NodePickerFavoritesViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 12/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "NodePicker.h"

@interface NodePickerFavoritesViewController : ParentListViewController

- (instancetype)initWithParentNode:(AlfrescoFolder *)node
                           session:(id<AlfrescoSession>)session
              nodePickerController:(NodePicker *)nodePicker;

@end

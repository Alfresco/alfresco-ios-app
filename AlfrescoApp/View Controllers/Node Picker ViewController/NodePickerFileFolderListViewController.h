//
//  NodePickerFileFolderListViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ParentListViewController.h"
#import "NodePicker.h"

@interface NodePickerFileFolderListViewController : ParentListViewController

- (instancetype)initWithFolder:(AlfrescoFolder *)folder
             folderDisplayName:(NSString *)displayName
                       session:(id<AlfrescoSession>)session
          nodePickerController:(NodePicker *)nodePicker;

@end

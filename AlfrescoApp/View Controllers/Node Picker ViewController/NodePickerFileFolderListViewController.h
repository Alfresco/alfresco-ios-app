//
//  NodePickerFileFolderListViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "FileFolderListViewController.h"
#import "AlfrescoAppPicker.h"

@interface NodePickerFileFolderListViewController : FileFolderListViewController

- (instancetype)initWithFolder:(AlfrescoFolder *)folder
             folderPermissions:(AlfrescoPermissions *)permissions
             folderDisplayName:(NSString *)displayName
                       session:(id<AlfrescoSession>)session
          nodePickerController:(AlfrescoAppPicker *)nodePicker;

@end

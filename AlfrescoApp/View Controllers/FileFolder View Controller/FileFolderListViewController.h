/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
  
#import "BaseFileFolderListViewController.h"
#import "UploadFormViewController.h"
#import "DownloadsViewController.h"
#import "MultiSelectActionsToolbar.h"

@class AlfrescoFolder;
@class AlfrescoPermissions;
@protocol AlfrescoSession;

@interface FileFolderListViewController : BaseFileFolderListViewController <
    DownloadsPickerDelegate,
    MultiSelectActionsDelegate,
    UploadFormViewControllerDelegate,
    UIActionSheetDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
    >

/**
 Providing nil to the folder parameter will result in the root folder (Company Home) being displayed.
 
 @param folder - the content of this folder will be displayed. Providing nil will result in Company Home being displayed.
 @param session - the user' session
 */
- (id)initWithFolder:(AlfrescoFolder *)folder session:(id<AlfrescoSession>)session;

- (id)initWithFolder:(AlfrescoFolder *)folder folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session;

/**
 Use the permissions initialiser to avoid the visual refreshing of the navigationItem barbuttons. Failure to set these will result in the
 permissions being retrieved once the controller's view is displayed.
 
 @param folder - the content of this folder will be displayed. Providing nil will result in Company Home being displayed.
 @param permissions - the permissions of the folder
 @param session - the user' session
 */
- (id)initWithFolder:(AlfrescoFolder *)folder folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session;

- (id)initWithFolder:(AlfrescoFolder *)folder folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session;

@end

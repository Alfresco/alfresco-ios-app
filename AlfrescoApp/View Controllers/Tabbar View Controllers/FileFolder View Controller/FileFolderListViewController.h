//
//  FileFolderListViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "UploadFormViewController.h"
#import "DownloadsViewController.h"
#import "MultiSelectActionsToolbar.h"

@class AlfrescoFolder;
@class AlfrescoPermissions;
@protocol AlfrescoSession;

@interface FileFolderListViewController : ParentListViewController <
    DownloadsPickerDelegate,
    MultiSelectActionsDelegate,
    UploadFormViewControllerDelegate,
    UIActionSheetDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIPopoverControllerDelegate,
    UISearchBarDelegate,
    UISearchDisplayDelegate>

@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults;

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

- (void)updateUIUsingFolderPermissionsWithAnimation:(BOOL)animated;

@end

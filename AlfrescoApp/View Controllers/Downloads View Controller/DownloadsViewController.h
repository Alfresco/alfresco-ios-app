//
//  DownloadsViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ParentListViewController.h"
#import "MultiSelectActionsToolbar.h"
#import "DocumentFilter.h"

@class DownloadsViewController;

@protocol DownloadsPickerDelegate <NSObject>
@optional
- (void)downloadPicker:(DownloadsViewController *)picker didPickDocument:(NSString *)documentPath;
- (void)downloadPickerDidCancel;
@end

@interface DownloadsViewController : ParentListViewController <MultiSelectActionsDelegate, UIActionSheetDelegate>

@property (nonatomic) BOOL isDownloadPickerEnabled;
@property (nonatomic, weak) id<DownloadsPickerDelegate> downloadPickerDelegate;

- (id)initWithDocumentFilter:(id<DocumentFilter>)documentFilter;

@end

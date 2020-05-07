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
  
#import "ParentListViewController.h"
#import "MultiSelectContainerView.h"
#import "DocumentFilter.h"

@class DownloadsViewController;

@protocol DownloadsPickerDelegate <NSObject>
@optional
- (void)downloadPicker:(DownloadsViewController *)picker didPickDocument:(NSString *)documentPath;
- (void)downloadPickerDidCancel;
@end

@interface DownloadsViewController : ParentListViewController <MultiSelectActionsDelegate>

@property (nonatomic) BOOL isDownloadPickerEnabled;
@property (nonatomic, weak) id<DownloadsPickerDelegate> downloadPickerDelegate;
@property (nonatomic, getter=isScreenNameTrackingEnabled) BOOL screenNameTrackingEnabled;

- (id)initWithDocumentFilter:(id<DocumentFilter>)documentFilter;

@end

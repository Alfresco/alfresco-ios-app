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

#import <UIKit/UIKit.h>

@interface SearchViewController : UITableViewController

@property (nonatomic, weak) UIViewController *sitesPushHandler;
@property (nonatomic) BOOL shouldHideNavigationBarOnSearchControllerPresentation;

- (instancetype)initWithDataSourceType:(SearchViewControllerDataSourceType)dataSourceType listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session;
- (void)pushDocument:(AlfrescoNode *)node contentPath:(NSString *)contentPath permissions:(AlfrescoPermissions *)permissions;
- (void)pushFolder:(AlfrescoFolder *)node folderPermissions:(AlfrescoPermissions *)permissions;
- (void)pushFolderPreviewForAlfrescoFolder:(AlfrescoFolder *)node folderPermissions:(AlfrescoPermissions *)permissions;
- (void)pushUser:(AlfrescoPerson *)person;

@end

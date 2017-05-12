/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
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

#import "AccountDataSource.h"

@class AccountDetailsViewController;

@protocol AccountDetailsViewControllerDelegate <NSObject>

@optional
- (void)accountDetailsViewControllerWillDismiss:(AccountDetailsViewController *)controller;
- (void)accountDetailsViewControllerDidDismiss:(AccountDetailsViewController *)controller;
- (void)accountDetailsViewController:(AccountDetailsViewController *)controller willDismissAfterAddingAccount:(UserAccount *)account;
- (void)accountDetailsViewController:(AccountDetailsViewController *)controller didDismissAfterAddingAccount:(UserAccount *)account;
- (void)accountInfoChanged:(UserAccount *)newAccount;

@end

@interface AccountDetailsViewController : UITableViewController

@property (nonatomic, weak) id<AccountDetailsViewControllerDelegate> delegate;

- (instancetype)initWithDataSourceType:(AccountDataSourceType)dataSourceType account:(UserAccount *)account configuration:(NSDictionary *)configuration session:(id<AlfrescoSession>)session;

@end

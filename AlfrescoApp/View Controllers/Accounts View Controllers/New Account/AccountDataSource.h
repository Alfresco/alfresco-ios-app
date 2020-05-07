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

#import <Foundation/Foundation.h>

typedef enum : NSUInteger
{
    AccountDataSourceTypeNewAccountServer,
    AccountDataSourceTypeNewAccountCredentials,
    AccountDataSourceTypeAccountSettings,
    AccountDataSourceTypeAccountSettingSAML,
    AccountDataSourceTypeCloudAccountSettings,
    AccountDataSourceTypeAccountDetails,
    AccountDataSourceTypeNewAccountAIMS,
    AccountDataSourceTypeAccountSettingAIMS
} AccountDataSourceType;

typedef enum : NSUInteger
{
    AccountFormFieldInvalid              = 1 << 0,
    AccountFormFieldValidWithChanges     = 1 << 1,
    AccountFormFieldValidWithoutChanges  = 1 << 2
}AccountFormFieldValidation;

static NSInteger const kTagCertificateCell = 1;
static NSInteger const kTagReorderCell = 2;
static NSInteger const kTagProfileCell = 3;
static NSInteger const kTagAccountDetailsCell = 4;
static NSInteger const kTagLogOutCell = 5;
static NSInteger const kTagNeedHelpCell = 6;

@protocol AccountDataSourceDelegate <NSObject>

@optional
- (void)enableSaveBarButton:(BOOL)enable;

@end

@interface AccountDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, weak) id <AccountDataSourceDelegate> delegate;

- (instancetype)initWithDataSourceType:(AccountDataSourceType)dataSourceType account:(UserAccount *)account backupAccount:(UserAccount *)backupAccount configuration:(NSDictionary *)configuration;

- (void)updateFormBackupAccount;
- (void)reloadWithAccount:(UserAccount *)account;
- (BOOL)validateAccountFieldsValues;

@end

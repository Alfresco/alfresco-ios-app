/*
 ******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile SDK.
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
 *****************************************************************************
 */

#import "AlfrescoConfigInfo.h"
#import "AlfrescoCreationConfig.h"
#import "AlfrescoFeatureConfig.h"
#import "AlfrescoFormConfig.h"
#import "AlfrescoProfileConfig.h"
#import "AlfrescoRepositoryConfig.h"
#import "AlfrescoViewConfig.h"
#import "AlfrescoViewGroupConfig.h"


typedef void (^AlfrescoConfigInfoCompletionBlock)(AlfrescoConfigInfo *configInfo, NSError *error);
typedef void (^AlfrescoCreationConfigCompletionBlock)(AlfrescoCreationConfig *config, NSError *error);
typedef void (^AlfrescoFeatureConfigCompletionBlock)(AlfrescoFeatureConfig *config, NSError *error);
typedef void (^AlfrescoFormConfigCompletionBlock)(AlfrescoFormConfig *config, NSError *error);
typedef void (^AlfrescoProfileConfigCompletionBlock)(AlfrescoProfileConfig *config, NSError *error);
typedef void (^AlfrescoRepositoryConfigCompletionBlock)(AlfrescoRepositoryConfig *config, NSError *error);
typedef void (^AlfrescoViewConfigCompletionBlock)(AlfrescoViewConfig *config, NSError *error);
typedef void (^AlfrescoViewConfigsCompletionBlock)(NSArray *configs, NSError *);
typedef void (^AlfrescoViewGroupConfigCompletionBlock)(AlfrescoViewGroupConfig *config, NSError *error);

/**---------------------------------------------------------------------------------------
 * @name Configuration Constants
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoConfigServiceParameterApplicationId;
extern NSString * const kAlfrescoConfigServiceParameterProfileId;
extern NSString * const kAlfrescoConfigServiceParameterFolder;
extern NSString * const kAlfrescoConfigServiceParameterFileName;

extern NSString * const kAlfrescoConfigScopeContextNode;
extern NSString * const kAlfrescoConfigScopeContextFormMode;

extern NSString * const kAlfrescoConfigNewConfigRetrievedFromServerNotification;
extern NSString * const kAlfrescoConfigBadConfigRetrievedFromServerNotification;

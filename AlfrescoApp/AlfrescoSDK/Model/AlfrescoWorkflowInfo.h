/*
 ******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
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

/** The AlfrescoWorkflowInfo model object
 
 Author: Tauseef Mughal (Alfresco)
 */

#import <Foundation/Foundation.h>
#import "AlfrescoConstants.h"

@protocol AlfrescoSession;

@interface AlfrescoWorkflowInfo : NSObject <NSCoding>

@property (nonatomic, assign, readonly) AlfrescoWorkflowEngineType workflowEngine;
@property (nonatomic, assign, readonly) BOOL publicAPI;

- (id)initWithSession:(id<AlfrescoSession>)session workflowEngine:(AlfrescoWorkflowEngineType)workflowEngine;

@end

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

/** The AlfrescoWorkflowTask model object
 
 Author: Tauseef Mughal (Alfresco)
 */

#import <Foundation/Foundation.h>

@protocol AlfrescoSession;

@interface AlfrescoWorkflowTask : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSString *processIdentifier;
@property (nonatomic, strong, readonly) NSString *processDefinitionIdentifier;
@property (nonatomic, strong, readonly) NSDate *startedAt;
@property (nonatomic, strong, readonly) NSDate *endedAt;
@property (nonatomic, strong, readonly) NSDate *dueAt;
@property (nonatomic, strong, readonly) NSString *taskDescription;
@property (nonatomic, strong, readonly) NSNumber *priority;
@property (nonatomic, strong, readonly) NSString *assigneeIdentifier;

- (id)initWithProperties:(NSDictionary *)properties session:(id<AlfrescoSession>)session;

@end

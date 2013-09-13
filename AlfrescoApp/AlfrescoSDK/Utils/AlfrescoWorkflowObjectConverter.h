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

/** AlfrescoWorkflowObjectConverter
 
 Author: Tauseef Mughal (Alfresco)
 */

#import "AlfrescoObjectConverter.h"

@protocol AlfrescoSession;

@interface AlfrescoWorkflowObjectConverter : AlfrescoObjectConverter

// process definitions
- (NSArray *)workflowDefinitionsFromOldJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error;
- (NSArray *)workflowDefinitionsFromPublicJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error;

// processes
- (NSArray *)workflowProcessesFromOldJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error;
- (NSArray *)workflowProcessesFromPublicJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error;

// tasks
- (NSArray *)workflowTasksFromOldJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error;
- (NSArray *)workflowTasksFromPublicJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error;

// attachment identifiers
- (NSString *)attachmentContainerNodeRefFromOldJSONData:(NSData *)jsonData conversionError:(NSError **)error;
- (NSArray *)attachmentIdentifiersFromOldJSONData:(NSData *)jsonData conversionError:(NSError **)error;
- (NSArray *)attachmentIdentifiersFromPublicJSONData:(NSData *)jsonData conversionError:(NSError **)error;

@end

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

#import <Foundation/Foundation.h>

extern NSString * const kAlfrescoProcessDefinitionID;
extern NSString * const kAlfrescoProcessID;
extern NSString * const kAlfrescoTaskID;
extern NSString * const kAlfrescoItemID;

extern NSString * const kAlfrescoWorkflowReviewAndApprove;

extern NSString * const kAlfrescoWorkflowBaseOldAPIURL;
extern NSString * const kAlfrescoWorkflowBasePublicAPIURL;

extern NSString * const kAlfrescoWorkflowProcessDefinitionOldAPI;
extern NSString * const kAlfrescoWorkflowProcessDefinitionPublicAPI;
extern NSString * const kAlfrescoWorkflowSingleProcessDefinitionOldAPI;
extern NSString * const kAlfrescoWorkflowSingleProcessDefinitionPublicAPI;
extern NSString * const kAlfrescoWorkflowProcessDefinitionFormModelPublicAPI;

extern NSString * const kAlfrescoWorkflowProcessesOldAPI;
extern NSString * const kAlfrescoWorkflowProcessesPublicAPI;
extern NSString * const kAlfrescoWorkflowSingleProcessOldAPI;
extern NSString * const kAlfrescoWorkflowSingleProcessPublicAPI;
extern NSString * const kAlfrescoWorkflowTasksForProcessOldAPI;
extern NSString * const kAlfrescoWorkflowTasksForProcessPublicAPI;
extern NSString * const kAlfrescoWorkflowProcessImageOldAPI;
extern NSString * const kAlfrescoWorkflowProcessImagePublicAPI;
extern NSString * const kAlfrescoWorkflowProcessCreateOldAPI;

extern NSString * const kAlfrescoWorkflowProcessWhereParameter;
extern NSString * const kAlfrescoWorkflowProcessStatus;
extern NSString * const kAlfrescoWorkflowProcessPublicAny;
extern NSString * const kAlfrescoWorkflowProcessPublicActive;
extern NSString * const kAlfrescoWorkflowProcessPublicCompleted;
extern NSString * const kAlfrescoWorkflowProcessOldInProgress;
extern NSString * const kAlfrescoWorkflowProcessOldCompleted;

extern NSString * const kAlfrescoWorkflowTasksOldAPI;
extern NSString * const kAlfrescoWorkflowTasksPublicAPI;
extern NSString * const kAlfrescoWorkflowSingleTaskOldAPI;
extern NSString * const kAlfrescoWorkflowSingleTaskPublicAPI;
extern NSString * const kAlfrescoWorkflowTaskAttachmentsOldAPI;
extern NSString * const kAlfrescoWorkflowTaskAttachmentsPublicAPI;
extern NSString * const kAlfrescoWorkflowTaskAttachmentsDeletePublicAPI;
extern NSString * const kAlfrescoWorkflowTaskCompleteOldAPI;

extern NSString * const kAlfrescoWorkflowTaskSelectParameter;
extern NSString * const kAlfrescoWorkflowState;
extern NSString * const kAlfrescoWorkflowTaskAssignee;
extern NSString * const kAlfrescoWorkflowTaskCompleted;
extern NSString * const kAlfrescoWorkflowTaskClaim;
extern NSString * const kAlfrescoWorkflowTaskUnClaim;
extern NSString * const kAlfrescoWorkflowTaskResolved;

extern NSString * const kAlfrescoPersonNodeRefOldAPI;

extern NSString * const kAlfrescoWorkflowJBPMEnginePrefix;
extern NSString * const kAlfrescoWorkflowActivitiEnginePrefix;
extern NSString * const kAlfrescoWorkflowNodeRefPrefix;

extern NSString * const kAlfrescoPublicJSONEntry;
extern NSString * const kAlfrescoPublicJSONIdentifier;
extern NSString * const kAlfrescoPublicJSONName;
extern NSString * const kAlfrescoPublicJSONDescription;
extern NSString * const kAlfrescoPublicJSONVersion;
extern NSString * const kAlfrescoPublicJSONList;
extern NSString * const kAlfrescoPublicJSONEntries;
extern NSString * const kAlfrescoPublicJSONHasMoreItems;
extern NSString * const kAlfrescoPublicJSONTotalItems;
extern NSString * const kAlfrescoPublicJSONSkipCount;
extern NSString * const kAlfrescoPublicJSONMaxItems;

extern NSString * const kAlfrescoPublicJSONProcessID;
extern NSString * const kAlfrescoPublicJSONProcessDefinitionID;
extern NSString * const kAlfrescoPublicJSONProcessDefinitionKey;
extern NSString * const kAlfrescoPublicJSONStartedAt;
extern NSString * const kAlfrescoPublicJSONEndedAt;
extern NSString * const kAlfrescoPublicJSONDueAt;
extern NSString * const kAlfrescoPublicJSONPriority;
extern NSString * const kAlfrescoPublicJSONAssignee;
extern NSString * const kAlfrescoPublicJSONVariables;
extern NSString * const kAlfrescoPublicJSONStartUserID;

extern NSString * const kAlfrescoOldJSONProperties;
extern NSString * const kAlfrescoOldJSONWorkflowInstance;
extern NSString * const kAlfrescoOldJSONData;
extern NSString * const kAlfrescoOldBPMJSONID;
extern NSString * const kAlfrescoOldJSONIdentifier;
extern NSString * const kAlfrescoOldJSONName;
extern NSString * const kAlfrescoOldBPMJSONStartedAt;
extern NSString * const kAlfrescoOldBPMJSONEndedAt;
extern NSString * const kAlfrescoOldBPMJSONDueAt;
extern NSString * const kAlfrescoOldBPMJSONPriority;
extern NSString * const kAlfrescoOldBPMJSONDescription;
extern NSString * const kAlfrescoOldBPMJSONAssignee;
extern NSString * const kAlfrescoOldBPMJSONPackageContainer;

extern NSString * const kAlfrescoOldJSONOwner;

extern NSString * const kAlfrescoPublicBPMJSONProcessDescription;
extern NSString * const kAlfrescoPublicBPMJSONProcessPriority;
extern NSString * const kAlfrescoPublicBPMJSONProcessAssignee;
extern NSString * const kAlfrescoPublicBPMJSONProcessAssignees;
extern NSString * const kAlfrescoPublicBPMJSONProcessSendEmailNotification;
extern NSString * const kAlfrescoPublicBPMJSONProcessDueDate;
extern NSString * const kAlfrescoPublicBPMJSONProcessApprovalRate;

extern NSString * const kAlfrescoOldBPMJSONProcessDescription;
extern NSString * const kAlfrescoOldBPMJSONProcessPriority;
extern NSString * const kAlfrescoOldBPMJSONProcessAssignee;
extern NSString * const kAlfrescoOldBPMJSONProcessAssignees;
extern NSString * const kAlfrescoOldBPMJSONProcessSendEmailNotification;
extern NSString * const kAlfrescoOldBPMJSONProcessDueDate;
extern NSString * const kAlfrescoOldBPMJSONProcessAttachmentsAdd;
extern NSString * const kAlfrescoOldBPMJSONProcessAttachmentsRemove;
extern NSString * const kAlfrescoOldBPMJSONProcessApprovalRate;

extern NSString * const kAlfrescoOldBPMJSONTransition;
extern NSString * const kAlfrescoOldBPMJSONStatus;
extern NSString * const kAlfrescoOldBPMJSONReviewOutcome;
extern NSString * const kAlfrescoOldBPMJSONComment;
extern NSString * const kAlfrescoOldJSONNext;
extern NSString * const kAlfrescoOldJSONCompleted;
extern NSString * const kAlfrescoOldJSONItemValue;

extern NSString * const kAlfrescoOldJSONProcessDefinitionID;
extern NSString * const kAlfrescoOldJSONStartedAt;
extern NSString * const kAlfrescoOldJSONEndedAt;
extern NSString * const kAlfrescoOldJSONDueAt;
extern NSString * const kAlfrescoOldJSONPriority;
extern NSString * const kAlfrescoOldJSONDescription;
extern NSString * const kAlfrescoOldJSONInitiator;

extern NSString * const kAlfrescoWorkflowEngineType;
extern NSString * const kAlfrescoWorkflowUsingPublicAPI;

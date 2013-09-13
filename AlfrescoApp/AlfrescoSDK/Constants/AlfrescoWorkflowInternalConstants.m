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

#import "AlfrescoWorkflowInternalConstants.h"

/**
 Workflow Constants
 */
NSString * const kAlfrescoProcessDefinitionID = @"{processDefinitionId}";
NSString * const kAlfrescoProcessID = @"{processId}";
NSString * const kAlfrescoTaskID = @"{taskId}";
NSString * const kAlfrescoItemID = @"{itemId}";

NSString * const kAlfrescoWorkflowReviewAndApprove = @"activitiReview";
// base URL's
NSString * const kAlfrescoWorkflowBaseOldAPIURL = @"/service/api/";
NSString * const kAlfrescoWorkflowBasePublicAPIURL = @"/api/-default-/public/workflow/versions/1";
// process-definitions
NSString * const kAlfrescoWorkflowProcessDefinitionOldAPI = @"workflow-definitions";
NSString * const kAlfrescoWorkflowProcessDefinitionPublicAPI = @"process-definitions";
NSString * const kAlfrescoWorkflowSingleProcessDefinitionOldAPI = @"workflow-definitions/{processDefinitionId}";
NSString * const kAlfrescoWorkflowSingleProcessDefinitionPublicAPI = @"process-definitions/{processDefinitionId}";
NSString * const kAlfrescoWorkflowProcessDefinitionFormModelPublicAPI = @"process-definitions/{processDefinitionId}/start-form-model";
// processes
NSString * const kAlfrescoWorkflowProcessesOldAPI = @"workflow-instances";
NSString * const kAlfrescoWorkflowProcessesPublicAPI = @"processes";
NSString * const kAlfrescoWorkflowSingleProcessOldAPI = @"workflow-instances/{processId}";
NSString * const kAlfrescoWorkflowSingleProcessPublicAPI = @"processes/{processId}";
NSString * const kAlfrescoWorkflowTasksForProcessOldAPI = @"workflow-instances/{processId}/task-instances";
NSString * const kAlfrescoWorkflowTasksForProcessPublicAPI = @"processes/{processId}/tasks";
NSString * const kAlfrescoWorkflowProcessImageOldAPI = @"workflow-instances/{processId}/diagram";
NSString * const kAlfrescoWorkflowProcessImagePublicAPI = @"processes/{processId}/image";
NSString * const kAlfrescoWorkflowProcessCreateOldAPI = @"workflow/{processDefinitionId}/formprocessor";
// processes - Parameters
NSString * const kAlfrescoWorkflowProcessWhereParameter = @"where";
NSString * const kAlfrescoWorkflowProcessStatus = @"status";
NSString * const kAlfrescoWorkflowProcessPublicAny = @"any";
NSString * const kAlfrescoWorkflowProcessPublicActive = @"active";
NSString * const kAlfrescoWorkflowProcessPublicCompleted = @"completed";
NSString * const kAlfrescoWorkflowProcessOldInProgress = @"in_progress";
NSString * const kAlfrescoWorkflowProcessOldCompleted = @"completed";
// tasks
NSString * const kAlfrescoWorkflowTasksOldAPI = @"task-instances";
NSString * const kAlfrescoWorkflowTasksPublicAPI = @"tasks";
NSString * const kAlfrescoWorkflowSingleTaskOldAPI = @"task-instances/{taskId}";
NSString * const kAlfrescoWorkflowSingleTaskPublicAPI = @"tasks/{taskId}";
NSString * const kAlfrescoWorkflowTaskAttachmentsOldAPI = @"forms/picker/items";
NSString * const kAlfrescoWorkflowTaskAttachmentsPublicAPI = @"tasks/{taskId}/items";
NSString * const kAlfrescoWorkflowTaskAttachmentsDeletePublicAPI = @"tasks/{taskId}/items/{itemId}";
NSString * const kAlfrescoWorkflowTaskCompleteOldAPI = @"task/{taskId}/formprocessor";
// tasks - Parameters
NSString * const kAlfrescoWorkflowTaskSelectParameter = @"select";
NSString * const kAlfrescoWorkflowState = @"state";
NSString * const kAlfrescoWorkflowTaskAssignee = @"assignee";
NSString * const kAlfrescoWorkflowTaskCompleted = @"completed";
NSString * const kAlfrescoWorkflowTaskClaim = @"claimed";
NSString * const kAlfrescoWorkflowTaskUnClaim = @"unclaimed";
NSString * const kAlfrescoWorkflowTaskResolved = @"resolved";
// person node ref
NSString * const kAlfrescoPersonNodeRefOldAPI = @"forms/picker/authority/children?selectableType=cm:person&searchTerm={personID}&size=1";

NSString * const kAlfrescoWorkflowJBPMEnginePrefix = @"jbpm$";
NSString * const kAlfrescoWorkflowActivitiEnginePrefix = @"activiti$";
NSString * const kAlfrescoWorkflowNodeRefPrefix = @"workspace://SpacesStore/";

// workflow
NSString * const kAlfrescoPublicJSONEntry = @"entry";
NSString * const kAlfrescoPublicJSONIdentifier = @"id";
NSString * const kAlfrescoPublicJSONName = @"name";
NSString * const kAlfrescoPublicJSONDescription = @"description";
NSString * const kAlfrescoPublicJSONVersion = @"version";
NSString * const kAlfrescoPublicJSONList = @"list";
NSString * const kAlfrescoPublicJSONEntries = @"entries";
NSString * const kAlfrescoPublicJSONHasMoreItems = @"hasMoreItems";
NSString * const kAlfrescoPublicJSONTotalItems = @"totalItems";
NSString * const kAlfrescoPublicJSONSkipCount = @"skipCount";
NSString * const kAlfrescoPublicJSONMaxItems = @"maxItems";

NSString * const kAlfrescoPublicJSONProcessID = @"processId";
NSString * const kAlfrescoPublicJSONProcessDefinitionID = @"processDefinitionId";
NSString * const kAlfrescoPublicJSONProcessDefinitionKey = @"processDefinitionKey";
NSString * const kAlfrescoPublicJSONStartedAt = @"startedAt";
NSString * const kAlfrescoPublicJSONEndedAt = @"endedAt";
NSString * const kAlfrescoPublicJSONDueAt = @"dueAt";
NSString * const kAlfrescoPublicJSONPriority = @"priority";
NSString * const kAlfrescoPublicJSONAssignee = @"assignee";
NSString * const kAlfrescoPublicJSONVariables = @"variables";
NSString * const kAlfrescoPublicJSONStartUserID = @"startUserId";

NSString * const kAlfrescoOldJSONProperties = @"properties";
NSString * const kAlfrescoOldJSONWorkflowInstance = @"workflowInstance";
NSString * const kAlfrescoOldJSONData = @"data";
NSString * const kAlfrescoOldBPMJSONID = @"bpm_taskId";
NSString * const kAlfrescoOldJSONIdentifier = @"id";
NSString * const kAlfrescoOldJSONName = @"name";
NSString * const kAlfrescoOldBPMJSONStartedAt = @"bpm_startDate";
NSString * const kAlfrescoOldBPMJSONEndedAt = @"bpm_completionDate";
NSString * const kAlfrescoOldBPMJSONDueAt = @"bpm_dueDate";
NSString * const kAlfrescoOldBPMJSONPriority = @"bpm_priority";
NSString * const kAlfrescoOldBPMJSONDescription = @"bpm_description";
NSString * const kAlfrescoOldBPMJSONAssignee = @"bpm_assignee";
NSString * const kAlfrescoOldBPMJSONPackageContainer = @"bpm_package";

NSString * const kAlfrescoOldJSONOwner = @"cm_owner";

NSString * const kAlfrescoPublicBPMJSONProcessDescription = @"bpm_workflowDescription";
NSString * const kAlfrescoPublicBPMJSONProcessPriority= @"bpm_workflowPriority";
NSString * const kAlfrescoPublicBPMJSONProcessAssignee = @"bpm_assignee";
NSString * const kAlfrescoPublicBPMJSONProcessAssignees = @"bpm_assignees";
NSString * const kAlfrescoPublicBPMJSONProcessSendEmailNotification = @"bpm_sendEMailNotifications";
NSString * const kAlfrescoPublicBPMJSONProcessDueDate = @"bpm_workflowDueDate";
NSString * const kAlfrescoPublicBPMJSONProcessApprovalRate = @"wf_requiredApprovePercent";

NSString * const kAlfrescoOldBPMJSONProcessDescription = @"prop_bpm_workflowDescription";
NSString * const kAlfrescoOldBPMJSONProcessPriority = @"prop_bpm_workflowPriority";
NSString * const kAlfrescoOldBPMJSONProcessAssignee = @"assoc_bpm_assignee_added";
NSString * const kAlfrescoOldBPMJSONProcessAssignees = @"assoc_bpm_assignees_added";
NSString * const kAlfrescoOldBPMJSONProcessSendEmailNotification = @"prop_bpm_sendEMailNotifications";
NSString * const kAlfrescoOldBPMJSONProcessDueDate = @"prop_bpm_workflowDueDate";
NSString * const kAlfrescoOldBPMJSONProcessAttachmentsAdd = @"assoc_packageItems_added";
NSString * const kAlfrescoOldBPMJSONProcessAttachmentsRemove = @"assoc_packageItems_removed";
NSString * const kAlfrescoOldBPMJSONProcessApprovalRate = @"prop_wf_requiredApprovePercent";

NSString * const kAlfrescoOldBPMJSONTransition = @"prop_transitions";
NSString * const kAlfrescoOldBPMJSONStatus = @"prop_bpm_status";
NSString * const kAlfrescoOldBPMJSONReviewOutcome = @"prop_wf_reviewOutcome";
NSString * const kAlfrescoOldBPMJSONComment = @"prop_bpm_comment";
NSString * const kAlfrescoOldJSONNext = @"Next";
NSString * const kAlfrescoOldJSONCompleted = @"Completed";
NSString * const kAlfrescoOldJSONItemValue = @"itemValueType";

NSString * const kAlfrescoOldJSONProcessDefinitionID = @"definitionUrl";
NSString * const kAlfrescoOldJSONStartedAt = @"startDate";
NSString * const kAlfrescoOldJSONEndedAt = @"endDate";
NSString * const kAlfrescoOldJSONDueAt = @"dueDate";
NSString * const kAlfrescoOldJSONPriority = @"priority";
NSString * const kAlfrescoOldJSONDescription = @"description";
NSString * const kAlfrescoOldJSONInitiator = @"initiator";

/**
 Property name constants
 */
NSString * const kAlfrescoWorkflowEngineType = @"workflowEngineType";
NSString * const kAlfrescoWorkflowUsingPublicAPI = @"workflowPublicAPI";


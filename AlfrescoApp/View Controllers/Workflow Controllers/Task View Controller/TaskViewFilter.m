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

#import "TaskViewFilter.h"

@interface TaskViewFilter()

@property (nonatomic, strong, readwrite) NSString *filterAssignee;
@property (nonatomic, strong, readwrite) NSString *filterPriority;
@property (nonatomic, strong, readwrite) NSString *filterStatus;
@property (nonatomic, strong, readwrite) NSString *filterDue;

@end

@implementation TaskViewFilter

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        self.filterAssignee = dictionary[kAlfrescoConfigViewParameterTaskFiltersAssigneeKey];
        self.filterPriority = dictionary[kAlfrescoConfigViewParameterTaskFiltersPriorityKey];
        self.filterStatus = dictionary[kAlfrescoConfigViewParameterTaskFiltersStatusKey];
        self.filterDue = dictionary[kAlfrescoConfigViewParameterTaskFiltersDueKey];
    }
    return self;
}

- (AlfrescoListingFilter *)listingFilter
{
    AlfrescoListingFilter *listingFilter = [[AlfrescoListingFilter alloc] init];

    /**
     * Assignee
     */
    if (self.filterAssignee)
    {
        if ([self.filterAssignee isEqualToString:kAlfrescoConfigViewParameterTaskFiltersAssigneeMe])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowAssignee withValue:kAlfrescoFilterValueWorkflowAssigneeMe];
        }
        else if ([self.filterAssignee isEqualToString:kAlfrescoConfigViewParameterTaskFiltersAssigneeAll])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowAssignee withValue:kAlfrescoFilterValueWorkflowAssigneeAll];
        }
        else if ([self.filterAssignee isEqualToString:kAlfrescoConfigViewParameterTaskFiltersAssigneeUnassigned])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowAssignee withValue:kAlfrescoFilterValueWorkflowAssigneeUnassigned];
        }
    }
    
    /**
     * Priority
     */
    if (self.filterPriority)
    {
        if ([self.filterPriority isEqualToString:kAlfrescoConfigViewParameterTaskFiltersPriorityHigh])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowPriority withValue:kAlfrescoFilterValueWorkflowPriorityHigh];
        }
        else if ([self.filterPriority isEqualToString:kAlfrescoConfigViewParameterTaskFiltersPriorityMedium])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowPriority withValue:kAlfrescoFilterValueWorkflowPriorityMedium];
        }
        else if ([self.filterPriority isEqualToString:kAlfrescoConfigViewParameterTaskFiltersPriorityLow])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowPriority withValue:kAlfrescoFilterValueWorkflowPriorityLow];
        }
    }
    
    /**
     * Status
     */
    if (self.filterStatus)
    {
        if ([self.filterStatus isEqualToString:kAlfrescoConfigViewParameterTaskFiltersStatusActive])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowStatus withValue:kAlfrescoFilterValueWorkflowStatusActive];
        }
        else if ([self.filterStatus isEqualToString:kAlfrescoConfigViewParameterTaskFiltersStatusAny])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowStatus withValue:kAlfrescoFilterValueWorkflowStatusAny];
        }
        else if ([self.filterStatus isEqualToString:kAlfrescoConfigViewParameterTaskFiltersStatusComplete])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowStatus withValue:kAlfrescoFilterValueWorkflowStatusCompleted];
        }
    }

    /**
     * Due Date
     */
    if (self.filterDue)
    {
        if ([self.filterDue isEqualToString:kAlfrescoConfigViewParameterTaskFiltersDueToday])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowDueDate withValue:kAlfrescoFilterValueWorkflowDueDateToday];
        }
        else if ([self.filterDue isEqualToString:kAlfrescoConfigViewParameterTaskFiltersDueTomorrow])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowDueDate withValue:kAlfrescoFilterValueWorkflowDueDateTomorrow];
        }
        else if ([self.filterDue isEqualToString:kAlfrescoConfigViewParameterTaskFiltersDueWeek])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowDueDate withValue:kAlfrescoFilterValueWorkflowDueDate7Days];
        }
        else if ([self.filterDue isEqualToString:kAlfrescoConfigViewParameterTaskFiltersDueOverdue])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowDueDate withValue:kAlfrescoFilterValueWorkflowDueDateOverdue];
        }
        else if ([self.filterDue isEqualToString:kAlfrescoConfigViewParameterTaskFiltersDueNone])
        {
            [listingFilter addFilter:kAlfrescoFilterByWorkflowDueDate withValue:kAlfrescoFilterValueWorkflowDueDateNone];
        }
    }
    
    return listingFilter;
}

@end

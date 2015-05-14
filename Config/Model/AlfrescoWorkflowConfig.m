/*
 ******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

#import "AlfrescoWorkflowConfig.h"
#import "AlfrescopropertyConstants.h"

@interface AlfrescoWorkflowConfig ()
@property (nonatomic, strong, readwrite) NSArray *processConfig;
@property (nonatomic, strong, readwrite) NSArray *taskConfig;
@end

@implementation AlfrescoWorkflowConfig

- (id)initWithDictionary:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        self.processConfig = properties[kAlfrescoWorkflowConfigPropertyProcessConfig];
        self.taskConfig = properties[kAlfrescoWorkflowConfigPropertyTaskConfig];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        self.processConfig = [aDecoder decodeObjectForKey:kAlfrescoWorkflowConfigPropertyProcessConfig];
        self.taskConfig = [aDecoder decodeObjectForKey:kAlfrescoWorkflowConfigPropertyTaskConfig];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.processConfig forKey:kAlfrescoWorkflowConfigPropertyProcessConfig];
    [aCoder encodeObject:self.taskConfig forKey:kAlfrescoWorkflowConfigPropertyTaskConfig];
}

@end

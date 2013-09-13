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

/** AlfrescoWorkflowUtils
 
 Author: Tauseef Mughal (Alfresco)
 */

#import "AlfrescoWorkflowUtils.h"
#import "AlfrescoInternalConstants.h"

@implementation AlfrescoWorkflowUtils

+ (NSString *)prefixForActivitiEngineType:(AlfrescoWorkflowEngineType)engineType
{
    NSString *returnString = nil;
    switch (engineType)
    {
        case AlfrescoWorkflowEngineTypeJBPM:
        {
            returnString = kAlfrescoWorkflowJBPMEnginePrefix;
        }
        break;
            
        case AlfrescoWorkflowEngineTypeActiviti:
        {
            returnString = kAlfrescoWorkflowActivitiEnginePrefix;
        }
        break;
            
        default:
            break;
    }
    return returnString;
}

+ (NSString *)nodeGUIDFromNodeIdentifier:(NSString *)nodeIdentifier
{
    NSString *nodeGUID = [nodeIdentifier stringByReplacingOccurrencesOfString:kAlfrescoWorkflowNodeRefPrefix withString:@""];
    NSRange range = [nodeGUID rangeOfString:@";" options:NSBackwardsSearch];
    nodeGUID = [nodeGUID substringToIndex:range.location];
    
    return nodeGUID;
}

@end

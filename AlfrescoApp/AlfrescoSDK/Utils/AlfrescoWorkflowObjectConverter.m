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

#import "AlfrescoWorkflowObjectConverter.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoSession.h"
#import "AlfrescoErrors.h"
#import "AlfrescoWorkflowProcessDefinition.h"
#import "AlfrescoLog.h"

@implementation AlfrescoWorkflowObjectConverter

- (NSArray *)workflowDefinitionsFromOldJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error
{
    return [self parseJSONData:jsonData notFoundErrorCode:kAlfrescoErrorCodeWorkflowNoProcessDefinitionFound parseBlock:^id(id jsonObject, NSError *parseError) {
        if (parseError)
        {
            *error = parseError;
            return nil;
        }
        else
        {
            NSMutableArray *workflowDefinitions = [NSMutableArray array];
            id processDataResponseObject = [jsonObject valueForKey:kAlfrescoOldJSONData];
            
            if ([processDataResponseObject isKindOfClass:[NSArray class]])
            {
                for (NSDictionary *entryDictionary in processDataResponseObject)
                {
                    [workflowDefinitions addObject:[[AlfrescoWorkflowProcessDefinition alloc] initWithProperties:entryDictionary session:session]];
                }
            }
            else if ([processDataResponseObject isKindOfClass:[NSDictionary class]])
            {
                [workflowDefinitions addObject:[[AlfrescoWorkflowProcessDefinition alloc] initWithProperties:processDataResponseObject session:session]];
            }
            return workflowDefinitions;
        }
    }];
}

- (NSArray *)workflowDefinitionsFromPublicJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error
{
    return [self parseJSONData:jsonData notFoundErrorCode:kAlfrescoErrorCodeWorkflowNoProcessDefinitionFound parseBlock:^id(id jsonObject, NSError *parseError) {
        if (parseError)
        {
            *error = parseError;
            return nil;
        }
        else
        {
            NSMutableArray *workflowDefinitions = [NSMutableArray array];
            NSDictionary *listDictionary = [jsonObject valueForKey:kAlfrescoPublicJSONList];
            NSArray *processArray = [listDictionary valueForKey:kAlfrescoPublicJSONEntries];
            for (NSDictionary *entryDictionary in processArray)
            {
                [workflowDefinitions addObject:[[AlfrescoWorkflowProcessDefinition alloc] initWithProperties:entryDictionary session:session]];
            }
            
            return workflowDefinitions;
        }
    }];
}

- (NSArray *)workflowProcessesFromOldJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error
{
    return [self parseJSONData:jsonData notFoundErrorCode:kAlfrescoErrorCodeWorkflowNoProcessFound parseBlock:^id(id jsonObject, NSError *parseError) {
        if (parseError)
        {
            *error = parseError;
            return nil;
        }
        else
        {
            NSMutableArray *workflowProcesses = [NSMutableArray array];
            NSArray *processArray = [jsonObject valueForKey:kAlfrescoOldJSONData];
            for (NSDictionary *entryDictionary in processArray)
            {
                [workflowProcesses addObject:[[AlfrescoWorkflowProcess alloc] initWithProperties:entryDictionary session:session]];
            }
            return workflowProcesses;
        }
    }];
}

- (NSArray *)workflowProcessesFromPublicJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error
{
    return [self parseJSONData:jsonData notFoundErrorCode:kAlfrescoErrorCodeWorkflowNoProcessFound parseBlock:^id(id jsonObject, NSError *parseError) {
        if (parseError)
        {
            *error = parseError;
            return nil;
        }
        else
        {
            NSMutableArray *workflowProcesses = [NSMutableArray array];
            NSDictionary *listDictionary = [jsonObject valueForKey:kAlfrescoPublicJSONList];
            NSArray *processArray = [listDictionary valueForKey:kAlfrescoPublicJSONEntries];
            for (NSDictionary *entryDictionary in processArray)
            {
                [workflowProcesses addObject:[[AlfrescoWorkflowProcess alloc] initWithProperties:entryDictionary session:session]];
            }
            return workflowProcesses;
        }
    }];
}

- (NSArray *)workflowTasksFromOldJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error
{
    return [self parseJSONData:jsonData notFoundErrorCode:kAlfrescoErrorCodeWorkflowNoTaskFound parseBlock:^id(id jsonObject, NSError *parseError) {
        if (parseError)
        {
            *error = parseError;
            return nil;
        }
        else
        {
            NSMutableArray *workflowTasks = [NSMutableArray array];
            NSArray *processArray = [jsonObject valueForKey:kAlfrescoOldJSONData];
            for (NSDictionary *entryDictionary in processArray)
            {
                [workflowTasks addObject:[[AlfrescoWorkflowTask alloc] initWithProperties:entryDictionary session:session]];
            }
            return workflowTasks;
        }
    }];
}

- (NSArray *)workflowTasksFromPublicJSONData:(NSData *)jsonData session:(id<AlfrescoSession>)session conversionError:(NSError **)error
{
    return [self parseJSONData:jsonData notFoundErrorCode:kAlfrescoErrorCodeWorkflowNoTaskFound parseBlock:^id(id jsonObject, NSError *parseError) {
        if (parseError)
        {
            *error = parseError;
            return nil;
        }
        else
        {
            NSMutableArray *workflowTasks = [NSMutableArray array];
            NSDictionary *listDictionary = [jsonObject valueForKey:kAlfrescoPublicJSONList];
            NSArray *processArray = [listDictionary valueForKey:kAlfrescoPublicJSONEntries];
            for (NSDictionary *entryDictionary in processArray)
            {
                [workflowTasks addObject:[[AlfrescoWorkflowTask alloc] initWithProperties:entryDictionary session:session]];
            }
            return workflowTasks;
        }
    }];
}

- (NSString *)attachmentContainerNodeRefFromOldJSONData:(NSData *)jsonData conversionError:(NSError **)error
{
    return [self parseJSONData:jsonData notFoundErrorCode:kAlfrescoErrorCodeJSONParsing parseBlock:^id(id jsonObject, NSError *parseError) {
        if (parseError)
        {
            *error = parseError;
            return nil;
        }
        else
        {
            NSString *containerRef = nil;
            if ([jsonObject isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *jsonResponseDictionary = (NSDictionary *)jsonObject;
                NSDictionary *processDictionary = [jsonResponseDictionary valueForKey:kAlfrescoJSONData];
                
                if (processDictionary)
                {
                    NSDictionary *taskProperties = [processDictionary objectForKey:kAlfrescoOldJSONProperties];
                    containerRef = [taskProperties objectForKey:kAlfrescoOldBPMJSONPackageContainer];
                }
            }
            else
            {
                AlfrescoLogDebug(@"Parsing response, should have returned a dictionary in selector - %@", NSStringFromSelector(_cmd));
            }
            return containerRef;
        }
    }];
}

- (NSArray *)attachmentIdentifiersFromOldJSONData:(NSData *)jsonData conversionError:(NSError **)error
{
    return [self parseJSONData:jsonData notFoundErrorCode:kAlfrescoErrorCodeJSONParsing parseBlock:^id(id jsonObject, NSError *parseError) {
        if (parseError)
        {
            *error = parseError;
            return nil;
        }
        else
        {
            NSMutableArray *nodeRefIdentifiers = [NSMutableArray array];
            if ([jsonObject isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *jsonResponseDictionary = (NSDictionary *)jsonObject;
                NSArray *itemsArray = [[jsonResponseDictionary valueForKey:kAlfrescoOldJSONData] valueForKey:kAlfrescoJSONItems];
                
                if (itemsArray)
                {
                    for (NSDictionary *item in itemsArray)
                    {
                        NSString *nodeIdentifier = [item objectForKey:kAlfrescoJSONNodeRef];
                        if (nodeIdentifier)
                        {
                            [nodeRefIdentifiers addObject:nodeIdentifier];
                        }
                    }
                }
            }
            else
            {
                AlfrescoLogDebug(@"Parsing response, should have returned a dictionary in selector - %@", NSStringFromSelector(_cmd));
            }
            return nodeRefIdentifiers;
        }
    }];
}

- (NSArray *)attachmentIdentifiersFromPublicJSONData:(NSData *)jsonData conversionError:(NSError **)error
{
    return [self parseJSONData:jsonData notFoundErrorCode:kAlfrescoErrorCodeJSONParsing parseBlock:^id(id jsonObject, NSError *parseError) {
        if (parseError)
        {
            *error = parseError;
            return nil;
        }
        else
        {
            NSMutableArray *nodeRefIdentifiers = [NSMutableArray array];
            NSDictionary *listDictionary = [jsonObject valueForKey:kAlfrescoPublicJSONList];
            NSArray *nodeArray = [listDictionary valueForKey:kAlfrescoPublicJSONEntries];
            for (NSDictionary *attachmentDictionary in nodeArray)
            {
                NSDictionary *entryDictionary = [attachmentDictionary objectForKey:kAlfrescoPublicJSONEntry];
                NSString *nodeIdentifier = [entryDictionary objectForKey:kAlfrescoPublicJSONIdentifier];
                if (nodeIdentifier)
                {
                    [nodeRefIdentifiers addObject:nodeIdentifier];
                }
            }
            return nodeRefIdentifiers;
        }
    }];
}

@end

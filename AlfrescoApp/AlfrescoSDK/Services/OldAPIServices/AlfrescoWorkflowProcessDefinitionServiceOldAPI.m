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

/** AlfrescoWorkflowProcessOldAPIService
 
 Author: Tauseef Mughal (Alfresco)
 */

#import "AlfrescoWorkflowProcessDefinitionServiceOldAPI.h"
#import "AlfrescoErrors.h"
#import "AlfrescoNetworkProvider.h"
#import "AlfrescoRequest.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoPagingUtils.h"
#import "AlfrescoWorkflowUtils.h"
#import "AlfrescoWorkflowObjectConverter.h"

@interface AlfrescoWorkflowProcessDefinitionServiceOldAPI ()

@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoWorkflowObjectConverter *workflowObjectConverter;

@end

@implementation AlfrescoWorkflowProcessDefinitionServiceOldAPI

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoWorkflowBaseOldAPIURL];
        self.workflowObjectConverter = [[AlfrescoWorkflowObjectConverter alloc] init];
    }
    return self;
}

- (AlfrescoRequest *)retrieveAllProcessDefinitionsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoWorkflowProcessDefinitionOldAPI];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (!data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *workflowDefinitions = [weakSelf.workflowObjectConverter workflowDefinitionsFromOldJSONData:data session:weakSelf.session conversionError:&conversionError];
            completionBlock(workflowDefinitions, conversionError);
        }
    }];
    
    return request;
}

- (AlfrescoRequest *)retrieveProcessDefinitionsWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (!listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoWorkflowProcessDefinitionOldAPI];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (!data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *workflowDefinitions = [weakSelf.workflowObjectConverter workflowDefinitionsFromOldJSONData:data session:weakSelf.session conversionError:&conversionError];
            AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:workflowDefinitions listingContext:listingContext];
            completionBlock(pagingResult, conversionError);
        }
    }];
    
    return request;
}

- (AlfrescoRequest *)retrieveProcessDefinitionWithIdentifier:(NSString *)processIdentifier completionBlock:(AlfrescoProcessDefinitionCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    [AlfrescoErrors assertArgumentNotNil:processIdentifier argumentName:@"processIdentifier"];
    
    AlfrescoRequest *request = nil;
    
    if (!self.session.repositoryInfo.capabilities.doesSupportLikingNodes)
    {
        NSError *notSupportedError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeWorkflowFunctionNotSupported];
        completionBlock(nil, notSupportedError);
    }
    else
    {
        request = [[AlfrescoRequest alloc] init];
        NSString *workflowEnginePrefix = [AlfrescoWorkflowUtils prefixForActivitiEngineType:self.session.workflowInfo.workflowEngine];
        NSString *completeProcessIdentifier = [workflowEnginePrefix stringByAppendingString:processIdentifier];
        NSString *requestString = [kAlfrescoWorkflowSingleProcessDefinitionOldAPI stringByReplacingOccurrencesOfString:kAlfrescoProcessDefinitionID withString:completeProcessIdentifier];
        
        NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
        
        __weak typeof(self) weakSelf = self;
        [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
            if (!data)
            {
                completionBlock(nil, error);
            }
            else
            {
                NSError *conversionError = nil;
                NSArray *workflowDefinitions = [weakSelf.workflowObjectConverter workflowDefinitionsFromOldJSONData:data session:weakSelf.session conversionError:&conversionError];
                if (workflowDefinitions.count > 0)
                {
                    AlfrescoWorkflowProcessDefinition *processDefinition = [workflowDefinitions objectAtIndex:0];
                    completionBlock(processDefinition, conversionError);
                }
                else
                {
                    completionBlock(nil, conversionError);
                }
            }
        }];
    }
    return request;
}

- (AlfrescoRequest *)retrieveFormModelForProcess:(NSString *)processDefinitionId completionBlock:(AlfrescoDictionaryCompletionBlock)completionBlock
{
    NSError *notSupportedError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeWorkflowFunctionNotSupported];
    if (completionBlock != NULL)
    {
        completionBlock(nil, notSupportedError);
    }
    return nil;
}

@end

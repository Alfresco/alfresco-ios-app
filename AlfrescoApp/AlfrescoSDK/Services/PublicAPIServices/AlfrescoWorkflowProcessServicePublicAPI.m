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

/** AlfrescoWorkflowProcessPublicAPI
 
 Author: Tauseef Mughal (Alfresco)
 */

#import "AlfrescoWorkflowProcessServicePublicAPI.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoSession.h"
#import "AlfrescoWorkflowProcess.h"
#import "AlfrescoDocumentFolderService.h"
#import "AlfrescoWorkflowProcessDefinition.h"
#import "AlfrescoLog.h"
#import "AlfrescoWorkflowObjectConverter.h"

@interface AlfrescoWorkflowProcessServicePublicAPI ()

@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong, readwrite) NSDictionary *publicToPrivateStateMappings;
@property (nonatomic, strong, readwrite) NSDictionary *publicToPrivateVariableMappings;
@property (nonatomic, strong, readwrite) AlfrescoWorkflowObjectConverter *workflowObjectConverter;

@end

@implementation AlfrescoWorkflowProcessServicePublicAPI

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoWorkflowBasePublicAPIURL];
        self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
        self.publicToPrivateStateMappings = @{kAlfrescoWorkflowProcessStateAny : kAlfrescoWorkflowProcessPublicAny,
                                              kAlfrescoWorkflowProcessStateActive : kAlfrescoWorkflowProcessPublicActive,
                                              kAlfrescoWorkflowProcessStateCompleted : kAlfrescoWorkflowProcessPublicCompleted};
        self.publicToPrivateVariableMappings = @{kAlfrescoWorkflowProcessDescription : kAlfrescoPublicBPMJSONProcessDescription,
                                                 kAlfrescoWorkflowProcessPriority : kAlfrescoPublicBPMJSONProcessPriority,
                                                 kAlfrescoWorkflowProcessSendEmailNotification : kAlfrescoPublicBPMJSONProcessSendEmailNotification,
                                                 kAlfrescoWorkflowProcessDueDate : kAlfrescoPublicBPMJSONProcessDueDate,
                                                 kAlfrescoWorkflowProcessApprovalRate : kAlfrescoPublicBPMJSONProcessApprovalRate};
        self.workflowObjectConverter = [[AlfrescoWorkflowObjectConverter alloc] init];
    }
    return self;
}

- (AlfrescoRequest *)retrieveAllProcessesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    return [self retrieveProcessesInState:kAlfrescoWorkflowProcessStateAny completionBlock:completionBlock];
}

- (AlfrescoRequest *)retrieveProcessesWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    return [self retrieveProcessesInState:kAlfrescoWorkflowProcessStateAny listingContext:listingContext completionBlock:completionBlock];
}

- (AlfrescoRequest *)retrieveProcessesInState:(NSString *)state completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *whereParameterString = [NSString stringWithFormat:@"(%@=%@)", kAlfrescoWorkflowProcessStatus, [self.publicToPrivateStateMappings objectForKey:state]];
    NSString *queryString = [AlfrescoURLUtils buildQueryStringWithDictionary:@{kAlfrescoWorkflowProcessWhereParameter : whereParameterString}];
    NSString *extenstionURLString = [kAlfrescoWorkflowProcessesPublicAPI stringByAppendingString:queryString];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:extenstionURLString];
    
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.session.networkProvider executeRequestWithURL:url session:self.session method:kAlfrescoHTTPGet alfrescoRequest:alfrescoRequest completionBlock:^(NSData *data, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *workflowProcesses = [weakSelf.workflowObjectConverter workflowProcessesFromPublicJSONData:data session:weakSelf.session conversionError:&conversionError];
            completionBlock(workflowProcesses, conversionError);
        }
    }];
    return alfrescoRequest;
}

- (AlfrescoRequest *)retrieveProcessesInState:(NSString *)state listingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (!listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    NSString *whereParameterString = [NSString stringWithFormat:@"(%@=%@)", kAlfrescoWorkflowProcessStatus, [self.publicToPrivateStateMappings objectForKey:state]];
    NSString *queryString = [AlfrescoURLUtils buildQueryStringWithDictionary:@{kAlfrescoWorkflowProcessWhereParameter : whereParameterString}];
    NSString *extenstionURLString = [kAlfrescoWorkflowProcessesPublicAPI stringByAppendingString:queryString];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:extenstionURLString listingContext:listingContext];
    
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.session.networkProvider executeRequestWithURL:url session:self.session requestBody:nil method:kAlfrescoHTTPGet alfrescoRequest:alfrescoRequest completionBlock:^(NSData *data, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *workflowDefinitions = [weakSelf.workflowObjectConverter workflowProcessesFromPublicJSONData:data session:weakSelf.session conversionError:&conversionError];
            NSDictionary *pagingInfo = [AlfrescoObjectConverter paginationJSONFromData:data error:&conversionError];
            AlfrescoPagingResult *pagingResult = nil;
            if (pagingInfo)
            {
                BOOL hasMore = [[pagingInfo valueForKeyPath:kAlfrescoPublicJSONHasMoreItems] boolValue];
                int total = [[pagingInfo valueForKey:kAlfrescoPublicJSONTotalItems] intValue];
                pagingResult = [[AlfrescoPagingResult alloc] initWithArray:workflowDefinitions hasMoreItems:hasMore totalItems:total];
            }
            completionBlock(pagingResult, conversionError);
        }
    }];
    
    return alfrescoRequest;
}

- (AlfrescoRequest *)retrieveProcessWithIdentifier:(NSString *)processID completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:processID argumentName:@"processID"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoWorkflowSingleProcessPublicAPI stringByReplacingOccurrencesOfString:kAlfrescoProcessID withString:processID];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *workflowProcesses = [weakSelf.workflowObjectConverter workflowProcessesFromPublicJSONData:data session:weakSelf.session conversionError:&conversionError];
            if (conversionError)
            {
                completionBlock(nil, conversionError);
            }
            else
            {
                AlfrescoWorkflowProcess *process = [workflowProcesses objectAtIndex:0];
                completionBlock(process, conversionError);
            }
        }
    }];
    
    return request;
}

- (AlfrescoRequest *)retrieveVariablesForProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    // STUB - Not part of 1.3
    return nil;
}

- (AlfrescoRequest *)retrieveAllTasksForProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    return [self retrieveTasksForProcess:process inState:kAlfrescoWorkflowProcessStateAny completionBlock:completionBlock];
}

- (AlfrescoRequest *)retrieveTasksForProcess:(AlfrescoWorkflowProcess *)process inState:(NSString *)state completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:process argumentName:@"process"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *queryString = [AlfrescoURLUtils buildQueryStringWithDictionary:@{kAlfrescoWorkflowState : [self.publicToPrivateStateMappings objectForKey:state]}];
    NSString *requestString = [kAlfrescoWorkflowTasksForProcessPublicAPI stringByReplacingOccurrencesOfString:kAlfrescoProcessID withString:process.identifier];
    NSString *completeRequestString = [requestString stringByAppendingString:queryString];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:completeRequestString];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *tasks = [weakSelf.workflowObjectConverter workflowTasksFromPublicJSONData:data session:weakSelf.session conversionError:&conversionError];
            
            if (error)
            {
                completionBlock(nil, conversionError);
            }
            else
            {
                completionBlock(tasks, conversionError);
            }
        }
    }];
    return request;
}

//- (AlfrescoRequest *)retrieveActivitiesForProcess:(AlfrescoWorkflowProcess *)process completionBlock:(???)completionBlock;

- (AlfrescoRequest *)retrieveAttachmentsForTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    // TODO
    return nil;
}

- (AlfrescoRequest *)retrieveProcessImage:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:process argumentName:@"process"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoWorkflowProcessImagePublicAPI stringByReplacingOccurrencesOfString:kAlfrescoProcessID withString:process.identifier];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithData:data mimeType:@"application/octet-stream"];
            completionBlock(contentFile, error);
        }
    }];
    
    return request;
}

- (AlfrescoRequest *)retrieveProcessImage:(AlfrescoWorkflowProcess *)process outputStream:(NSOutputStream *)outputStream completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:process argumentName:@"process"];
    [AlfrescoErrors assertArgumentNotNil:outputStream argumentName:@"outputStream"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoWorkflowProcessImagePublicAPI stringByReplacingOccurrencesOfString:kAlfrescoProcessID withString:process.identifier];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request outputStream:outputStream completionBlock:^(NSData *data, NSError *error) {
        if (error)
        {
            completionBlock(NO, error);
        }
        else
        {
            completionBlock(YES, error);
        }
    }];
    return request;
}

- (AlfrescoRequest *)startProcessForProcessDefinition:(AlfrescoWorkflowProcessDefinition *)processDefinition assignees:(NSArray *)assignees variables:(NSDictionary *)variables attachments:(NSArray *)attachmentNodes completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:processDefinition argumentName:@"processDefinition"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSMutableDictionary *requestBody = [NSMutableDictionary dictionary];
    NSMutableArray *nodeRefs = [NSMutableArray arrayWithCapacity:attachmentNodes.count];
    
    for (id attachmentNodeObject in attachmentNodes)
    {
        if (![attachmentNodeObject isKindOfClass:[AlfrescoNode class]])
        {
            NSString *reason = [NSString stringWithFormat:@"The assignees passed in must be AlfrescoPerson instances, but instead you passed in an instance of %@", NSStringFromClass([attachmentNodeObject class])];
            @throw [NSException exceptionWithName:@"Invalid assignees value" reason:reason userInfo:nil];
        }
        
        AlfrescoNode *node = (AlfrescoNode *)attachmentNodeObject;
        [nodeRefs addObject:node.identifier];
    }
    
    if (nodeRefs.count > 0)
    {
        [requestBody setObject:nodeRefs forKey:kAlfrescoJSONItems];
    }
    
    NSArray *allVariableKeys = [variables allKeys];
    NSDictionary *completeVariables = [NSMutableDictionary dictionary];
    for (id keyObject in allVariableKeys)
    {
        NSString *key = (NSString *)keyObject;
        NSString *mappedPrivateKey = [self.publicToPrivateVariableMappings objectForKey:key];
        
        if (mappedPrivateKey)
        {
            [completeVariables setValue:[variables objectForKey:key] forKey:mappedPrivateKey];
        }
        else
        {
            [completeVariables setValue:[variables objectForKey:key] forKey:key];
        }
    }
    
    if (!assignees)
    {
        [completeVariables setValue:self.session.personIdentifier forKey:kAlfrescoPublicBPMJSONProcessAssignee];
    }
    else if (assignees.count == 1)
    {
        [completeVariables setValue:assignees[0] forKey:kAlfrescoPublicBPMJSONProcessAssignee];
    }
    else
    {
        [completeVariables setValue:assignees forKey:kAlfrescoPublicBPMJSONProcessAssignees];
    }
    
    // add the variables dictionary to the request
    if (completeVariables.count > 0)
    {
        [requestBody setValue:completeVariables forKey:kAlfrescoPublicJSONVariables];
    }
    
    [requestBody setObject:processDefinition.identifier forKey:kAlfrescoPublicJSONProcessDefinitionID];
    
    NSError *requestConversionError = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&requestConversionError];
    if (requestConversionError)
    {
        AlfrescoLogDebug(@"Parsing of dictionary failed in selector - %@", NSStringFromSelector(_cmd));
        completionBlock(nil, requestConversionError);
    }
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoWorkflowProcessesPublicAPI];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session requestBody:requestData method:kAlfrescoHTTPPOST alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            id workflowProcessesDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&conversionError];
            if (conversionError || ![workflowProcessesDictionary isKindOfClass:[NSDictionary class]])
            {
                completionBlock(nil, conversionError);
            }
            else
            {
                AlfrescoWorkflowProcess *process = [[AlfrescoWorkflowProcess alloc] initWithProperties:(NSDictionary *)workflowProcessesDictionary session:self.session];
                completionBlock(process, conversionError);
            }
        }
    }];
    return request;
}

- (AlfrescoRequest *)addAttachment:(AlfrescoNode *)node toProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    // TODO
    return nil;
}

- (AlfrescoRequest *)updateVariables:(NSDictionary *)variables forProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    // TODO
    return nil;
}

- (AlfrescoRequest *)deleteProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:process argumentName:@"process"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoWorkflowSingleProcessPublicAPI stringByReplacingOccurrencesOfString:kAlfrescoProcessID withString:process.identifier];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session method:kAlfrescoHTTPDelete alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (error)
        {
            completionBlock(NO, error);
        }
        else
        {
            completionBlock(YES, error);
        }
    }];
    return request;
}

- (AlfrescoRequest *)removeVariables:(NSArray *)variablesKeys forProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    // TODO
    return nil;
}

- (AlfrescoRequest *)removeAttachment:(AlfrescoNode *)node fromTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    // TODO
    return nil;
}

#pragma mark - Private Functions

- (void)retrieveAlfrescoNodes:(NSArray *)alfrescoNodeIdentifiers completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    __block NSMutableArray *alfrescoNodes = nil;
    __block NSInteger callBacks = 0;
    
    for (NSString *nodeIdentifier in alfrescoNodeIdentifiers)
    {
        [self.documentService retrieveNodeWithIdentifier:nodeIdentifier completionBlock:^(AlfrescoNode *node, NSError *error) {
            callBacks++;
            if (node)
            {
                [alfrescoNodes addObject:node];
            }
            
            if (callBacks == alfrescoNodeIdentifiers.count)
            {
                completionBlock(alfrescoNodes, nil);
            }
        }];
    }
}

@end

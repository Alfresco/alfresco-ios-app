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

/** AlfrescoWorkflowTaskPublicAPI
 
 Author: Tauseef Mughal (Alfresco)
 */

#import "AlfrescoWorkflowTaskPublicAPI.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoSession.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoWorkflowTask.h"
#import "AlfrescoDocumentFolderService.h"
#import "AlfrescoLog.h"
#import "AlfrescoWorkflowObjectConverter.h"
#import "AlfrescoWorkflowUtils.h"

@interface AlfrescoWorkflowTaskPublicAPI ()

@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong, readwrite) AlfrescoWorkflowObjectConverter *workflowObjectConverter;

@end

@implementation AlfrescoWorkflowTaskPublicAPI

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoWorkflowBasePublicAPIURL];
        self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
        self.workflowObjectConverter = [[AlfrescoWorkflowObjectConverter alloc] init];
    }
    return self;
}

- (AlfrescoRequest *)retrieveAllTasksWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoWorkflowTasksPublicAPI];
    
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
            NSArray *workflowTasks = [weakSelf.workflowObjectConverter workflowTasksFromPublicJSONData:data session:weakSelf.session conversionError:&conversionError];
            completionBlock(workflowTasks, conversionError);
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveTasksWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (!listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoWorkflowProcessDefinitionPublicAPI listingContext:listingContext];
    
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
            NSArray *workflowDefinitions = [weakSelf.workflowObjectConverter workflowTasksFromPublicJSONData:data session:weakSelf.session conversionError:&conversionError];;
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
    return request;
}

- (AlfrescoRequest *)retrieveTaskWithIdentifier:(NSString *)taskIdentifier completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:taskIdentifier argumentName:@"taskIdentifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoWorkflowSingleTaskPublicAPI stringByReplacingOccurrencesOfString:kAlfrescoTaskID withString:taskIdentifier];
    
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
            id workflowTaskJSONObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&conversionError];
            if (conversionError || ![workflowTaskJSONObject isKindOfClass:[NSDictionary class]])
            {
                completionBlock(nil, conversionError);
            }
            else
            {
                AlfrescoWorkflowTask *task = [[AlfrescoWorkflowTask alloc] initWithProperties:(NSDictionary *)workflowTaskJSONObject session:weakSelf.session];
                completionBlock(task, conversionError);
            }

        }
    }];
    return request;
}

//- (AlfrescoRequest *)retrieveFormModelForTask:(AlfrescoWorkflowTask *)task completionBlock:(Return Type?)completionBlock;

- (AlfrescoRequest *)retrieveAttachmentsForTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:task argumentName:@"task"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoWorkflowTaskAttachmentsPublicAPI stringByReplacingOccurrencesOfString:kAlfrescoTaskID withString:task.identifier];
    
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
            NSArray *attachmentIdentifiers = [weakSelf.workflowObjectConverter attachmentIdentifiersFromPublicJSONData:data conversionError:&conversionError];
            if (conversionError)
            {
                completionBlock(nil, conversionError);
            }
            else
            {
                [weakSelf retrieveAlfrescoNodes:attachmentIdentifiers completionBlock:completionBlock];
            }
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveVariablesForTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    // STUB - Not part of 1.3
    return nil;
}

- (AlfrescoRequest *)completeTask:(AlfrescoWorkflowTask *)task properties:(NSDictionary *)properties completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    return [self updateTaskState:task requestBody:@{kAlfrescoWorkflowState : kAlfrescoWorkflowTaskCompleted} completionBlock:completionBlock];
}

- (AlfrescoRequest *)claimTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    return [self updateTaskState:task requestBody:@{kAlfrescoWorkflowState : kAlfrescoWorkflowTaskClaim} completionBlock:completionBlock];
}

- (AlfrescoRequest *)unclaimTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    return [self updateTaskState:task requestBody:@{kAlfrescoWorkflowState : kAlfrescoWorkflowTaskUnClaim} completionBlock:completionBlock];
}

- (AlfrescoRequest *)assignTask:(AlfrescoWorkflowTask *)task toAssignee:(AlfrescoPerson *)assignee completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    return [self updateTaskState:task requestBody:@{kAlfrescoWorkflowState : kAlfrescoWorkflowTaskClaim, kAlfrescoWorkflowTaskAssignee : assignee.identifier} completionBlock:completionBlock];
}

- (AlfrescoRequest *)resolveTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    return [self updateTaskState:task requestBody:@{kAlfrescoWorkflowState : kAlfrescoWorkflowTaskResolved} completionBlock:completionBlock];
}

- (AlfrescoRequest *)addAttachment:(AlfrescoNode *)node toTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    return [self addAttachments:@[node] toTask:task completionBlock:completionBlock];
}

- (AlfrescoRequest *)addAttachments:(NSArray *)nodeArray toTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:nodeArray argumentName:@"nodeArray"];
    [AlfrescoErrors assertArgumentNotNil:task argumentName:@"task"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSMutableArray *requestBody = [NSMutableArray arrayWithCapacity:nodeArray.count];
    for (id nodeObject in nodeArray)
    {
        if (![nodeObject isKindOfClass:[AlfrescoNode class]])
        {
            NSString *exceptionMessage = [NSString stringWithFormat:@"The node array passed into %@ should contain instances of %@, instead it contained instances of %@",
                                          NSStringFromSelector(_cmd),
                                          NSStringFromClass([AlfrescoNode class]),
                                          NSStringFromClass([nodeObject class])];
            @throw [NSException exceptionWithName:@"Invaild parameters" reason:exceptionMessage userInfo:nil];
        }
        
        AlfrescoNode *currentNode = (AlfrescoNode *)nodeObject;
        // this should be fixed in the workflow api to accept complete node refs
//        [nodeRefs addObject:@{kAlfrescoJSONIdentifier : currentNode.identifier}];
        [requestBody addObject:@{kAlfrescoJSONIdentifier : [AlfrescoWorkflowUtils nodeGUIDFromNodeIdentifier:currentNode.identifier]}];
    }
    
    NSError *requestConversionError = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&requestConversionError];
    
    if (requestConversionError)
    {
        AlfrescoLogDebug(@"Request could not be parsed correctly in %@", NSStringFromSelector(_cmd));
    }
    
    NSString *requestString = [kAlfrescoWorkflowTaskAttachmentsPublicAPI stringByReplacingOccurrencesOfString:kAlfrescoTaskID withString:task.identifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session requestBody:requestData method:kAlfrescoHTTPPOST alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
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

- (AlfrescoRequest *)updateVariables:(NSDictionary *)variables forTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    // STUB - Not part of 1.3
    return nil;
}

- (AlfrescoRequest *)removeAttachment:(AlfrescoNode *)node fromTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:task argumentName:@"task"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoWorkflowTaskAttachmentsDeletePublicAPI stringByReplacingOccurrencesOfString:kAlfrescoTaskID withString:task.identifier];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoItemID withString:[AlfrescoWorkflowUtils nodeGUIDFromNodeIdentifier:node.identifier]];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session method:kAlfrescoHTTPDelete alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (error)
        {
            completionBlock(NO, nil);
        }
        else
        {
            completionBlock(YES, error);
        }
    }];
    return request;
}

- (AlfrescoRequest *)removeVariables:(NSArray *)variablesKeys forTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    // STUB - Not part of 1.3
    return nil;
}

#pragma mark - Private Functions

- (AlfrescoRequest *)updateTaskState:(AlfrescoWorkflowTask *)task requestBody:(NSDictionary *)requestDictionary completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:task argumentName:@"task"];
    [AlfrescoErrors assertArgumentNotNil:requestDictionary argumentName:@"requestDictionary"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSMutableString *requestString = [[kAlfrescoWorkflowSingleTaskPublicAPI stringByReplacingOccurrencesOfString:kAlfrescoTaskID withString:task.identifier] mutableCopy];
    
    // build the select parameters string
    NSMutableString *requestParametersString = [[NSMutableString alloc] init];
    NSArray *allParameterKeys = [requestDictionary allKeys];
    for (int i = 0; i < allParameterKeys.count; i++)
    {
        NSString *key = [allParameterKeys objectAtIndex:i];
        [requestParametersString appendString:key];
        if (i != (allParameterKeys.count - 1))
        {
            [requestParametersString appendString:@","];
        }
    }
    
    NSString *parameters = [AlfrescoURLUtils buildQueryStringWithDictionary:@{kAlfrescoWorkflowTaskSelectParameter : requestParametersString}];
    [requestString appendString:parameters];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    
    NSError *requestBodyConversionError = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDictionary options:0 error:&requestBodyConversionError];
    
    if (requestBodyConversionError)
    {
        AlfrescoLogDebug(@"Request could not be parsed correctly in %@", NSStringFromSelector(_cmd));
        return nil;
    }
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.session.networkProvider executeRequestWithURL:url session:self.session requestBody:requestData method:kAlfrescoHTTPPut alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            id workflowTaskJSONObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&conversionError];
            if (conversionError || ![workflowTaskJSONObject isKindOfClass:[NSDictionary class]])
            {
                completionBlock(nil, conversionError);
            }
            else
            {
                AlfrescoWorkflowTask *task = [[AlfrescoWorkflowTask alloc] initWithProperties:(NSDictionary *)workflowTaskJSONObject session:weakSelf.session];
                completionBlock(task, conversionError);
            }
        }
    }];
    return request;
}

- (void)retrieveAlfrescoNodes:(NSArray *)alfrescoNodeIdentifiers completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    __block NSMutableArray *alfrescoNodes = [NSMutableArray array];
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

/*******************************************************************************
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
 ******************************************************************************/

#import "AlfrescoVersionService.h"
#import "AlfrescoInternalConstants.h"
#import "CMISVersioningService.h"
#import "CMISDocument.h"
#import "CMISSession.h"
#import "AlfrescoCMISToAlfrescoObjectConverter.h"
#import "AlfrescoPagingUtils.h"
#import "AlfrescoSortingUtils.h"
#import "AlfrescoErrors.h"
#import "AlfrescoCMISUtil.h"

@interface AlfrescoVersionService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) CMISSession *cmisSession;
@property (nonatomic, strong, readwrite) AlfrescoCMISToAlfrescoObjectConverter *objectConverter;
@property (nonatomic, strong, readwrite) NSArray *supportedSortKeys;
@property (nonatomic, strong, readwrite) NSString *defaultSortKey;

@end

@implementation AlfrescoVersionService

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if (nil != self)
    {
        self.session = session;
        self.cmisSession = [session objectForParameter:kAlfrescoSessionKeyCmisSession];
        self.objectConverter = [[AlfrescoCMISToAlfrescoObjectConverter alloc] initWithSession:self.session];
        self.defaultSortKey = kAlfrescoSortByName;
        self.supportedSortKeys = [NSArray arrayWithObjects:kAlfrescoSortByName, kAlfrescoSortByTitle, kAlfrescoSortByDescription, kAlfrescoSortByCreatedAt, kAlfrescoSortByModifiedAt, nil];
    }
    return self;
}


- (AlfrescoRequest *)retrieveAllVersionsOfDocument:(AlfrescoDocument *)document
                      completionBlock:(AlfrescoArrayCompletionBlock)completionBlock 
{
    [AlfrescoErrors assertArgumentNotNil:document argumentName:@"document"];
    [AlfrescoErrors assertArgumentNotNil:document.identifier argumentName:@"document.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
//    __weak AlfrescoVersionService *weakSelf = self;
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession.binding.versioningService
                           retrieveAllVersions:document.identifier
                           filter:nil
                           includeAllowableActions:YES
                           completionBlock:^(NSArray *allVersions, NSError *error){
         if (nil == allVersions)
         {
             NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
             completionBlock(nil, alfrescoError);
         }
         else
         {
             NSMutableArray *alfrescoVersions = [NSMutableArray array];
             for (CMISObjectData *cmisData in allVersions)
             {
                 AlfrescoNode *alfrescoNode = [self.objectConverter nodeFromCMISObjectData:cmisData];
                 [alfrescoVersions addObject:alfrescoNode];
             }
             NSArray *sortedAlfrescoVersionArray = [AlfrescoSortingUtils sortedArrayForArray:alfrescoVersions sortKey:self.defaultSortKey ascending:YES];
             completionBlock(sortedAlfrescoVersionArray, nil);
             
         }
     }];
    return request;
}

- (AlfrescoRequest *)retrieveAllVersionsOfDocument:(AlfrescoDocument *)document
                       listingContext:(AlfrescoListingContext *)listingContext
                      completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:document argumentName:@"document"];
    [AlfrescoErrors assertArgumentNotNil:document.identifier argumentName:@"document.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
//    __weak AlfrescoVersionService *weakSelf = self;
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession.binding.versioningService
                           retrieveAllVersions:document.identifier
                           filter:nil
                           includeAllowableActions:YES
                           completionBlock:^(NSArray *allVersions, NSError *error){
         if (nil == allVersions)
         {
             NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
             completionBlock(nil, alfrescoError);
         }
         else
         {
             NSMutableArray *alfrescoVersions = [NSMutableArray array];
             for (CMISObjectData *cmisData in allVersions)
             {
                 AlfrescoNode *alfrescoNode = [self.objectConverter nodeFromCMISObjectData:cmisData];
                 [alfrescoVersions addObject:alfrescoNode];
             }
             NSArray *sortedVersionArray = [AlfrescoSortingUtils sortedArrayForArray:alfrescoVersions
                                                                             sortKey:listingContext.sortProperty
                                                                       supportedKeys:self.supportedSortKeys
                                                                          defaultKey:self.defaultSortKey
                                                                           ascending:listingContext.sortAscending];
             AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedVersionArray listingContext:listingContext];
             completionBlock(pagingResult, nil);
             
         }
     }];
    return request;
}

@end

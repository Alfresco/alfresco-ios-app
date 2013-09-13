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

#import "AlfrescoSearchService.h"
#import "AlfrescoErrors.h"
#import "AlfrescoCMISToAlfrescoObjectConverter.h"
#import "AlfrescoPagingUtils.h"
#import "CMISConstants.h"
#import "CMISDocument.h"
#import "CMISSession.h"
#import "CMISDiscoveryService.h"
#import "CMISPagedResult.h"
#import "CMISObjectList.h"
#import "CMISQueryResult.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoSortingUtils.h"
#import "AlfrescoCMISUtil.h"

@interface AlfrescoSearchService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) CMISSession *cmisSession;
@property (nonatomic, strong, readwrite) AlfrescoCMISToAlfrescoObjectConverter *objectConverter;
@property (nonatomic, strong, readwrite) NSArray *supportedSortKeys;
@property (nonatomic, strong, readwrite) NSString *defaultSortKey;
@end

@implementation AlfrescoSearchService


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



- (AlfrescoRequest *)searchWithStatement:(NSString *)statement
                                language:(AlfrescoSearchLanguage)language
                         completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:statement argumentName:@"statement"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    if (AlfrescoSearchLanguageCMIS == language)
    {
        request.httpRequest = [self.cmisSession.binding.discoveryService
         query:statement
         searchAllVersions:NO
         relationships:CMISIncludeRelationshipBoth
         renditionFilter:nil
         includeAllowableActions:YES
         maxItems:[NSNumber numberWithInt:self.session.defaultListingContext.maxItems]
         skipCount:[NSNumber numberWithInt:self.session.defaultListingContext.skipCount]
         completionBlock:^(CMISObjectList *objectList, NSError *error){
             if (nil == objectList)
             {
                 NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                 completionBlock(nil, alfrescoError);
             }
             else
             {
                 NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[objectList.objects count]];
                 for (CMISObjectData *queryData in objectList.objects)
                 {
                     [resultArray addObject:[self.objectConverter nodeFromCMISObjectData:queryData]];
                 }
                 NSArray *sortedResultArray = [AlfrescoSortingUtils sortedArrayForArray:resultArray sortKey:self.defaultSortKey ascending:YES];
                 completionBlock(sortedResultArray, nil);
             }
             
        }];
    }
    return request;
    
}


- (AlfrescoRequest *)searchWithStatement:(NSString *)statement
                                language:(AlfrescoSearchLanguage)language
                          listingContext:(AlfrescoListingContext *)listingContext
                         completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:statement argumentName:@"statement"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }    
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];

    if (AlfrescoSearchLanguageCMIS == language)
    {
        request.httpRequest = [self.cmisSession.binding.discoveryService
         query:statement
         searchAllVersions:NO
         relationships:CMISIncludeRelationshipBoth
         renditionFilter:nil
         includeAllowableActions:YES
         maxItems:[NSNumber numberWithInt:listingContext.maxItems]
         skipCount:[NSNumber numberWithInt:listingContext.skipCount]
         completionBlock:^(CMISObjectList *objectList, NSError *error){
             if (nil == objectList)
             {
                 NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                 completionBlock(nil, alfrescoError);
             }
             else
             {
                 NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[objectList.objects count]];
                 for (CMISObjectData *queryData in objectList.objects)
                 {
                     [resultArray addObject:[self.objectConverter nodeFromCMISObjectData:queryData]];
                 }
                 NSArray *sortedArray = [AlfrescoSortingUtils sortedArrayForArray:resultArray
                                                                          sortKey:listingContext.sortProperty
                                                                    supportedKeys:self.supportedSortKeys
                                                                       defaultKey:self.defaultSortKey
                                                                        ascending:listingContext.sortAscending];
                 AlfrescoPagingResult *pagingResult = [[AlfrescoPagingResult alloc] initWithArray:sortedArray hasMoreItems:NO totalItems:sortedArray.count];
                 completionBlock(pagingResult, nil);
             }
             
         }];
    }
    return request;
    
}

- (AlfrescoRequest *)searchWithKeywords:(NSString *)keywords
                                options:(AlfrescoKeywordSearchOptions *)options
                        completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:keywords argumentName:@"keywords"];
    [AlfrescoErrors assertArgumentNotNil:options argumentName:@"options"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];

    NSString *query = [self createSearchQuery:keywords options:options];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession query:query searchAllVersions:NO completionBlock:^(CMISPagedResult *pagedResult, NSError *error){
        if (nil == pagedResult)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            NSMutableArray *resultArray = [NSMutableArray array];
            for (CMISQueryResult *queryResult in pagedResult.resultArray)
            {
                [resultArray addObject:[self.objectConverter documentFromCMISQueryResult:queryResult]];
            }
            NSArray *sortedArray = [AlfrescoSortingUtils sortedArrayForArray:resultArray sortKey:self.defaultSortKey ascending:YES];
            completionBlock(sortedArray, nil);
        }
    }];
    return request;
}

- (AlfrescoRequest *)searchWithKeywords:(NSString *)keywords
                                options:(AlfrescoKeywordSearchOptions *)options
                         listingContext:(AlfrescoListingContext *)listingContext
                        completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:keywords argumentName:@"keywords"];
    [AlfrescoErrors assertArgumentNotNil:options argumentName:@"options"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }

    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    NSString *query = [self createSearchQuery:keywords options:options];
    CMISOperationContext *operationContext = [AlfrescoPagingUtils operationContextFromListingContext:listingContext];
    request.httpRequest = [self.cmisSession query:query searchAllVersions:NO operationContext:operationContext completionBlock:^(CMISPagedResult *pagedResult, NSError *error){
        if (nil == pagedResult)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            NSMutableArray *resultArray = [NSMutableArray array];
            for (CMISQueryResult *queryResult in pagedResult.resultArray)
            {
                [resultArray addObject:[self.objectConverter documentFromCMISQueryResult:queryResult]];
            }
            NSArray *sortedArray = [AlfrescoSortingUtils sortedArrayForArray:resultArray sortKey:self.defaultSortKey ascending:YES];
            AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedArray listingContext:listingContext];
            completionBlock(pagingResult, nil);            
        }        
    }];    
    return request;
}


#pragma mark Internal methods

- (NSString *) createSearchQuery:(NSString *)keywords  options:(AlfrescoKeywordSearchOptions *)options
{
    NSMutableString *searchQuery = [NSMutableString stringWithString:@"SELECT * FROM cmis:document WHERE ("];
    BOOL firstKeyword = YES;
    NSArray *keywordArray = [keywords componentsSeparatedByString:@" "];
    for (NSString *keyword in keywordArray)
    {
        if (!firstKeyword)
        {
            [searchQuery appendString:@" OR "];
        }
        else 
        {
            firstKeyword = NO;
        }
        
        // the includeALL option overrides all others
        if (options.includeAll)
        {
            [searchQuery appendString:[NSString stringWithFormat:@"CONTAINS('ALL:%@%@')", keyword, (options.exactMatch ? @"*" : @"")]];
        }
        else
        {
            if (options.exactMatch)
            {
                [searchQuery appendString:[NSString stringWithFormat:@"%@ = '%@'", kCMISPropertyName, keyword]];
            }
            else 
            {
                [searchQuery appendString:[NSString stringWithFormat:@"CONTAINS('~%@:%@')", kCMISPropertyName, keyword]];
            }
            
            if (options.includeContent)
            {
                [searchQuery appendString:[NSString stringWithFormat:@" OR CONTAINS('%@')", keyword]];
            }
        }
    }
    [searchQuery appendString:@")"];
    if (options.includeDescendants)
    {
        if (nil != options.folder && nil != options.folder.identifier) 
        {
            [searchQuery appendString:[NSString stringWithFormat:@" AND IN_TREE('%@')", options.folder.identifier]];
        }
    }
    
    return searchQuery;
    
}


@end

/*******************************************************************************
 * Copyright (C) 2005-2012 Alfresco Software Limited.
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

#import "AlfrescoPagingUtils.h"
#import "CMISQueryResult.h"
#import "CMISOperationContext.h"
#import "CMISPagedResult.h"

@implementation AlfrescoPagingUtils

+ (CMISOperationContext *) operationContextFromListingContext:(AlfrescoListingContext *)listingContext
{
    CMISOperationContext *operationContext = [CMISOperationContext defaultOperationContext];
    operationContext.maxItemsPerPage = listingContext.maxItems;
    operationContext.skipCount = listingContext.skipCount;
    operationContext.orderBy = listingContext.sortProperty;
    return operationContext;
}

+ (AlfrescoPagingResult *) pagedResultFromArray:(CMISPagedResult *)cmisResult objectConverter:(AlfrescoCMISToAlfrescoObjectConverter *)converter
{
    NSMutableArray *children = [NSMutableArray arrayWithCapacity:[cmisResult.resultArray count]];
    for (id object in cmisResult.resultArray)
    {
        if ([object isKindOfClass:[CMISQueryResult class]])
        {
            [children addObject:[converter documentFromCMISQueryResult:object]];
        }
        else
        {
            [children addObject:[converter nodeFromCMISObject:object]];
        }
    }
    AlfrescoPagingResult *pagingResult = [[AlfrescoPagingResult alloc] initWithArray:children
                                                                        hasMoreItems:cmisResult.hasMoreItems
                                                                          totalItems:cmisResult.numItems];
    return pagingResult;
}

+ (AlfrescoPagingResult *) pagedResultFromArray:(NSArray *)nonPagedArray listingContext:(AlfrescoListingContext *)listingContext
{
    int totalItems = 0;
    int totalItemsAdded = 0;
    NSMutableArray *resultArray = [NSMutableArray array];
    for (id entry in nonPagedArray)
    {
        totalItems = totalItems + 1;
        if (listingContext.skipCount == 0 || listingContext.skipCount < totalItems)
        {
            totalItemsAdded = totalItemsAdded + 1;
            if (listingContext.maxItems >= totalItemsAdded)
            {
                [resultArray addObject:entry];
            }
        }
    }
    
    BOOL hasMoreItems = NO;
    if ([resultArray count] + listingContext.skipCount < totalItems)
    {
        hasMoreItems = YES;
    }
    
    
    AlfrescoPagingResult *pagingResult = [[AlfrescoPagingResult alloc] initWithArray:resultArray hasMoreItems:hasMoreItems totalItems:totalItems];
    return pagingResult;
}

@end

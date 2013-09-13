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

#import "AlfrescoCloudDocumentFolderService.h"
#import "AlfrescoErrors.h"
#import "CMISOperationContext.h"
#import "CMISSession.h"
#import "AlfrescoCMISUtil.h"
#import "CMISDocument.h"
#import "CMISRendition.h"
#import "AlfrescoLog.h"
#import "AlfrescoFileManager.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoFavoritesCache.h"
#import "AlfrescoSortingUtils.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoObjectConverter.h"
#import "AlfrescoPagingUtils.h"

@interface AlfrescoCloudDocumentFolderService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) CMISSession *cmisSession;
@property (nonatomic, strong, readwrite) AlfrescoFavoritesCache *favoritesCache;
@property (nonatomic, strong, readwrite) NSString *defaultSortKey;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@end

@implementation AlfrescoCloudDocumentFolderService

- (id)initWithSession:(id<AlfrescoSession>)session
{
    if (self = [super initWithSession:session])
    {
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoCloudAPIPath];

        NSString *favoritesCacheKey = [NSString stringWithFormat:@"%@%@", kAlfrescoSessionInternalCache, NSStringFromClass([AlfrescoFavoritesCache class])];
        id cachedObj = [self.session objectForParameter:favoritesCacheKey];
        if (cachedObj)
        {
            AlfrescoLogDebug(@"Using existing AlfrescoFavoritesCache for key %@", favoritesCacheKey);
            self.favoritesCache = (AlfrescoFavoritesCache *)cachedObj;
        }
        else
        {
            AlfrescoLogDebug(@"Creating new AlfrescoFavoritesCache for key %@", favoritesCacheKey);
            self.favoritesCache = [AlfrescoFavoritesCache favoritesCacheForSession:session];
        }
    }
    return self;
}

- (AlfrescoRequest *)retrieveRenditionOfNode:(AlfrescoNode *)node
                               renditionName:(NSString *)renditionName
                             completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:renditionName argumentName:@"renditionName"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    CMISOperationContext *operationContext = [CMISOperationContext defaultOperationContext];
    operationContext.renditionFilterString = @"cmis:thumbnail";
    request.httpRequest = [self.cmisSession retrieveObject:node.identifier operationContext:operationContext completionBlock:^(CMISObject *cmisObject, NSError *error) {
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else if([cmisObject isKindOfClass:[CMISFolder class]])
        {
            NSError *wrongTypeError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderNoThumbnail];
            completionBlock(nil, wrongTypeError);
        }
        else
        {
            NSError *renditionsError = nil;
            CMISDocument *document = (CMISDocument *)cmisObject;
            NSArray *renditions = document.renditions;
            if (nil == renditions)
            {
                renditionsError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderNoThumbnail];
                completionBlock(nil, renditionsError);
            }
            else if(0 == renditions.count)
            {
                renditionsError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderNoThumbnail];
                completionBlock(nil, renditionsError);
            }
            else
            {
                CMISRendition *thumbnailRendition = (CMISRendition *)[renditions objectAtIndex:0];
                AlfrescoLogDebug(@"************* NUMBER OF RENDITION OBJECTS FOUND IS %d and the document ID is %@",renditions.count, thumbnailRendition.renditionDocumentId);
                NSString *tmpFileName = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingFormat:@"%@.png",node.name];
                AlfrescoLogDebug(@"************* DOWNLOADING TO FILE %@",tmpFileName);
                request.httpRequest = [thumbnailRendition downloadRenditionContentToFile:tmpFileName completionBlock:^(NSError *downloadError) {
                    if (downloadError)
                    {
                        NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:downloadError];
                        completionBlock(nil, alfrescoError);
                    }
                    else
                    {
                        AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:[NSURL fileURLWithPath:tmpFileName] mimeType:@"image/png"];
                        completionBlock(contentFile, nil);
                    }
                } progressBlock:^(unsigned long long bytesDownloaded, unsigned long long bytesTotal) {
                    AlfrescoLogDebug(@"************* PROGRESS DOWNLOADING FILE with %llu bytes downloaded from %llu total ",bytesDownloaded, bytesTotal);
                }];
            }
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveRenditionOfNode:(AlfrescoNode *)node
                               renditionName:(NSString *)renditionName
                                outputStream:(NSOutputStream *)outputStream
                             completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:renditionName argumentName:@"renditionName"];
    [AlfrescoErrors assertArgumentNotNil:outputStream argumentName:@"outputStream"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    CMISOperationContext *operationContext = [CMISOperationContext defaultOperationContext];
    operationContext.renditionFilterString = @"cmis:thumbnail";
    request.httpRequest = [self.cmisSession retrieveObject:node.identifier operationContext:operationContext completionBlock:^(CMISObject *cmisObject, NSError *error) {
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(NO, alfrescoError);
        }
        else if([cmisObject isKindOfClass:[CMISFolder class]])
        {
            NSError *wrongTypeError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderNoThumbnail];
            completionBlock(NO, wrongTypeError);
        }
        else
        {
            NSError *renditionsError = nil;
            CMISDocument *document = (CMISDocument *)cmisObject;
            NSArray *renditions = document.renditions;
            if (nil == renditions)
            {
                renditionsError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderNoThumbnail];
                completionBlock(NO, renditionsError);
            }
            else if (0 == renditions.count)
            {
                renditionsError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderNoThumbnail];
                completionBlock(NO, renditionsError);
            }
            else
            {
                CMISRendition *thumbnailRendition = (CMISRendition *)[renditions objectAtIndex:0];
                AlfrescoLogDebug(@"************* NUMBER OF RENDITION OBJECTS FOUND IS %d and the document ID is %@", renditions.count, thumbnailRendition.renditionDocumentId);
                request.httpRequest = [thumbnailRendition downloadRenditionContentToOutputStream:outputStream completionBlock:^(NSError *downloadError) {
                    if (downloadError)
                    {
                        NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:downloadError];
                        completionBlock(NO, alfrescoError);
                    }
                    else
                    {
                        completionBlock(YES, nil);
                    }
                } progressBlock:^(unsigned long long bytesDownloaded, unsigned long long bytesTotal) {
                    AlfrescoLogDebug(@"************* PROGRESS DOWNLOADING FILE with %llu bytes downloaded from %llu total ",bytesDownloaded, bytesTotal);
                }];
            }
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveFavoriteDocumentsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSArray *favoriteDocuments = [self.favoritesCache favoriteDocuments];
    if (favoriteDocuments.count > 0 && !self.favoritesCache.hasMoreFavoriteDocuments)
    {
        NSArray *sortedDocuments = [AlfrescoSortingUtils sortedArrayForArray:favoriteDocuments sortKey:self.defaultSortKey ascending:YES];
        completionBlock(sortedDocuments, nil);
        return nil;
    }
    AlfrescoRequest *request = [self favoritesForType:AlfrescoFavoriteDocument listingContext:nil arrayCompletionBlock:completionBlock pagingCompletionBlock:nil];
    return request;
}

- (AlfrescoRequest *)retrieveFavoriteDocumentsWithListingContext:(AlfrescoListingContext *)listingContext
                                                 completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    NSArray *favoriteDocuments = [self.favoritesCache favoriteDocuments];
    if (favoriteDocuments.count > 0 && !self.favoritesCache.hasMoreFavoriteDocuments)
    {
        NSArray *sortedDocuments = [AlfrescoSortingUtils sortedArrayForArray:favoriteDocuments sortKey:self.defaultSortKey ascending:YES];
        AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedDocuments listingContext:listingContext];
        completionBlock(pagingResult, nil);
        return nil;
    }
    AlfrescoRequest *request = [self favoritesForType:AlfrescoFavoriteDocument listingContext:listingContext arrayCompletionBlock:nil pagingCompletionBlock:completionBlock];
    return request;
}

- (AlfrescoRequest *)retrieveFavoriteFoldersWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSArray *favoriteFolders = [self.favoritesCache favoriteFolders];
    if (favoriteFolders.count > 0 && !self.favoritesCache.hasMoreFavoriteFolders)
    {
        NSArray *sortedFolders = [AlfrescoSortingUtils sortedArrayForArray:favoriteFolders sortKey:self.defaultSortKey ascending:YES];
        completionBlock(sortedFolders, nil);
        return nil;
    }
    AlfrescoRequest *request = [self favoritesForType:AlfrescoFavoriteFolder listingContext:nil arrayCompletionBlock:completionBlock pagingCompletionBlock:nil];
    return request;
}

- (AlfrescoRequest *)retrieveFavoriteFoldersWithListingContext:(AlfrescoListingContext *)listingContext
                                               completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    NSArray *favoriteFolders = [self.favoritesCache favoriteFolders];
    if (favoriteFolders.count > 0 && !self.favoritesCache.hasMoreFavoriteFolders)
    {
        NSArray *sortedFolders = [AlfrescoSortingUtils sortedArrayForArray:favoriteFolders sortKey:self.defaultSortKey ascending:YES];
        AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedFolders listingContext:listingContext];
        completionBlock(pagingResult, nil);
        return nil;
    }
    AlfrescoRequest *request = [self favoritesForType:AlfrescoFavoriteFolder listingContext:listingContext arrayCompletionBlock:nil pagingCompletionBlock:completionBlock];
    return request;
}

- (AlfrescoRequest *)retrieveFavoriteNodesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSArray *favoriteNodes = [self.favoritesCache allFavorites];
    if (favoriteNodes.count > 0 && !self.favoritesCache.hasMoreFavoriteNodes)
    {
        NSArray *sortedNodes = [AlfrescoSortingUtils sortedArrayForArray:favoriteNodes sortKey:self.defaultSortKey ascending:YES];
        completionBlock(sortedNodes, nil);
        return nil;
    }
    AlfrescoRequest *request = [self favoritesForType:AlfrescoFavoriteNode listingContext:nil arrayCompletionBlock:completionBlock pagingCompletionBlock:nil];
    return request;
}

- (AlfrescoRequest *)retrieveFavoriteNodesWithListingContext:(AlfrescoListingContext *)listingContext
                                             completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    NSArray *favoriteNodes = [self.favoritesCache allFavorites];
    if (favoriteNodes.count > 0 && !self.favoritesCache.hasMoreFavoriteNodes)
    {
        NSArray *sortedNodes = [AlfrescoSortingUtils sortedArrayForArray:favoriteNodes sortKey:self.defaultSortKey ascending:YES];
        AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedNodes listingContext:listingContext];
        completionBlock(pagingResult, nil);
        return nil;
    }
    AlfrescoRequest *request = [self favoritesForType:AlfrescoFavoriteNode listingContext:listingContext arrayCompletionBlock:nil pagingCompletionBlock:completionBlock];
    return request;
}

- (AlfrescoRequest *)isFavorite:(AlfrescoNode *)node
              	completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoCloudFavorite stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoNodeRef withString:node.identifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString listingContext:nil];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        
        if (error && error.code != kAlfrescoErrorCodeHTTPResponse)
        {
            completionBlock(NO, NO, error);
        }
        else
        {
            completionBlock(YES, (data != nil), nil);
        }
    }];
    
    return request;
}

- (AlfrescoRequest *)addFavorite:(AlfrescoNode *)node
                 completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoCloudAddFavoriteAPI listingContext:nil];
    NSData *bodyData = [self jsonDataForAddingFavorite:node];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:bodyData
                                                 method:kAlfrescoHTTPPOST
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error) {
                                            if (error)
                                            {
                                                completionBlock(NO, NO, error);
                                            }
                                            else
                                            {
                                                [self.favoritesCache addFavorite:node];
                                                completionBlock(YES, YES, error);
                                            }
                                        }];
    return request;
}

- (AlfrescoRequest *)removeFavorite:(AlfrescoNode *)node
                    completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoCloudFavorite stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
    NSString *nodeIdWithoutVersionNumber = [AlfrescoObjectConverter nodeRefWithoutVersionID:node.identifier];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoNodeRef withString:nodeIdWithoutVersionNumber];
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString listingContext:nil];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                                 method:kAlfrescoHTTPDelete
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error) {
                                            if (error)
                                            {
                                                completionBlock(NO, NO, error);
                                            }
                                            else
                                            {
                                                [self.favoritesCache removeFavorite:node];
                                                completionBlock(YES, NO, error);
                                            }
                                        }];
    return request;
}

#pragma mark - private methods

- (AlfrescoRequest *)favoritesForType:(AlfrescoFavoriteType)type
                       listingContext:(AlfrescoListingContext *)listingContext
                 arrayCompletionBlock:(AlfrescoArrayCompletionBlock)arrayCompletionBlock
                pagingCompletionBlock:(AlfrescoPagingResultCompletionBlock)pagingCompletionBlock
{
    NSString *requestString = nil;
    NSURL *url = nil;
    if (type == AlfrescoFavoriteDocument)
    {
        requestString = [kAlfrescoCloudFavoriteDocumentsAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
    }
    else if (type == AlfrescoFavoriteFolder)
    {
        requestString = [kAlfrescoCloudFavoriteFoldersAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
    }
    else
    {
        requestString = [kAlfrescoCloudFavoritesAllAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
    }
    url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString listingContext:listingContext];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    BOOL usePaging = (nil == arrayCompletionBlock);
    
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (nil == data)
        {
            [self errorForCompletionBlocks:error arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
        }
        else
        {
            NSError *conversionError = nil;
            NSDictionary *pagingInfo = [AlfrescoObjectConverter paginationJSONFromData:data error:&conversionError];
            [self favoritesArrayWithData:data completionBlock:^(NSArray *favorites, NSError *conversionError) {
                
                if (error)
                {
                    [self errorForCompletionBlocks:conversionError arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
                }
                else
                {
                    if (favorites && pagingInfo)
                    {
                        NSArray *sortedFavorites = [AlfrescoSortingUtils sortedArrayForArray:favorites sortKey:self.defaultSortKey ascending:YES];
                        BOOL hasMoreFavorites = [[pagingInfo valueForKeyPath:kAlfrescoCloudJSONHasMoreItems] boolValue];
                        int totalFavorites = -1;
                        if ([pagingInfo valueForKey:kAlfrescoCloudJSONTotalItems])
                        {
                            totalFavorites = [[pagingInfo valueForKey:kAlfrescoCloudJSONTotalItems] intValue];
                        }
                        [self.favoritesCache addFavorites:sortedFavorites type:type hasMoreFavorites:hasMoreFavorites totalFavorites:totalFavorites];
                        
                        NSArray *resultsArray = nil;
                        switch (type)
                        {
                            case AlfrescoFavoriteDocument:
                            {
                                hasMoreFavorites = self.favoritesCache.hasMoreFavoriteDocuments;
                                totalFavorites = self.favoritesCache.totalDocuments;
                                resultsArray = [self.favoritesCache favoriteDocuments];
                            }
                                break;
                            case AlfrescoFavoriteFolder:
                            {
                                hasMoreFavorites = self.favoritesCache.hasMoreFavoriteFolders;
                                totalFavorites = self.favoritesCache.totalFolders;
                                resultsArray = [self.favoritesCache favoriteFolders];
                            }
                                break;
                            case AlfrescoFavoriteNode:
                            {
                                hasMoreFavorites = self.favoritesCache.hasMoreFavoriteNodes;
                                totalFavorites = self.favoritesCache.totalNodes;
                                resultsArray = [self.favoritesCache allFavorites];
                            }
                                break;
                        }
                        if (usePaging)
                        {
                            AlfrescoPagingResult *pagingResult = [[AlfrescoPagingResult alloc] initWithArray:resultsArray hasMoreItems:hasMoreFavorites totalItems:totalFavorites];
                            pagingCompletionBlock(pagingResult, nil);
                        }
                        else
                        {
                            arrayCompletionBlock(resultsArray, nil);
                        }
                    }
                    else
                    {
                        [self errorForCompletionBlocks:conversionError arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
                    }
                }
            }];
        }
    }];
    
    return request;
}

#pragma mark - private methods

- (void)favoritesArrayWithData:(NSData *)data completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    NSError *conversionError = nil;
    NSArray *entriesArray = [AlfrescoObjectConverter arrayJSONEntriesFromListData:data error:&conversionError];
    
    __block NSInteger total = entriesArray.count;
    NSMutableArray *resultsArray = [NSMutableArray arrayWithCapacity:entriesArray.count];
    
    if (nil != entriesArray && entriesArray.count > 0)
    {
        NSArray *identifiers = [entriesArray valueForKeyPath:@"entry.targetGuid"];
        
        for (NSString *identifier in identifiers)
        {
            [self retrieveNodeWithIdentifier:identifier completionBlock:^(AlfrescoNode *node, NSError *error) {
                
                if (!error)
                {
                    [resultsArray addObject:node];
                }
                total--;
                
                if (total == 0)
                {
                    completionBlock(resultsArray, nil);
                }
            }];
        }
    }
    else
    {
        completionBlock(resultsArray, conversionError);
    }
}

- (NSData *)jsonDataForAddingFavorite:(AlfrescoNode *)node
{
    NSString *nodeIdWithoutVersionNumber = [AlfrescoObjectConverter nodeRefWithoutVersionID:node.identifier];
    NSDictionary *nodeId = [NSDictionary dictionaryWithObject:nodeIdWithoutVersionNumber forKey:kAlfrescoJSONGUID];
    NSDictionary *fileFolder = nil;
    if (node.isDocument)
    {
        fileFolder = [NSDictionary dictionaryWithObject:nodeId forKey:kAlfrescoJSONFile];
    }
    else
    {
        fileFolder = [NSDictionary dictionaryWithObject:nodeId forKey:kAlfrescoJSONFolder];
    }
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObject:fileFolder forKey:kAlfrescoJSONTarget];
    NSError *error = nil;
    return [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
}

- (void)errorForCompletionBlocks:(NSError *)error
            arrayCompletionBlock:(AlfrescoArrayCompletionBlock)arrayCompletionBlock
           pagingCompletionBlock:(AlfrescoPagingResultCompletionBlock)pagingCompletionBlock
{
    if (arrayCompletionBlock)
    {
        arrayCompletionBlock(nil, error);
    }
    else
    {
        pagingCompletionBlock(nil, error);
    }
}

@end

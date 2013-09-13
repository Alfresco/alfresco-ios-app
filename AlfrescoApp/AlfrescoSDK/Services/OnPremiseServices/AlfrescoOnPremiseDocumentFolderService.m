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

#import "AlfrescoOnPremiseDocumentFolderService.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoFavoritesCache.h"
#import "AlfrescoSortingUtils.h"
#import "AlfrescoLog.h"
#import "AlfrescoPagingUtils.h"
#import "AlfrescoSearchService.h"

@interface AlfrescoOnPremiseDocumentFolderService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoFavoritesCache *favoritesCache;
@property (nonatomic, strong, readwrite) NSString *defaultSortKey;
@end

@implementation AlfrescoOnPremiseDocumentFolderService

- (id)initWithSession:(id<AlfrescoSession>)session
{
    if (self = [super initWithSession:session])
    {
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoOnPremiseAPIPath];
        
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
            self.favoritesCache = [AlfrescoFavoritesCache favoritesCacheForSession:self.session];
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
    
    NSURL *url = [self renditionURLForNode:node renditionName:renditionName];
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:alfrescoRequest completionBlock:^(NSData *responseData, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            AlfrescoContentFile *thumbnail = [[AlfrescoContentFile alloc] initWithData:responseData mimeType:@"application/octet-stream"];
            completionBlock(thumbnail, nil);
        }
    }];
    return alfrescoRequest;
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
    
    NSURL *url = [self renditionURLForNode:node renditionName:renditionName];
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:alfrescoRequest outputStream:outputStream completionBlock:^(NSData *responseData, NSError *error) {
        if (error)
        {
            completionBlock(NO, error);
        }
        else
        {
            completionBlock(YES, nil);
        }
    }];
    return alfrescoRequest;
}

- (AlfrescoRequest *)retrieveFavoriteDocumentsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSArray *favouriteDocuments = [self.favoritesCache favoriteDocuments];
    if (favouriteDocuments.count > 0)
    {
        NSArray *sortedFavoriteDocuments = [AlfrescoSortingUtils sortedArrayForArray:favouriteDocuments sortKey:self.defaultSortKey ascending:YES];
        AlfrescoLogDebug(@"returning cached favorite documents %d", sortedFavoriteDocuments.count);
        completionBlock(sortedFavoriteDocuments, nil);
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
    
    NSArray *favouriteDocuments = [self.favoritesCache favoriteDocuments];
    if (favouriteDocuments.count > 0)
    {
        NSArray *sortedFavoriteDocuments = [AlfrescoSortingUtils sortedArrayForArray:favouriteDocuments sortKey:self.defaultSortKey ascending:YES];
        AlfrescoLogDebug(@"returning cached favorite documents %d", sortedFavoriteDocuments.count);
        AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedFavoriteDocuments listingContext:listingContext];
        completionBlock(pagingResult, nil);
        return nil;
    }
    AlfrescoRequest *request = [self favoritesForType:AlfrescoFavoriteDocument listingContext:listingContext arrayCompletionBlock:nil pagingCompletionBlock:completionBlock];
    return request;
}

- (AlfrescoRequest *)retrieveFavoriteFoldersWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSArray *favouriteFolders = [self.favoritesCache favoriteFolders];
    if (favouriteFolders.count > 0)
    {
        NSArray *sortedFavoriteFolders = [AlfrescoSortingUtils sortedArrayForArray:favouriteFolders sortKey:self.defaultSortKey ascending:YES];
        AlfrescoLogDebug(@"returning cached favorite folders %d", sortedFavoriteFolders.count);
        completionBlock(sortedFavoriteFolders, nil);
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
    
    NSArray *favouriteFolders = [self.favoritesCache favoriteFolders];
    if (favouriteFolders.count > 0)
    {
        NSArray *sortedFavoriteFolders = [AlfrescoSortingUtils sortedArrayForArray:favouriteFolders sortKey:self.defaultSortKey ascending:YES];
        AlfrescoLogDebug(@"returning cached favorite folders %d", sortedFavoriteFolders.count);
        AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedFavoriteFolders listingContext:listingContext];
        completionBlock(pagingResult, nil);
        return nil;
    }
    AlfrescoRequest *request = [self favoritesForType:AlfrescoFavoriteFolder listingContext:listingContext arrayCompletionBlock:nil pagingCompletionBlock:completionBlock];
    return request;
}

- (AlfrescoRequest *)retrieveFavoriteNodesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSMutableArray *favoriteNodes = [NSMutableArray array];
    
    [self retrieveFavoriteDocumentsWithCompletionBlock:^(NSArray *favoriteDocuments, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            [favoriteNodes addObjectsFromArray:favoriteDocuments];
            [self retrieveFavoriteFoldersWithCompletionBlock:^(NSArray *favoriteFolders, NSError *error) {
                if (error)
                {
                    completionBlock(nil, error);
                }
                else
                {
                    [favoriteNodes addObjectsFromArray:favoriteFolders];
                    NSArray *sortedFavoriteNodes = [AlfrescoSortingUtils sortedArrayForArray:favoriteNodes sortKey:self.defaultSortKey ascending:YES];
                    completionBlock(sortedFavoriteNodes, nil);
                }
            }];
        }
    }];
    return nil;
}

- (AlfrescoRequest *)retrieveFavoriteNodesWithListingContext:(AlfrescoListingContext *)listingContext
                                             completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    [self retrieveFavoriteNodesWithCompletionBlock:^(NSArray *array, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            AlfrescoPagingResult *paging = [AlfrescoPagingUtils pagedResultFromArray:array listingContext:listingContext];
            completionBlock(paging, nil);
        }
    }];
    return nil;
}

- (AlfrescoRequest *)isFavorite:(AlfrescoNode *)node completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (node.isDocument)
    {
        [self retrieveFavoriteDocumentsWithCompletionBlock:^(NSArray *array, NSError *error) {
            if (error)
            {
                completionBlock(NO, NO, error);
            }
            else
            {
                BOOL isNodeFavorite = [[array valueForKeyPath:@"identifier"] containsObject:node.identifier];
                completionBlock(YES, isNodeFavorite, nil);
            }
        }];
    }
    else
    {
        [self retrieveFavoriteFoldersWithCompletionBlock:^(NSArray *array, NSError *error) {
            if (error)
            {
                completionBlock(NO, NO, error);
            }
            else
            {
                BOOL isNodeFavorite = [[array valueForKeyPath:@"identifier"] containsObject:node.identifier];
                completionBlock(YES, isNodeFavorite, nil);
            }
        }];
    }
    return nil;
}

- (AlfrescoRequest *)addFavorite:(AlfrescoNode *)node completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    [self prepareRequestBodyToFavorite:YES node:node completionBlock:^(NSData *data, NSError *error) {
        
        AlfrescoFavoriteType type = node.isDocument ? AlfrescoFavoriteDocument : AlfrescoFavoriteFolder;
        [self updateFavoritesWithList:data forType:type completionBlock:^(BOOL succeeded, NSError *error) {
            
            if (succeeded)
            {
                [self.favoritesCache addFavorite:node];
            }
            completionBlock(succeeded, succeeded, error);
        }];
    }];
    return nil;
}

- (AlfrescoRequest *)removeFavorite:(AlfrescoNode *)node completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    [self prepareRequestBodyToFavorite:NO node:node completionBlock:^(NSData *data, NSError *error) {
        
        AlfrescoFavoriteType type = node.isDocument ? AlfrescoFavoriteDocument : AlfrescoFavoriteFolder;
        [self updateFavoritesWithList:data forType:type completionBlock:^(BOOL succeeded, NSError *error) {
            
            if (succeeded)
            {
                [self.favoritesCache removeFavorite:node];
            }
            completionBlock(succeeded, !succeeded, error);
        }];
    }];
    return nil;
}

#pragma mark - private methods

- (NSURL *)renditionURLForNode:(AlfrescoNode *)node renditionName:(NSString *)renditionName
{
    NSString *nodeIdentifier = [node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"];    
    nodeIdentifier = [self identifierWithoutVersionNumberForIdentifier:nodeIdentifier];
    
    NSString *requestString = [kAlfrescoOnPremiseThumbnailRenditionAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef withString:nodeIdentifier];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoRenditionId withString:renditionName];
    return [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
}

- (NSString *)identifierWithoutVersionNumberForIdentifier:(NSString *)identifier
{
    NSRange versionNumberRange = [identifier rangeOfString:@";"];
    if (versionNumberRange.location != NSNotFound)
    {
        return [identifier substringToIndex:versionNumberRange.location];
    }
    return identifier;
}

- (NSString *)cmisQueryWithNodes:(NSArray *)nodes forType:(AlfrescoFavoriteType)type
{
    NSString *pattern = [NSString stringWithFormat:@"(cmis:objectId='%@')", [nodes componentsJoinedByString:@"' OR cmis:objectId='"]];
    NSString *nodeType = (type == AlfrescoFavoriteDocument) ? @"document" : @"folder";
    
    return [NSString stringWithFormat:@"SELECT * FROM cmis:%@ WHERE %@", nodeType, pattern];
}

- (AlfrescoRequest *)favoritesForType:(AlfrescoFavoriteType)type
                       listingContext:(AlfrescoListingContext *)listingContext
                 arrayCompletionBlock:(AlfrescoArrayCompletionBlock)arrayCompletionBlock
                pagingCompletionBlock:(AlfrescoPagingResultCompletionBlock)pagingCompletionBlock
{
    NSString *requestString = nil;
    NSURL *url = nil;
    if (type == AlfrescoFavoriteDocument)
    {
        requestString = [kAlfrescoOnPremiseFavoriteDocumentsAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
        url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    }
    else if (type == AlfrescoFavoriteFolder)
    {
        requestString = [kAlfrescoOnPremiseFavoriteFoldersAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
        url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    }
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                                 method:kAlfrescoHTTPGet
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error) {
                                            if (nil != error)
                                            {
                                                [self errorForCompletionBlocks:error arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
                                            }
                                            else
                                            {
                                                NSError *conversionError = nil;
                                                NSArray *favorites = [self favoritesArrayFromJSONData:data forType:type error:&conversionError];
                                                
                                                if (favorites != nil)
                                                {
                                                    if (favorites.count > 0)
                                                    {
                                                        NSString *searchStatement = [self cmisQueryWithNodes:favorites forType:type];
                                                        AlfrescoSearchService *searchService = [[AlfrescoSearchService alloc] initWithSession:self.session];
                                                        [searchService searchWithStatement:searchStatement language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *resultsArray, NSError *error) {
                                                            if (error)
                                                            {
                                                                [self errorForCompletionBlocks:error arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
                                                            }
                                                            else
                                                            {
                                                                [self.favoritesCache addFavorites:resultsArray type:AlfrescoFavoriteNode hasMoreFavorites:NO totalFavorites:0];
                                                                if (arrayCompletionBlock)
                                                                {
                                                                    arrayCompletionBlock(resultsArray, nil);
                                                                }
                                                                else
                                                                {
                                                                    AlfrescoPagingResult *paging = [AlfrescoPagingUtils pagedResultFromArray:resultsArray listingContext:listingContext];
                                                                    pagingCompletionBlock(paging, nil);
                                                                }
                                                            }
                                                        }];
                                                    }
                                                    else
                                                    {
                                                        AlfrescoPagingResult *paging = [AlfrescoPagingUtils pagedResultFromArray:favorites listingContext:listingContext];
                                                        arrayCompletionBlock ? arrayCompletionBlock(favorites, nil) : pagingCompletionBlock(paging, nil);
                                                    }
                                                }
                                                else
                                                {
                                                    [self errorForCompletionBlocks:conversionError arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
                                                }
                                            }
                                        }];
    return request;
}

- (NSArray *)favoritesArrayFromJSONData:(NSData *)data forType:(AlfrescoFavoriteType)type error:(NSError **)outError
{
    if (nil == data)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        else
        {
            NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        return nil;
    }
    
    NSError *error = nil;
    id favoritesObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(error)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeFavorites];
        return nil;
    }
    if ([favoritesObject isKindOfClass:[NSDictionary class]] == NO)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    NSDictionary *favoritesDictionary = (NSDictionary *)favoritesObject;
    
    NSString *joinedFavoriteNodes = nil;
    if (type == AlfrescoFavoriteDocument)
    {
        joinedFavoriteNodes = [favoritesDictionary valueForKeyPath:kAlfrescoOnPremiseFavoriteDocuments];
    }
    else
    {
        joinedFavoriteNodes = [favoritesDictionary valueForKeyPath:kAlfrescoOnPremiseFavoriteFolders];
    }
    
    NSArray *favorites = (joinedFavoriteNodes.length > 0) ? [joinedFavoriteNodes componentsSeparatedByString:@","] : [NSArray array];
    return favorites;
}

- (void)updateFavoritesWithList:(NSData *)data forType:(AlfrescoFavoriteType)type completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    NSString *requestString = nil;
    NSURL *url = nil;
    if (type == AlfrescoFavoriteDocument)
    {
        requestString = [kAlfrescoOnPremiseFavoriteDocumentsAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
        url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    }
    else
    {
        requestString = [kAlfrescoOnPremiseFavoriteFoldersAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
        url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    }
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];    
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:data
                                                 method:kAlfrescoHTTPPOST
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error) {
                                            if (error)
                                            {
                                                completionBlock(NO, error);
                                            }
                                            else
                                            {
                                                completionBlock(YES, error);
                                            }
                                        }];
}

- (void)prepareRequestBodyToFavorite:(BOOL)favorite node:(AlfrescoNode *)node completionBlock:(AlfrescoDataCompletionBlock)completionBlock
{
    void (^updateFavoritesList)(NSMutableArray *, BOOL) = ^(NSMutableArray *favorites, BOOL addToFavorites)
    {
        if (addToFavorites)
        {
            if (![[favorites valueForKeyPath:@"identifier"] containsObject:node.identifier])
            {
                [favorites addObject:node];
            }
        }
        else
        {
            NSInteger nodeIndex = [[favorites valueForKeyPath:@"identifier"] indexOfObject:node.identifier];
            [favorites removeObjectAtIndex:nodeIndex];
        }
    };
    
    NSData * (^generateJsonBody)(NSMutableArray *) = ^ NSData * (NSMutableArray *favorites)
    {
        NSArray *favoriteIdentifiers = [favorites valueForKeyPath:@"identifier"];
        NSMutableArray *favoriteIdentifiersWithoutVersionNumber = [NSMutableArray array];
        for (NSString *favoriteIdentifier in favoriteIdentifiers)
        {
            [favoriteIdentifiersWithoutVersionNumber addObject:[self identifierWithoutVersionNumberForIdentifier:favoriteIdentifier]];
        }
        NSString *joinedFavoriteIdentifiers = [favoriteIdentifiersWithoutVersionNumber componentsJoinedByString:@","];
        
        NSString *favoritesAPIKey = node.isDocument ? kAlfrescoOnPremiseFavoriteDocuments : kAlfrescoOnPremiseFavoriteFolders;
        NSArray *favoriteKeyComponents = [favoritesAPIKey componentsSeparatedByString:@"."];
        
        NSDictionary *favoriteKeyComponentDictionaries = nil;
        
        int lastKeyComponentIndex = favoriteKeyComponents.count - 1;
        for (int i = lastKeyComponentIndex; i >= 0; i--)
        {
            NSString *keyComponent = [favoriteKeyComponents objectAtIndex:i];
            if ([keyComponent isEqualToString:kAlfrescoJSONFavorites])
            {
                favoriteKeyComponentDictionaries = [NSDictionary dictionaryWithObject:joinedFavoriteIdentifiers forKey:keyComponent];
            }
            else
            {
                favoriteKeyComponentDictionaries = [NSDictionary dictionaryWithObject:favoriteKeyComponentDictionaries forKey:keyComponent];
            }
        }
        
        return [NSJSONSerialization dataWithJSONObject:favoriteKeyComponentDictionaries options:NSJSONWritingPrettyPrinted error:nil];
    };
    
    if (node.isDocument)
    {
        [self retrieveFavoriteDocumentsWithCompletionBlock:^(NSArray *array, NSError *error) {
            if (error)
            {
                completionBlock(nil, error);
            }
            else
            {
                NSMutableArray *updatedFavoritesList = array ? [array mutableCopy] : [NSMutableArray array];
                updateFavoritesList(updatedFavoritesList, favorite);
                NSData *jsonData = generateJsonBody(updatedFavoritesList);
                completionBlock(jsonData, error);
            }
        }];
    }
    else
    {
        [self retrieveFavoriteFoldersWithCompletionBlock:^(NSArray *array, NSError *error) {
            if (error)
            {
                completionBlock(nil, error);
            }
            else
            {
                NSMutableArray *updatedFavoritesList = array ? [array mutableCopy] : [NSMutableArray array];
                updateFavoritesList(updatedFavoritesList, favorite);
                NSData *jsonData = generateJsonBody(updatedFavoritesList);
                completionBlock(jsonData, error);
            }
        }];
    }
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

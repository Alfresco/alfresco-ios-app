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

#import "AlfrescoOnPremiseSiteService.h"
#import "AlfrescoPersonService.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoCMISToAlfrescoObjectConverter.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoPagingUtils.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoDocumentFolderService.h"
#import "AlfrescoSortingUtils.h"
#import "AlfrescoNetworkProvider.h"
#import "AlfrescoLog.h"
#import "AlfrescoSiteCache.h"
#import "AlfrescoOnPremiseJoinSiteRequest.h"

#define TIMEOUTINTERVAL 120

@interface AlfrescoOnPremiseSiteService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoCMISToAlfrescoObjectConverter *objectConverter;
@property (nonatomic, weak, readwrite) id<AlfrescoAuthenticationProvider> authenticationProvider;
@property (nonatomic, strong, readwrite) NSArray *supportedSortKeys;
@property (nonatomic, strong, readwrite) NSString *defaultSortKey;
@property (nonatomic, strong, readwrite) AlfrescoSiteCache *siteCache;
@property (nonatomic, strong, readwrite) NSMutableArray *joinRequests;
@end

@implementation AlfrescoOnPremiseSiteService

- (id)initWithSession:(id<AlfrescoSession>)session
{
    if (self = [super init])
    {
        self.session = session;
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoOnPremiseAPIPath];
        self.objectConverter = [[AlfrescoCMISToAlfrescoObjectConverter alloc] initWithSession:self.session];
        id authenticationObject = [session objectForParameter:kAlfrescoAuthenticationProviderObjectKey];
        self.authenticationProvider = nil;
        if ([authenticationObject isKindOfClass:[AlfrescoBasicAuthenticationProvider class]])
        {
            self.authenticationProvider = (AlfrescoBasicAuthenticationProvider *)authenticationObject;
        }
        self.defaultSortKey = kAlfrescoSortByTitle;
        self.supportedSortKeys = [NSArray arrayWithObjects:kAlfrescoSortByTitle, kAlfrescoSortByShortname, nil];
        self.joinRequests = [NSMutableArray array];

        NSString *siteCacheKey = [NSString stringWithFormat:@"%@%@", kAlfrescoSessionInternalCache, NSStringFromClass([AlfrescoSiteCache class])];
        id cachedObj = [self.session objectForParameter:siteCacheKey];
        if (cachedObj)
        {
            AlfrescoLogDebug(@"Found an existing SiteCache for key: %@", siteCacheKey);
            self.siteCache = (AlfrescoSiteCache *)cachedObj;
        }
        else
        {
            AlfrescoLogDebug(@"Creating SiteCache for key: %@", siteCacheKey);
            self.siteCache = [[AlfrescoSiteCache alloc] init];
            [self.session setObject:self.siteCache forParameter:siteCacheKey];
        }
    }
    return self;
}

- (void)clear
{
    [self.siteCache clear];
}


- (AlfrescoRequest *)retrieveAllSitesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    AlfrescoRequest *request = [self retrieveSitesForType:AlfrescoSiteAll listingContext:nil arrayCompletionBlock:completionBlock pagingCompletionBlock:nil];
    return request;
}

- (AlfrescoRequest *)retrieveAllSitesWithListingContext:(AlfrescoListingContext *)listingContext
                                        completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    AlfrescoRequest *request = [self retrieveSitesForType:AlfrescoSiteAll listingContext:listingContext arrayCompletionBlock:nil pagingCompletionBlock:completionBlock];
    return request;
}

- (AlfrescoRequest *)retrieveSitesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSArray *memberSites = [self.siteCache memberSites];
    if (0 < memberSites.count)
    {
        NSArray *sortedSiteArray = [AlfrescoSortingUtils sortedArrayForArray:memberSites sortKey:self.defaultSortKey ascending:YES];
        if ([AlfrescoLog sharedInstance].logLevel == AlfrescoLogLevelDebug)
        {
            AlfrescoLogDebug(@"returning cached member sites %d", sortedSiteArray.count);
        }
        completionBlock(sortedSiteArray, nil);
        return nil;
    }
    AlfrescoRequest *request = [self retrieveSitesForType:AlfrescoSiteMember listingContext:nil arrayCompletionBlock:completionBlock pagingCompletionBlock:nil];
    return request;
}

- (AlfrescoRequest *)retrieveSitesWithListingContext:(AlfrescoListingContext *)listingContext
                                     completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    NSArray *memberSites = [self.siteCache memberSites];
    if (0 < memberSites.count)
    {
        NSArray *sortedSiteArray = [AlfrescoSortingUtils sortedArrayForArray:memberSites sortKey:self.defaultSortKey ascending:YES];
        if ([AlfrescoLog sharedInstance].logLevel == AlfrescoLogLevelDebug)
        {
            AlfrescoLogDebug(@"returning cached member sites %d", sortedSiteArray.count);
        }
        AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedSiteArray listingContext:listingContext];
        completionBlock(pagingResult, nil);
        return nil;
    }
    
    AlfrescoRequest *request = [self retrieveSitesForType:AlfrescoSiteMember listingContext:listingContext arrayCompletionBlock:nil pagingCompletionBlock:completionBlock];
    return request;
}


- (AlfrescoRequest *)retrieveFavoriteSitesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    NSArray *favourites = [self.siteCache favoriteSites];
    if (0 < favourites.count)
    {
        NSArray *sortedSites = [AlfrescoSortingUtils sortedArrayForArray:favourites sortKey:self.defaultSortKey ascending:YES];
        if ([AlfrescoLog sharedInstance].logLevel == AlfrescoLogLevelDebug)
        {
            AlfrescoLogDebug(@"returning cached favorite sites %d", sortedSites.count);
        }
        completionBlock(sortedSites, nil);
        return nil;
    }
    AlfrescoRequest *request = [self retrieveSitesForType:AlfrescoSiteFavorite listingContext:nil arrayCompletionBlock:completionBlock pagingCompletionBlock:nil];
    return request;
}

- (AlfrescoRequest *)retrieveFavoriteSitesWithListingContext:(AlfrescoListingContext *)listingContext
                                             completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    NSArray *favourites = [self.siteCache favoriteSites];
    if (0 < favourites.count)
    {
        NSArray *sortedSites = [AlfrescoSortingUtils sortedArrayForArray:favourites sortKey:self.defaultSortKey ascending:YES];
        if ([AlfrescoLog sharedInstance].logLevel == AlfrescoLogLevelDebug)
        {
            AlfrescoLogDebug(@"returning cached favorite sites %d", sortedSites.count);
        }
        AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedSites listingContext:listingContext];
        completionBlock(pagingResult, nil);
        return nil;
    }
    AlfrescoRequest *request = [self retrieveSitesForType:AlfrescoSiteFavorite listingContext:listingContext arrayCompletionBlock:nil pagingCompletionBlock:completionBlock];
    return request;
}

- (AlfrescoRequest *)retrieveSiteWithShortName:(NSString *)siteShortName
                               completionBlock:(AlfrescoSiteCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:siteShortName argumentName:@"siteShortName"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoOnPremiseSitesShortnameAPI stringByReplacingOccurrencesOfString:kAlfrescoSiteId withString:siteShortName];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            AlfrescoSite *site = [self alfrescoSiteFromJSONData:data error:&conversionError];
            completionBlock(site, conversionError);
        }
    }];
    return request;
}


- (AlfrescoRequest *)retrieveDocumentLibraryFolderForSite:(NSString *)siteShortName
                                          completionBlock:(AlfrescoFolderCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:siteShortName argumentName:@"siteShortName"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    __block AlfrescoDocumentFolderService *docService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    NSString *requestString = [kAlfrescoOnPremiseSiteDoclibAPI stringByReplacingOccurrencesOfString:kAlfrescoSiteId withString:siteShortName];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:[self.session.baseUrl absoluteString] extensionURL:requestString];
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSString *folderId = nil;
            NSError *conversionError = nil;
            id jsonContainer = [NSJSONSerialization JSONObjectWithData:data options:0 error:&conversionError];
            if (nil != jsonContainer)
            {
                NSArray *containerArray = [jsonContainer valueForKey:kAlfrescoJSONContainers];
                if ( nil != containerArray && containerArray.count > 0)
                {
                    folderId = [[containerArray objectAtIndex:0] valueForKey:kAlfrescoJSONNodeRef];
                }
                if (nil != folderId)
                {
                    request = [docService retrieveNodeWithIdentifier:folderId completionBlock:^(AlfrescoNode *node, NSError *nodeError){
                        completionBlock((AlfrescoFolder *)node, nodeError);
                        docService = nil;
                    }];
                }
                else
                {
                    completionBlock(nil, [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData]);
                }
            }
            else
            {
                completionBlock(nil, conversionError);
            }
            
        }
    }];
    return request;
}


- (AlfrescoRequest *)addFavoriteSite:(AlfrescoSite *)site
                     completionBlock:(AlfrescoSiteCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    NSString *requestString = [kAlfrescoOnPremiseAddOrRemoveFavoriteSiteAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId
                                                                                                      withString:self.session.personIdentifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    NSData *jsonData = [self jsonDataForFavoriteSites:site.shortName addFavorite:YES];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:jsonData
                                                 method:kAlfrescoHTTPPOST
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            [self.siteCache addSite:site type:AlfrescoSiteFavorite];
            completionBlock(site, error);
        }
    }];
    
    return request;
}

- (AlfrescoRequest *)removeFavoriteSite:(AlfrescoSite *)site
                        completionBlock:(AlfrescoSiteCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoOnPremiseAddOrRemoveFavoriteSiteAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId
                                                                                                      withString:self.session.personIdentifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    NSData *jsonData = [self jsonDataForFavoriteSites:site.shortName addFavorite:NO];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:jsonData
                                                 method:kAlfrescoHTTPPOST
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            [self.siteCache removeSite:site type:AlfrescoSiteFavorite];
            completionBlock(site, error);
        }
    }];
    
    return request;
}

- (AlfrescoRequest *)joinSite:(AlfrescoSite *)site
              completionBlock:(AlfrescoSiteCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (site.visibility == AlfrescoSiteVisibilityPublic)
    {
        return [self joinPublicSite:site completionBlock:completionBlock];
    }
    else if (site.visibility == AlfrescoSiteVisibilityModerated)
    {
        return [self joinModeratedSite:site completionBlock:completionBlock];
    }
    else
    {
        NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeSites];
        completionBlock(nil, error);
        return nil;
    }
    
}

- (AlfrescoRequest *)joinPublicSite:(AlfrescoSite *)site completionBlock:(AlfrescoSiteCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    NSString *requestString = [kAlfrescoOnPremiseJoinPublicSiteAPI stringByReplacingOccurrencesOfString:kAlfrescoSiteId
                                                                                             withString:site.identifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    NSData *jsonData = [self jsonDataForJoiningPublicSite:self.session.personIdentifier];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session requestBody:jsonData method:kAlfrescoHTTPPOST alfrescoRequest:request completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            [self.siteCache addSite:site type:AlfrescoSiteMember];
            completionBlock(site, nil);
        }
    }];
    
    return request;
    
    
}

- (AlfrescoRequest *)joinModeratedSite:(AlfrescoSite *)site
                       completionBlock:(AlfrescoSiteCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    NSString *requestString = [kAlfrescoOnPremiseJoinModeratedSiteAPI stringByReplacingOccurrencesOfString:kAlfrescoSiteId
                                                                                                withString:site.identifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    NSData *jsonData = [self jsonDataForJoiningModeratedSite:self.session.personIdentifier comment:nil];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session requestBody:jsonData method:kAlfrescoHTTPPOST alfrescoRequest:request completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *jsonError = nil;
            AlfrescoOnPremiseJoinSiteRequest *joinRequest = [self singleJoinRequestFromJSONData:data error:&jsonError];
            if (joinRequest)
            {
                [self.joinRequests addObject:joinRequest];
                [self.siteCache addSite:site type:AlfrescoSitePendingMember];
                completionBlock(site, nil);
            }
            else
            {
                completionBlock(nil, jsonError);
            }
        }
    }];
    
    return request;
    
}


- (AlfrescoRequest *)retrievePendingSitesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    NSArray *pendingSiteRequests = [self.siteCache pendingMemberSites];
    if (0 < pendingSiteRequests.count)
    {
        completionBlock(pendingSiteRequests, nil);
        return nil;
    }
    AlfrescoRequest *request = [self retrieveSitesForType:AlfrescoSitePendingMember listingContext:nil arrayCompletionBlock:completionBlock pagingCompletionBlock:nil];
    return request;
}

- (AlfrescoRequest *)retrievePendingSitesWithListingContext:(AlfrescoListingContext *)listingContext
                                            completionblock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    NSArray *pendingSiteRequests = [self.siteCache pendingMemberSites];
    if (0 < pendingSiteRequests.count)
    {
        AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:pendingSiteRequests listingContext:listingContext];
        completionBlock(pagingResult, nil);
        return nil;
    }
    AlfrescoRequest *request = [self retrieveSitesForType:AlfrescoSitePendingMember listingContext:listingContext arrayCompletionBlock:nil pagingCompletionBlock:completionBlock];
    return request;
}


- (AlfrescoRequest *)cancelPendingJoinRequestForSite:(AlfrescoSite *)site
                                     completionBlock:(AlfrescoSiteCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSPredicate *joinPredicate = [NSPredicate predicateWithFormat:@"shortName == %@", site.identifier];
    NSArray *foundRequests = [self.joinRequests filteredArrayUsingPredicate:joinPredicate];
    if (0 == foundRequests.count)
    {
        NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeSitesNoSites];
        completionBlock(nil, error);
        return nil;
    }
    __block AlfrescoOnPremiseJoinSiteRequest *foundRequest = [foundRequests objectAtIndex:0];
    NSString *requestString = [kAlfrescoOnPremiseCancelJoinRequestsAPI stringByReplacingOccurrencesOfString:kAlfrescoSiteId
                                                                                                  withString:site.identifier];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoInviteId withString:foundRequest.identifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                                 method:kAlfrescoHTTPDelete
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error){
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            [self.siteCache removeSite:site type:AlfrescoSitePendingMember];
            [self.joinRequests removeObject:foundRequest];
            completionBlock(site, nil);
        }
    }];
        
    return request;
}


- (AlfrescoRequest *)leaveSite:(AlfrescoSite *)site
               completionBlock:(AlfrescoSiteCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
        
    NSString *requestString = [kAlfrescoOnPremiseLeaveSiteAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId
                                                                                        withString:self.session.personIdentifier];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoSiteId withString:site.identifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session method:kAlfrescoHTTPDelete alfrescoRequest:request completionBlock:^(NSData *data, NSError *error){
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            [self.siteCache removeSite:site type:AlfrescoSiteMember];
            completionBlock(site, nil);
        }
    }];
    return request;
}



#pragma mark Site service internal methods
/**
 this method is the entry point for parsing sites for all different states.
 The calls are daisy-chained:
 *allsites -> favorite sites -> member sites -> pending sites
 */
- (AlfrescoRequest *)retrieveSitesForType:(AlfrescoSiteFlags)type
                           listingContext:(AlfrescoListingContext *)listingContext
                     arrayCompletionBlock:(AlfrescoArrayCompletionBlock)arrayCompletionBlock
                    pagingCompletionBlock:(AlfrescoPagingResultCompletionBlock)pagingCompletionBlock
{
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    
    NSURL *allSitesAPI = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoOnPremiseSiteAPI];
    [self.session.networkProvider executeRequestWithURL:allSitesAPI session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            [self errorForCompletionBlocks:error arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *siteArray = [self siteArrayFromJSONData:data error:&conversionError];
            if (siteArray)
            {
                NSArray *allSortedArray = [AlfrescoSortingUtils sortedArrayForArray:siteArray sortKey:self.defaultSortKey ascending:YES];
                [self.siteCache addSites:allSortedArray type:AlfrescoSiteAll];
                [self retrieveFavouriteSitesForType:type arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock listingContext:listingContext alfrescoRequest:request];
            }
            else
            {
                [self errorForCompletionBlocks:conversionError arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];                
            }
        }
    }];
    return request;
}


/**
 This method is called from retrieving all sites and is the 2nd in the daisy chain
 allsites -> *favorite sites -> member sites -> pending sites
 */
- (void)retrieveFavouriteSitesForType:(AlfrescoSiteFlags)type
                 arrayCompletionBlock:(AlfrescoArrayCompletionBlock)arrayCompletionBlock
                pagingCompletionBlock:(AlfrescoPagingResultCompletionBlock)pagingCompletionBlock
                       listingContext:(AlfrescoListingContext *)listingContext
                      alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
{
    NSString *favRequestString = [kAlfrescoOnPremiseFavoriteSiteForPersonAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId
                                                                                                       withString:self.session.personIdentifier];
    NSURL *favouriteSitesURL = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:favRequestString];
    [self.session.networkProvider executeRequestWithURL:favouriteSitesURL session:self.session alfrescoRequest:alfrescoRequest completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            [self errorForCompletionBlocks:error arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *favSitesArray = [self favoriteSitesArrayFromJSONData:data error:&conversionError];
            if (nil != favSitesArray)
            {
                NSPredicate *favoritePredicate = [NSPredicate predicateWithFormat:@"shortName IN %@",favSitesArray];
                NSArray *favoriteSites = [self.siteCache.allSites filteredArrayUsingPredicate:favoritePredicate];
                [self.siteCache addSites:favoriteSites type:AlfrescoSiteFavorite];
                [self retrieveMemberSitesForType:type arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock listingContext:listingContext alfrescoRequest:alfrescoRequest];
            }
            else
            {
                [self errorForCompletionBlocks:conversionError arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];                
            }
        }
    }];
}


/**
 This method is called from retrieving all sites and is the 3rd in the daisy chain
 allsites -> favorite sites -> *member sites -> pending sites
 */
- (void)retrieveMemberSitesForType:(AlfrescoSiteFlags)type
              arrayCompletionBlock:(AlfrescoArrayCompletionBlock)arrayCompletionBlock
             pagingCompletionBlock:(AlfrescoPagingResultCompletionBlock)pagingCompletionBlock
                    listingContext:(AlfrescoListingContext *)listingContext
                   alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
{
    NSString *siteString = [kAlfrescoOnPremiseSiteForPersonAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
    NSURL *mySitesAPI = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:siteString];
    [self.session.networkProvider executeRequestWithURL:mySitesAPI session:self.session alfrescoRequest:alfrescoRequest completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            [self errorForCompletionBlocks:error arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *mySiteArray = [self siteArrayFromJSONData:data error:&conversionError];
            if (mySiteArray)
            {
                NSArray *mySortedSiteArray = [AlfrescoSortingUtils sortedArrayForArray:mySiteArray sortKey:self.defaultSortKey ascending:YES];
                [self.siteCache addSites:mySortedSiteArray type:AlfrescoSiteMember];
                [self retrievePendingMemberSitesForType:type arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock listingContext:listingContext alfrescoRequest:alfrescoRequest];
            }
            else
            {
                [self errorForCompletionBlocks:conversionError arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
            }
        }
    }];
}

/**
 This method is called from retrieving all sites and is the last in the daisy chain
 allsites -> favorite sites -> member sites -> *pending sites
 Now that we have run through all different states we can resolve the resulting site arrays (or paging result)
 */
- (void)retrievePendingMemberSitesForType:(AlfrescoSiteFlags)type
                     arrayCompletionBlock:(AlfrescoArrayCompletionBlock)arrayCompletionBlock
                    pagingCompletionBlock:(AlfrescoPagingResultCompletionBlock)pagingCompletionBlock
                           listingContext:(AlfrescoListingContext *)listingContext
                          alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
{
    NSString *pendingString = [kAlfrescoOnPremisePendingJoinRequestsAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId
                                                                                                  withString:self.session.personIdentifier];
    NSURL *pendingSitesAPI = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:pendingString];
    [self.session.networkProvider executeRequestWithURL:pendingSitesAPI session:self.session alfrescoRequest:alfrescoRequest completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            [self errorForCompletionBlocks:error arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
        }
        else
        {
            NSError *jsonError = nil;
            NSArray *requests = [self joinRequestArrayFromJSONData:data error:&jsonError];
            if (requests)
            {
                NSArray *resultsArray = nil;
                NSArray *pendingSites = [self sitesArrayFromJoinRequests:requests];
                [self.siteCache addSites:pendingSites type:AlfrescoSitePendingMember];
                switch (type)
                {
                    case AlfrescoSiteAll:
                        resultsArray = [self.siteCache allSites];
                        break;
                    case AlfrescoSiteFavorite:
                        resultsArray = [self.siteCache favoriteSites];
                        break;
                    case AlfrescoSiteMember:
                        resultsArray = [self.siteCache memberSites];
                        break;
                    case AlfrescoSitePendingMember:
                        resultsArray = [self.siteCache pendingMemberSites];
                        break;
                }
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
            else
            {
                [self errorForCompletionBlocks:jsonError arrayCompletionBlock:arrayCompletionBlock pagingCompletionBlock:pagingCompletionBlock];
            }
        }
    }];
    
}

- (AlfrescoRequest *)retrieveAllMembers:(AlfrescoSite *)site completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    AlfrescoRequest *request = [self retrieveAllMembersForSite:site completionBlock:completionBlock];
    return request;
}

- (AlfrescoRequest *)retrieveAllMembers:(AlfrescoSite *)site
                     WithListingContext:(AlfrescoListingContext *)listingContext
                        completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    AlfrescoRequest *request = [self retrieveAllMembersForSite:site completionBlock:^(NSArray *array, NSError *error) {
        
        AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:array listingContext:listingContext];
        completionBlock(pagingResult, error);
    }];
    return request;
}

- (AlfrescoRequest *)retrieveAllMembersForSite:(AlfrescoSite *)site completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    NSString *requestString = [kAlfrescoOnPremiseJoinPublicSiteAPI stringByReplacingOccurrencesOfString:kAlfrescoSiteId
                                                                                             withString:site.identifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *members = [self membersArrayFromJSONData:data error:&conversionError];
            // Members with incomplete properties
            completionBlock(members, conversionError);
        }
    }];
    
    return request;
}

- (AlfrescoRequest *)searchMembers:(AlfrescoSite *)site
                            filter:(NSString *)filter
                WithListingContext:(AlfrescoListingContext *)listingContext
                   completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:filter argumentName:@"filter"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString =  [kAlfrescoOnPremiseJoinPublicSiteAPI stringByAppendingString:kAlfrescoOnPremiseSiteMembershipFilter];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoSiteId withString:site.identifier];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoSearchFilter withString:filter];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        if (nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *members = [self membersArrayFromJSONData:data error:&conversionError];
            // Members with incomplete properties
            AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:members listingContext:listingContext];
            completionBlock(pagingResult, error);
        }
    }];
    return request;
}

- (AlfrescoRequest *)isPerson:(AlfrescoPerson *)person memberOfSite:(AlfrescoSite *)site completionBlock:(AlfrescoMemberCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:person argumentName:@"person"];
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoOnPremiseLeaveSiteAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:person.identifier];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoSiteId withString:site.identifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session method:kAlfrescoHTTPGet alfrescoRequest:request completionBlock:^(NSData *data, NSError *error) {
        
        // if person is not member : the request returns error and data is nil so its difficult to differenciate if request failed or person is not member
        if (error)
        {
            completionBlock(YES, NO, nil);
        }
        else
        {
            completionBlock(YES, YES, nil);
        }
    }];
    return request;
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


- (AlfrescoOnPremiseJoinSiteRequest *)singleJoinRequestFromJSONData:(NSData *)data error:(NSError **)outError
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
    id jsonRequestObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(error)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeSites];
        return nil;
    }
    if ([jsonRequestObj isKindOfClass:[NSDictionary class]] == NO)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeSitesNoSites];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeSitesNoSites];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeSitesNoSites];
        }
        return nil;
    }
    NSDictionary *jsonDict = (NSDictionary *)jsonRequestObj;
    if (![[jsonDict allKeys] containsObject:kAlfrescoJSONData])
    {
        NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        return nil;
    }
    
    id dataObj = [jsonDict objectForKey:kAlfrescoJSONData];
    if (![dataObj isKindOfClass:[NSDictionary class]])
    {
        NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        return nil;
    }
    else
    {
        return [[AlfrescoOnPremiseJoinSiteRequest alloc] initWithProperties:(NSDictionary *)dataObj];
    }
}

- (NSArray *)joinRequestArrayFromJSONData:(NSData *)data error:(NSError **)outError
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
    id jsonRequestObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(error)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeSites];
        return nil;
    }
    if ([jsonRequestObj isKindOfClass:[NSDictionary class]] == NO)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeSitesNoSites];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeSitesNoSites];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeSitesNoSites];
        }
        return nil;
    }
    NSDictionary *jsonDict = (NSDictionary *)jsonRequestObj;
    if (![[jsonDict allKeys] containsObject:kAlfrescoJSONData])
    {
        NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        return nil;
    }
    
    id dataObj = [jsonDict objectForKey:kAlfrescoJSONData];
    if (![dataObj isKindOfClass:[NSArray class]])
    {
        NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        return nil;
    }
    NSMutableArray *allRequests = [NSMutableArray array];
    for (id requestObj in (NSArray *)dataObj)
    {
        [allRequests addObject:[[AlfrescoOnPremiseJoinSiteRequest alloc] initWithProperties:requestObj]];
    }
    return allRequests;    
}


- (NSArray *) siteArrayFromJSONData:(NSData *)data error:(NSError **)outError
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
    id jsonSiteArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(error)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeSites];
        return nil;
    }
    if ([jsonSiteArray isKindOfClass:[NSArray class]] == NO)
    {
        if([jsonSiteArray isKindOfClass:[NSDictionary class]] == YES && [[jsonSiteArray valueForKeyPath:@"status.code"] isEqualToNumber:[NSNumber numberWithInt:404]])
        {
            // no results found
            return [NSArray array];
        }
        else
        {
            if (nil == *outError)
            {
                *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeSitesNoSites];
            }
            else
            {
                NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeSitesNoSites];
                *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeSitesNoSites];
            }
            return nil;
        }
    }
    
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[jsonSiteArray count]];
    for (NSDictionary *siteDict in jsonSiteArray)
    {
        [resultArray addObject:[[AlfrescoSite alloc] initWithProperties:siteDict]];
    }
    return resultArray;
}

- (AlfrescoSite *) alfrescoSiteFromJSONData:(NSData *)data error:(NSError **)outError
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
    id jsonSite = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(error)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeSites];
        return nil;
    }
    if ([jsonSite isKindOfClass:[NSDictionary class]] == NO)
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
    if([[jsonSite valueForKeyPath:kAlfrescoJSONStatusCode] isEqualToNumber:[NSNumber numberWithInt:404]])
    {
        //empty/non existent site - should this happen? error message?
        return nil;
    }
    return [[AlfrescoSite alloc] initWithProperties:jsonSite];
}

- (NSArray *)membersArrayFromJSONData:(NSData *)data error:(NSError *__autoreleasing *)outError
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
    id jsonArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if(nil == jsonArray)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodePerson];
        return nil;
    }
    
    if (NO == [jsonArray isKindOfClass:[NSArray class]])
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
    
    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (NSDictionary *member in jsonArray)
    {
        NSMutableDictionary *memberProperties = [member valueForKey:kAlfrescoJSONAuthority];
        AlfrescoCompany *company = [[AlfrescoCompany alloc] initWithProperties:memberProperties];
        [memberProperties setValue:company forKey:kAlfrescoJSONCompany];
        AlfrescoPerson *person = [[AlfrescoPerson alloc] initWithProperties:memberProperties];
        [members addObject:person];
    }
    
    return members;
}

- (NSArray *) favoriteSitesArrayFromJSONData:(NSData *)data error:(NSError **)outError
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
    id favoriteSitesObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(error)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeSites];
        return nil;
    }
    if ([favoriteSitesObject isKindOfClass:[NSDictionary class]] == NO)
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
    NSDictionary *favouriteSitesDictionary = (NSDictionary *)favoriteSitesObject;
    NSMutableArray *resultArray = [NSMutableArray array];

    id favouriteSitesObj = [favouriteSitesDictionary valueForKeyPath:kAlfrescoOnPremiseFavoriteSites];
    if ([favouriteSitesObj isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *favDict = (NSDictionary *)favouriteSitesObj;
        for (NSString * favouriteSite in favDict)
        {
            id valueObj = [favDict valueForKey:favouriteSite];
            if ([valueObj isKindOfClass:[NSNumber class]])
            {
                BOOL isFavourite = [valueObj boolValue];
                if (isFavourite)
                {
                    [resultArray addObject:favouriteSite];
                }
            }
            else
            {
                [resultArray addObject:favouriteSite];
            }
        }
    }
    else if([favouriteSitesObj isKindOfClass:[NSArray class]])
    {
        NSArray *sitesArray = (NSArray *)favouriteSitesObj;
        for (NSString * favouriteSite in sitesArray)
        {
            [resultArray addObject:favouriteSite];
        }
    }
    return resultArray;
}

- (NSData *)jsonDataForJoiningPublicSite:(NSString *)personId
{
    NSDictionary *personDict = [NSDictionary dictionaryWithObject:personId forKey:kAlfrescoJSONUserName];
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjects:@[kAlfrescoSiteConsumer,personDict] forKeys:@[kAlfrescoJSONRole, kAlfrescoJSONPerson]];
    NSError *error = nil;
    return [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
}

- (NSData *)jsonDataForJoiningModeratedSite:(NSString *)personId comment:(NSString *)comment
{
    if (nil == comment)
    {
        comment = @"";
    }
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjects:@[kAlfrescoModerated, personId, comment, kAlfrescoSiteConsumer ]
                                                         forKeys:@[kAlfrescoJSONInvitationType, kAlfrescoJSONInviteeUsername, kAlfrescoJSONInviteeComments, kAlfrescoJSONInviteeRolename]];
    NSError *error = nil;
    return [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
}

- (NSData *)jsonDataForFavoriteSites:(NSString *)siteId addFavorite:(BOOL)addFavorite
{
    NSDictionary *favorite = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:addFavorite]
                                                                                            forKey:siteId] forKey:kAlfrescoJSONFavorites];
    NSDictionary *sites = [NSDictionary dictionaryWithObject:favorite forKey:kAlfrescoJSONSites];
    NSDictionary *share = [NSDictionary dictionaryWithObject:sites forKey:kAlfrescoJSONShare];
    NSDictionary *alfresco = [NSDictionary dictionaryWithObject:share forKey:kAlfrescoJSONAlfresco];
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObject:alfresco forKey:kAlfrescoJSONOrg];
    NSError *error = nil;
    return [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
}

- (NSArray *)sitesArrayFromJoinRequests:(NSArray *)joinRequests
{
    if (nil == joinRequests)
    {
        return nil;
    }
    if (0 == joinRequests.count)
    {
        return joinRequests;
    }
    __block NSMutableArray *sites = [NSMutableArray arrayWithCapacity:joinRequests.count];
    NSMutableArray *requestsNotFound = [NSMutableArray array];
    for (AlfrescoOnPremiseJoinSiteRequest *request in joinRequests)
    {
        AlfrescoSite *siteCandidate = [self.siteCache objectWithIdentifier:request.shortName];
        if (siteCandidate)
        {
            [sites addObject:siteCandidate];
        }
        else
        {
            [requestsNotFound addObject:request];
        }
    }
    
    if (0 == requestsNotFound.count)
    {
        return sites;
    }
    else
    {
        __block BOOL callbackDone = NO;
        AlfrescoOnPremiseJoinSiteRequest *lastRequest = [requestsNotFound lastObject];
        for (AlfrescoOnPremiseJoinSiteRequest *notFoundRequest in requestsNotFound)
        {
            [self retrieveSiteWithShortName:notFoundRequest.shortName completionBlock:^(AlfrescoSite *foundSite, NSError *error){
                if (foundSite)
                {
                    [sites addObject:foundSite];
                }
                if ([notFoundRequest isEqual:lastRequest])
                {
                    callbackDone = YES;
                }
            }];
        }
        NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:TIMEOUTINTERVAL];
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        } while (!callbackDone && [timeoutDate timeIntervalSinceNow] > 0 );
        return sites;
    }
    
}


@end

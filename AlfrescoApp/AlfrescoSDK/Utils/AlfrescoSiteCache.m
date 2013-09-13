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

#import "AlfrescoSiteCache.h"
#import "AlfrescoOnPremiseJoinSiteRequest.h"
#import "AlfrescoInternalConstants.h"

@interface AlfrescoSiteCache ()
@property (nonatomic, strong) NSMutableArray *sitesCache;
@property (nonatomic, assign, readwrite) BOOL hasMoreSites;
@property (nonatomic, assign, readwrite) BOOL hasMoreMemberSites;
@property (nonatomic, assign, readwrite) BOOL hasMoreFavoriteSites;
@property (nonatomic, assign, readwrite) BOOL hasMorePendingSites;
@property (nonatomic, assign, readwrite) NSInteger totalSites;
@property (nonatomic, assign, readwrite) NSInteger totalMemberSites;
@property (nonatomic, assign, readwrite) NSInteger totalFavoriteSites;
@property (nonatomic, assign, readwrite) NSInteger totalPendingSites;
@end

@implementation AlfrescoSiteCache

- (id)init
{
    self = [super init];
    if (nil != self)
    {
        _sitesCache = [NSMutableArray arrayWithCapacity:0];
        _hasMoreFavoriteSites = YES;
        _hasMoreMemberSites = YES;
        _hasMorePendingSites = YES;
        _hasMoreSites = YES;
    }
    return self;
}

- (NSArray *)allSites
{
    return self.sitesCache;
}

- (NSArray *)memberSites
{
    NSPredicate *memberPredicate = [NSPredicate predicateWithFormat:@"isMember == YES"];
    return [self.sitesCache filteredArrayUsingPredicate:memberPredicate];
}

- (NSArray *)favoriteSites
{
    NSPredicate *favoritePredicate = [NSPredicate predicateWithFormat:@"isFavorite == YES"];
    return [self.sitesCache filteredArrayUsingPredicate:favoritePredicate];
}

- (NSArray *)pendingMemberSites
{
    NSPredicate *pendingMemberPredicate = [NSPredicate predicateWithFormat:@"isPendingMember == YES"];
    return [self.sitesCache filteredArrayUsingPredicate:pendingMemberPredicate];
}

- (void)addSite:(AlfrescoSite *)site type:(AlfrescoSiteFlags)type
{
    if (nil == site)
    {
        return;
    }
    NSUInteger foundIndex = [self.sitesCache indexOfObject:site];
    [self siteStateForSite:site type:type isOn:YES];

    if (NSNotFound == foundIndex)
    {
        [self.sitesCache addObject:site];
    }
    else
    {
        AlfrescoSite *originalSite = (AlfrescoSite *)[self.sitesCache objectAtIndex:foundIndex];
        [self transferStatesForSite:site fromSite:originalSite type:type];
        [self.sitesCache replaceObjectAtIndex:foundIndex withObject:site];
    }
}

- (void)removeSite:(AlfrescoSite *)site type:(AlfrescoSiteFlags)type
{
    if (nil == site)
    {
        return;
    }
    [self siteStateForSite:site type:type isOn:NO];
    if ([self canRemoveSite:site type:type])
    {
        [self.sitesCache removeObject:site];
    }
}


- (void)addSites:(NSArray *)sites type:(AlfrescoSiteFlags)type hasMoreSites:(BOOL)hasMoreSites totalSites:(NSInteger)totalSites
{
    if (nil == sites)
    {
        return;
    }
    switch (type)
    {
        case AlfrescoSiteAll:
            self.hasMoreSites = hasMoreSites;
            self.totalSites = totalSites;
            break;
        case AlfrescoSitePendingMember:
            self.hasMorePendingSites = hasMoreSites;
            self.totalPendingSites = totalSites;
            break;
        case AlfrescoSiteMember:
            self.hasMoreMemberSites = hasMoreSites;
            self.totalMemberSites = totalSites;
            break;
        case AlfrescoSiteFavorite:
            self.hasMoreFavoriteSites = hasMoreSites;
            self.totalFavoriteSites = totalSites;
            break;
    }
    [sites enumerateObjectsUsingBlock:^(AlfrescoSite *site, NSUInteger index, BOOL *stop){
        [self addSite:site type:type];
    }];
}

- (void)addSites:(NSArray *)sites type:(AlfrescoSiteFlags)type
{
    [self addSites:sites type:type hasMoreSites:NO totalSites:-1];
}


- (AlfrescoSite *)addPendingRequest:(AlfrescoOnPremiseJoinSiteRequest *)pendingRequest
{
    if (nil == pendingRequest)
    {
        return nil;
    }
    AlfrescoSite *site = [self objectWithIdentifier:pendingRequest.shortName];
    if (site)
    {
        [self addSite:site type:AlfrescoSitePendingMember];
    }
    else
    {
        NSMutableDictionary *siteProperties = [NSMutableDictionary dictionary];
        [siteProperties setValue:pendingRequest.shortName forKey:kAlfrescoJSONShortname];
        [siteProperties setValue:[NSNumber numberWithBool:YES] forKey:kAlfrescoSiteIsPendingMember];
        site = [[AlfrescoSite alloc] initWithProperties:siteProperties];
        [self.sitesCache addObject:site];
    }
    return site;
}

- (NSArray *)addPendingRequests:(NSArray *)pendingRequests
{
    if (nil == pendingRequests)
    {
        return nil;
    }
    [pendingRequests enumerateObjectsUsingBlock:^(AlfrescoOnPremiseJoinSiteRequest *pendingRequest, NSUInteger index, BOOL *stop){
        [self addPendingRequest:pendingRequest];
    }];
    return [self pendingMemberSites];
    
}

- (void)clear
{
    [self.sitesCache removeAllObjects];
}

/**
 the method returns the first entry found for the identifier. Typically, a site id is unique - but this may not always be the case(?)
 */
- (AlfrescoSite *)objectWithIdentifier:(NSString *)identifier
{
    if (!identifier)return nil;
    NSPredicate *idPredicate = [NSPredicate predicateWithFormat:@"identifier == %@",identifier];
    NSArray *results = [self.sitesCache filteredArrayUsingPredicate:idPredicate];
    return (0 == results.count) ? nil : results[0];
}

#pragma private methods
- (BOOL)canRemoveSite:(AlfrescoSite *)site type:(AlfrescoSiteFlags)type
{
    if (![self.sitesCache containsObject:site])
    {
        return NO;
    }
    BOOL canRemoveFromCache = NO;
    if ([self.sitesCache containsObject:site])
    {
        switch (type)
        {
            case AlfrescoSiteAll:
                canRemoveFromCache = YES;
                break;
            case AlfrescoSiteFavorite:
                if (!site.isMember && !site.isPendingMember)
                {
                    canRemoveFromCache = YES;
                }
                break;
            case AlfrescoSiteMember:
                if (!site.isFavorite)
                {
                    canRemoveFromCache = YES;
                }
                break;
            case AlfrescoSitePendingMember:
                if (!site.isFavorite)
                {
                    canRemoveFromCache = YES;
                }
                break;
        }
    }
    return canRemoveFromCache;
}

- (void)siteStateForSite:(AlfrescoSite *)site type:(AlfrescoSiteFlags)type isOn:(BOOL)isOn
{
    if (AlfrescoSitePendingMember == type)
    {
        [site performSelector:@selector(changePendingState:) withObject:[NSNumber numberWithBool:isOn]];
    }
    else if (AlfrescoSiteMember == type)
    {
        [site performSelector:@selector(changeMemberState:) withObject:[NSNumber numberWithBool:isOn]];
    }
    else if (AlfrescoSiteFavorite == type)
    {
        [site performSelector:@selector(changeFavoriteState:) withObject:[NSNumber numberWithBool:isOn]];
    }
}

- (void)transferStatesForSite:(AlfrescoSite *)site fromSite:(AlfrescoSite *)originalSite type:(AlfrescoSiteFlags)type
{
    if (AlfrescoSitePendingMember == type)
    {
        [site performSelector:@selector(changeMemberState:) withObject:[NSNumber numberWithBool:originalSite.isMember]];
        [site performSelector:@selector(changeFavoriteState:) withObject:[NSNumber numberWithBool:originalSite.isFavorite]];
    }
    else if (AlfrescoSiteMember == type)
    {
        [site performSelector:@selector(changeFavoriteState:) withObject:[NSNumber numberWithBool:originalSite.isFavorite]];
        [site performSelector:@selector(changePendingState:) withObject:[NSNumber numberWithBool:originalSite.isPendingMember]];
    }
    else if (AlfrescoSiteFavorite == type)
    {
        [site performSelector:@selector(changeMemberState:) withObject:[NSNumber numberWithBool:originalSite.isMember]];
        [site performSelector:@selector(changePendingState:) withObject:[NSNumber numberWithBool:originalSite.isPendingMember]];
    }
    
}


@end

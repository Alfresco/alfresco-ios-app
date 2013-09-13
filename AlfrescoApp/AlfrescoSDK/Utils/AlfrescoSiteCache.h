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

#import <Foundation/Foundation.h>
#import "AlfrescoSite.h"
#import "AlfrescoSession.h"

typedef enum
{
    AlfrescoSiteFavorite = 0,
    AlfrescoSiteMember,
    AlfrescoSitePendingMember,
    AlfrescoSiteAll    
} AlfrescoSiteFlags;

@class AlfrescoOnPremiseJoinSiteRequest;

@interface AlfrescoSiteCache : NSObject

@property (nonatomic, assign, readonly) BOOL hasMoreSites;
@property (nonatomic, assign, readonly) BOOL hasMoreMemberSites;
@property (nonatomic, assign, readonly) BOOL hasMoreFavoriteSites;
@property (nonatomic, assign, readonly) BOOL hasMorePendingSites;
@property (nonatomic, assign, readonly) NSInteger totalSites;
@property (nonatomic, assign, readonly) NSInteger totalMemberSites;
@property (nonatomic, assign, readonly) NSInteger totalFavoriteSites;
@property (nonatomic, assign, readonly) NSInteger totalPendingSites;

/**
 clears all entries in the cache
 */
- (void)clear;

/**
 returns my sites
 */
- (NSArray *)memberSites;

/**
 returns favourite sites
 */
- (NSArray *)favoriteSites;

/**
 returns sites for which a join request is pending (this would only be MODERATED sites)
 */
- (NSArray *)pendingMemberSites;

/**
 returns the entire site cache
 */
- (NSArray *)allSites;

- (void)addSite:(AlfrescoSite *)site type:(AlfrescoSiteFlags)type;

- (void)removeSite:(AlfrescoSite *)site type:(AlfrescoSiteFlags)type;

- (void)addSites:(NSArray *)sites type:(AlfrescoSiteFlags)type hasMoreSites:(BOOL)hasMoreSites totalSites:(NSInteger)totalSites;

- (AlfrescoSite *)addPendingRequest:(AlfrescoOnPremiseJoinSiteRequest *)pendingRequest;

- (void)addSites:(NSArray *)sites type:(AlfrescoSiteFlags)type;

- (AlfrescoSite *)objectWithIdentifier:(NSString *)identifier;

- (NSArray *)addPendingRequests:(NSArray *)pendingRequests;

@end

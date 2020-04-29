/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile iOS App.
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

#import "BaseFileFolderCollectionViewController.h"
#import "CollectionViewProtocols.h"

@class AlfrescoFolder;
@class AlfrescoPermissions;
@protocol AlfrescoSession;

@interface FileFolderCollectionViewController : BaseFileFolderCollectionViewController

/**
 Providing nil to the folder parameter will result in the root folder (Company Home) being displayed.
 
 @param folder - the content of this folder will be displayed. Providing nil will result in Company Home being displayed.
 @param displayName - the name that will be visible to the user when at the root of the navigation stack.
 @param session - an active session
 */
- (instancetype)initWithFolder:(AlfrescoFolder *)folder session:(id<AlfrescoSession>)session;
- (instancetype)initWithFolder:(AlfrescoFolder *)folder folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session;

/**
 Use the permissions initialiser to avoid the visual refreshing of the navigationItem barbuttons. Failure to set these will result in the
 permissions being retrieved once the controller's view is displayed.
 
 @param folder - the content of this folder will be displayed. Providing nil will result in Company Home being displayed.
 @param permissions - the permissions of the folder
 @param displayName - the name that will be visible to the user when at the root of the navigation stack.
 @param session - an active session
 */
- (instancetype)initWithFolder:(AlfrescoFolder *)folder folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session;
- (instancetype)initWithFolder:(AlfrescoFolder *)folder folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session;

/**
 Use the site short name initialiser to display the document library for the given site. Failure to provide a site short name will result in a company home controller.
 
 @param siteShortName - the site short name to which the document library folder should be shown. Providing nil will result in Company Home being displayed.
 @param permissions - the permissions of the site
 @param displayName - the name that will be visible to the user when at the root of the navigation stack.
 @param listingContext - the listing context with a paging definition that's used to retrieve the content of the site.
 @param session - an active session
 */
- (instancetype)initWithSiteShortname:(NSString *)siteShortName sitePermissions:(AlfrescoPermissions *)permissions siteDisplayName:(NSString *)displayName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session;

/**
 Use the folder path initialiser to display the contents of a folder node at a given path. Failure to provide a folder path will result in a company home controller.
 
 @param folderPath - the folder path for which the contents should be shown. Providing nil will result in Company Home being displayed.
 @param permissions - the folder's permissions
 @param displayName - the name that will be visible to the user when at the root of the navigation stack.
 @param listingContext - the listing context with a paging definition that's used to retrieve the children.
 @param session - an active session
 */
- (instancetype)initWithFolderPath:(NSString *)folderPath folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session;

/**
 Use the folder node ref initialiser to display the contents of a the folder associated to the nodeRef. Failure to provide a folder path will result in a company home controller.
 
 @param nodeRef - the folder's node ref for which the contents should be shown. Providing nil will result in Company Home being displayed.
 @param permissions - the folder's permissions
 @param folderDisplayName - the name that will be visible to the user when at the root of the navigation stack.
 @param listingContext - the listing context with a paging definition that's used to retrieve the children.
 @param session - an active session
 */
- (instancetype)initWithNodeRef:(NSString *)nodeRef folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session;

/**
 Use the document path initialiser to display the contents of the file. Failure to provide a document path will result in a company home controller.
 
 @param documentPath - the path of the document to be shown. Providing nil will result in a Company Home being displayed.
 @param session - an active session
 */
- (instancetype)initWithDocumentPath:(NSString *)documentPath session:(id<AlfrescoSession>)session;

/**
 Use the document node ref initialiser to display the contents of the file. Failure to provide a document path will result in a company home controller.
 
 @param nodeRef - the node ref of the document to be shown. Providing nil will result in a Company Home being displayed.
 @param session - an active session
 */
- (instancetype)initWithDocumentNodeRef:(NSString *)nodeRef session:(id<AlfrescoSession>)session;

/**
 Use the previous search string initialiser to initiate the specified search
 
 @param string - previous search string
 @param listingContext - the listing context with a paging definition that's used to retrieve search nodes
 @param session - an active session
 */
- (instancetype)initWithSearchString:(NSString *)string searchOptions:(AlfrescoKeywordSearchOptions *)options emptyMessage:(NSString *)emptyMessage listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session;

/**
 Use the folder type id initialiser when needing to display folders such as "My Files" or "Shared Files"
 
 @param (CustomFolderServiceFolderType)folderType - the custom folder type to display
 @param folderDisplayName - the name that will be visible to the user when at the root of the navigation stack.
 @param listingContext - the listing context with a paging definition that's used to retrieve the children.
 @param session - an active session
 */
- (instancetype)initWithCustomFolderType:(CustomFolderServiceFolderType)folderType folderDisplayName:(NSString *)displayName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session;

/**
 Use when needing to display the list of top level favorite nodes
 
 @param filter - values: all|folders|files
 @param listingContext - the listing context with a paging definition that's used to retrieve favorite nodes.
 @param session - an active session
 */
- (instancetype)initForFavoritesWithFilter:(NSString *)filter listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session;

/**
 Use the search statement initialiser to initiate a CMIS search

 @param statement - the CMIS statement
 @param displayName - the name that will be visible to the user
 @param listingContext - the listing context with a paging definition that's used to retrieve search nodes
 @param session - an active session
 */
- (instancetype)initWithSearchStatement:(NSString *)statement displayName:(NSString *)displayName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session;

@end

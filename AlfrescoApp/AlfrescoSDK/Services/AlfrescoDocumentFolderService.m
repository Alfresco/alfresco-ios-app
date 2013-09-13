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

#import "AlfrescoDocumentFolderService.h"
#import "AlfrescoPlaceholderDocumentFolderService.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CMISDocument.h"
#import "CMISSession.h"
#import "CMISQueryResult.h"
#import "CMISObjectConverter.h"
#import "CMISObjectId.h"
#import "CMISFolder.h"
#import "CMISPagedResult.h"
#import "CMISOperationContext.h"
#import "CMISConstants.h"
#import "CMISStringInOutParameter.h"
#import "CMISRendition.h"
#import "CMISEnums.h"
#import "CMISErrors.h"
#import "AlfrescoCMISToAlfrescoObjectConverter.h"
#import "AlfrescoProperty.h"
#import "AlfrescoErrors.h"
#import "AlfrescoListingContext.h"
#import "AlfrescoInternalConstants.h"
#import <objc/runtime.h>
#import "AlfrescoInternalConstants.h"
#import "AlfrescoPagingUtils.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoSortingUtils.h"
#import "AlfrescoCloudSession.h"
#import "AlfrescoFileManager.h"
#import "AlfrescoNetworkProvider.h"
#import "AlfrescoLog.h"
#import "AlfrescoCMISUtil.h"
#import "AlfrescoFavoritesCache.h"

typedef void (^CMISObjectCompletionBlock)(CMISObject *cmisObject, NSError *error);

@interface AlfrescoDocumentFolderService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) CMISSession *cmisSession;
@property (nonatomic, strong, readwrite) AlfrescoCMISToAlfrescoObjectConverter *objectConverter;
@property (nonatomic, weak, readwrite) id<AlfrescoAuthenticationProvider> authenticationProvider;
@property (nonatomic, strong, readwrite) AlfrescoFavoritesCache *favoritesCache;
@property (nonatomic, strong, readwrite) NSArray *supportedSortKeys;
@property (nonatomic, strong, readwrite) NSString *defaultSortKey;
@end

@implementation AlfrescoDocumentFolderService

+ (id)alloc
{
    if (self == [AlfrescoDocumentFolderService self])
    {
        return [AlfrescoPlaceholderDocumentFolderService alloc];
    }
    return [super alloc];
}

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if (nil != self)
    {
        self.session = session;
        self.cmisSession = [session objectForParameter:kAlfrescoSessionKeyCmisSession];
        self.objectConverter = [[AlfrescoCMISToAlfrescoObjectConverter alloc] initWithSession:self.session];
        id authenticationObject = [session objectForParameter:kAlfrescoAuthenticationProviderObjectKey];
        self.authenticationProvider = nil;
        if ([authenticationObject isKindOfClass:[AlfrescoBasicAuthenticationProvider class]])
        {
            self.authenticationProvider = (AlfrescoBasicAuthenticationProvider *)authenticationObject;
        }
        self.defaultSortKey = kAlfrescoSortByName;
        self.supportedSortKeys = [NSArray arrayWithObjects:kAlfrescoSortByName, kAlfrescoSortByTitle, kAlfrescoSortByDescription, kAlfrescoSortByCreatedAt, kAlfrescoSortByModifiedAt, nil];
    }
    return self;
}

#pragma mark - Create methods

- (AlfrescoRequest *)createFolderWithName:(NSString *)folderName
                           inParentFolder:(AlfrescoFolder *)folder
                               properties:(NSDictionary *)properties
                          completionBlock:(AlfrescoFolderCompletionBlock)completionBlock;
{
    return [self createFolderWithName:folderName inParentFolder:folder properties:properties aspects:nil type:nil completionBlock:completionBlock];
}

/**
 TODO needs to be fully implemented
 */
- (AlfrescoRequest *)createFolderWithName:(NSString *)folderName
                           inParentFolder:(AlfrescoFolder *)folder
                               properties:(NSDictionary *)properties
                                  aspects:(NSArray *)aspects
                          completionBlock:(AlfrescoFolderCompletionBlock)completionBlock
{
    return [self createFolderWithName:folderName inParentFolder:folder properties:properties aspects:aspects type:nil completionBlock:completionBlock];
}

/**
 TODO needs to be fully implemented
 */
- (AlfrescoRequest *)createFolderWithName:(NSString *)folderName
                           inParentFolder:(AlfrescoFolder *)folder
                               properties:(NSDictionary *)properties
                                  aspects:(NSArray *)aspects
                                     type:(NSString *)type
                          completionBlock:(AlfrescoFolderCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:folder argumentName:@"folder"];
    [AlfrescoErrors assertArgumentNotNil:folder.identifier argumentName:@"folder.identifier"];
    [AlfrescoErrors assertArgumentNotNil:folderName argumentName:@"folderName"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSDictionary *processedProperties = [self propertiesForName:folderName properties:properties type:type aspects:aspects isFolder:YES];
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession createFolder:processedProperties inFolder:folder.identifier completionBlock:^(NSString *folderRef, NSError *error){
        if (request.isCancelled)
        {
            if (nil == error)
            {
                // Request was cancelled too late to generate a cancellation error code, so create one now
                error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeCancelled detailedDescription:@"Request was cancelled"];
            }
            completionBlock(nil, [AlfrescoCMISUtil alfrescoErrorWithCMISError:error]);
        }
        else if (nil != folderRef)
        {
            request = [self retrieveNodeWithIdentifier:folderRef completionBlock:^(AlfrescoNode *node, NSError *error) {
                completionBlock((AlfrescoFolder *)node, error);
            }];
        }
        else
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
    }];
    return request;
}




- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                                contentFile:(AlfrescoContentFile *)file
                                 properties:(NSDictionary *)properties 
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock
{
    return [self createDocumentWithName:documentName
                         inParentFolder:folder
                            contentFile:file
                             properties:properties
                                aspects:nil
                                   type:nil
                        completionBlock:completionBlock
                          progressBlock:progressBlock];
}

/**
 TODO needs to be fully implemented
 */
- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                                contentFile:(AlfrescoContentFile *)file
                                 properties:(NSDictionary *)properties
                                    aspects:(NSArray *)aspects
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock
{
    return [self createDocumentWithName:documentName
                         inParentFolder:folder
                            contentFile:file
                             properties:properties
                                aspects:aspects
                                   type:nil
                        completionBlock:completionBlock
                          progressBlock:progressBlock];
}





/**
 TODO needs to be fully implemented
 */
- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                                contentFile:(AlfrescoContentFile *)file
                                 properties:(NSDictionary *)properties
                                    aspects:(NSArray *)aspects
                                       type:(NSString *)type
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock
{
    [AlfrescoErrors assertArgumentNotNil:file argumentName:@"file"];
    [AlfrescoErrors assertArgumentNotNil:folder argumentName:@"folder"];
    [AlfrescoErrors assertArgumentNotNil:folder.identifier argumentName:@"folder.identifier"];
    [AlfrescoErrors assertArgumentNotNil:documentName argumentName:@"folderName"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    [AlfrescoErrors assertArgumentNotNil:progressBlock argumentName:@"progressBlock"];
    
    NSDictionary *processedProperties = [self propertiesForName:documentName properties:properties type:type aspects:aspects isFolder:NO];
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession createDocumentFromFilePath:[file.fileUrl path] mimeType:file.mimeType properties:processedProperties inFolder:folder.identifier completionBlock:^(NSString *identifier, NSError *error){
        if (request.isCancelled)
        {
            if (nil == error)
            {
                // Request was cancelled too late to generate a cancellation error code, so create one now
                error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeCancelled detailedDescription:@"Request was cancelled"];
            }
            completionBlock(nil, [AlfrescoCMISUtil alfrescoErrorWithCMISError:error]);
        }
        else if (nil == identifier)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            request = [self retrieveNodeWithIdentifier:identifier completionBlock:^(AlfrescoNode *node, NSError *error) {
                
                completionBlock((AlfrescoDocument *)node, error);
                if (nil != node)
                {
                    BOOL isExtractMetadata = [[self.session objectForParameter:kAlfrescoMetadataExtraction] boolValue];
                    if (isExtractMetadata)
                    {
                        [self extractMetadataForNode:node alfrescoRequest:request];
                    }
                    BOOL isGenerateThumbnails = [[self.session objectForParameter:kAlfrescoThumbnailCreation] boolValue];
                    if (isGenerateThumbnails)
                    {
                        [self generateThumbnailForNode:node alfrescoRequest:request];
                    }
                }
            }];
            
        }
    } progressBlock:^(unsigned long long bytesUploaded, unsigned long long bytesTotal){
        if (progressBlock)
        {
            progressBlock(bytesUploaded, bytesTotal);
        }
    }];
    return request;
}


- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                              contentStream:(AlfrescoContentStream *)contentStream
                                 properties:(NSDictionary *)properties
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock
{
    
    return [self createDocumentWithName:documentName
                         inParentFolder:folder
                          contentStream:contentStream
                             properties:properties
                                aspects:nil
                                   type:nil
                        completionBlock:completionBlock
                          progressBlock:progressBlock];
}

/**
 TODO needs to be fully implemented
 */
- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                              contentStream:(AlfrescoContentStream *)contentStream
                                 properties:(NSDictionary *)properties
                                    aspects:(NSArray *)aspects
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock
{
    return [self createDocumentWithName:documentName
                         inParentFolder:folder
                          contentStream:contentStream
                             properties:properties
                                aspects:aspects
                                   type:nil
                        completionBlock:completionBlock
                          progressBlock:progressBlock];
}

/**
 TODO needs to be fully implemented
 */
- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                              contentStream:(AlfrescoContentStream *)contentStream
                                 properties:(NSDictionary *)properties
                                    aspects:(NSArray *)aspects
                                       type:(NSString *)type
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock
{
    [AlfrescoErrors assertArgumentNotNil:contentStream argumentName:@"contentStream"];
    [AlfrescoErrors assertArgumentNotNil:folder argumentName:@"folder"];
    [AlfrescoErrors assertArgumentNotNil:folder.identifier argumentName:@"folder.identifier"];
    [AlfrescoErrors assertArgumentNotNil:documentName argumentName:@"folderName"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    [AlfrescoErrors assertArgumentNotNil:progressBlock argumentName:@"progressBlock"];
    NSDictionary *processedProperties = [self propertiesForName:documentName properties:properties type:type aspects:aspects isFolder:NO];
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession createDocumentFromInputStream:contentStream.inputStream
                                                                 mimeType:contentStream.mimeType
                                                               properties:processedProperties
                                                                 inFolder:folder.identifier
                                                            bytesExpected:contentStream.length
                                                          completionBlock:^(NSString *objectId, NSError *error) {
        if (request.isCancelled)
        {
            if (nil == error)
            {
                // Request was cancelled too late to generate a cancellation error code, so create one now
                error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeCancelled detailedDescription:@"Request was cancelled"];
            }
            completionBlock(nil, [AlfrescoCMISUtil alfrescoErrorWithCMISError:error]);
        }
        else if (nil == objectId)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            request = [self retrieveNodeWithIdentifier:objectId completionBlock:^(AlfrescoNode *node, NSError *error) {
                completionBlock((AlfrescoDocument *)node, error);
                if (nil != node)
                {
                    BOOL isExtractMetadata = [[self.session objectForParameter:kAlfrescoMetadataExtraction] boolValue];
                    if (isExtractMetadata)
                    {
                        [self extractMetadataForNode:node alfrescoRequest:request];
                    }
                    BOOL isGenerateThumbnails = [[self.session objectForParameter:kAlfrescoThumbnailCreation] boolValue];
                    if (isGenerateThumbnails)
                    {
                        [self generateThumbnailForNode:node alfrescoRequest:request];
                    }
                }
            }];
        }
    } progressBlock:^(unsigned long long bytesUploaded, unsigned long long bytesTotal) {
        if (progressBlock && 0 < contentStream.length)
        {
            progressBlock(bytesUploaded, bytesTotal);
        }
    }];
    return request;
}


#pragma mark - Retrieval methods
- (AlfrescoRequest *)retrieveRootFolderWithCompletionBlock:(AlfrescoFolderCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveRootFolderWithCompletionBlock:^(CMISFolder *cmisFolder, NSError *error){
        AlfrescoFolder *rootFolder = nil;
        if (nil != cmisFolder)
        {
            rootFolder = (AlfrescoFolder *)[self.objectConverter nodeFromCMISObject:cmisFolder];
            completionBlock(rootFolder, error);
        }
        else
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
    }];
    return request;    
}

- (AlfrescoRequest *)retrievePermissionsOfNode:(AlfrescoNode *)node 
                               completionBlock:(AlfrescoPermissionsCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    id associatedPermissionsObject = objc_getAssociatedObject(node, &kAlfrescoPermissionsObjectKey);
    if (nil != associatedPermissionsObject && [associatedPermissionsObject isKindOfClass:[AlfrescoPermissions class]])
    {
        completionBlock((AlfrescoPermissions *)associatedPermissionsObject, nil);
        return nil;
    }
    else
    {
        return [self retrieveNodeWithIdentifier:node.identifier completionBlock:^(AlfrescoNode *retrievedNode, NSError *error){
            if (nil == retrievedNode)
            {
                NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                completionBlock(nil, alfrescoError);
            }
            else
            {
                id associatedObject = objc_getAssociatedObject(retrievedNode, &kAlfrescoPermissionsObjectKey);
                if ([associatedObject isKindOfClass:[AlfrescoPermissions class]])
                {
                    completionBlock((AlfrescoPermissions *)associatedObject, error);
                }
                else
                {
                    error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderPermissions];
                    completionBlock(nil, error);
                }
            }
        }];        
    }
    
}


- (AlfrescoRequest *)retrieveChildrenInFolder:(AlfrescoFolder *)folder 
                              completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:folder argumentName:@"folder"];
    [AlfrescoErrors assertArgumentNotNil:folder.identifier argumentName:@"folder.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:folder.identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else if (![cmisObject isKindOfClass:[CMISFolder class]])
        {
            NSError *classError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderWrongNodeType];
            completionBlock(nil, classError);
        }
        else
        {
            CMISFolder *folder = (CMISFolder *)cmisObject;
            request.httpRequest = [folder retrieveChildrenWithCompletionBlock:^(CMISPagedResult *pagedResult, NSError *error){
                if (nil == pagedResult)
                {
                    NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                    completionBlock(nil, alfrescoError);
                }
                else
                {
                    NSMutableArray *children = [NSMutableArray array];
                    for (CMISObject *cmisObject in pagedResult.resultArray)
                    {
                        [children addObject:[self.objectConverter nodeFromCMISObject:cmisObject]];
                    }
                    NSArray *sortedArray = [AlfrescoSortingUtils sortedArrayForArray:children sortKey:self.defaultSortKey ascending:YES];
                    completionBlock(sortedArray, nil);
                }
            }];
        }
    }];
    return request;
}





- (AlfrescoRequest *)retrieveChildrenInFolder:(AlfrescoFolder *)folder
                               listingContext:(AlfrescoListingContext *)listingContext
                              completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock 
{
    [AlfrescoErrors assertArgumentNotNil:folder argumentName:@"folder"];
    [AlfrescoErrors assertArgumentNotNil:folder.identifier argumentName:@"folder.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:folder.identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else if (![cmisObject isKindOfClass:[CMISFolder class]])
        {
            NSError *classError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderWrongNodeType];
            completionBlock(nil, classError);
        }
        else
        {
            CMISFolder *folder = (CMISFolder *)cmisObject;
            CMISOperationContext *opContext = [CMISOperationContext defaultOperationContext];
            if (listingContext.maxItems > 0)
            {
                opContext.maxItemsPerPage = listingContext.maxItems;
                opContext.skipCount = listingContext.skipCount;
            }
            
            request.httpRequest = [folder retrieveChildrenWithOperationContext:opContext completionBlock:^(CMISPagedResult *pagedResult, NSError *error){
                if (nil == pagedResult)
                {
                    NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                    completionBlock(nil, alfrescoError);
                }
                else
                {
                    AlfrescoPagingResult *pagingResult = nil;
                    NSMutableArray *children = [NSMutableArray array];
                    for (CMISObject *node in pagedResult.resultArray)
                    {
                        [children addObject:[self.objectConverter nodeFromCMISObject:node]];
                    }
                    NSArray *sortedChildren = nil;
                    if (0 < children.count)
                    {
                        sortedChildren = [AlfrescoSortingUtils sortedArrayForArray:children
                                                                           sortKey:listingContext.sortProperty
                                                                     supportedKeys:self.supportedSortKeys
                                                                        defaultKey:self.defaultSortKey
                                                                         ascending:listingContext.sortAscending];
                    }
                    else
                    {
                        sortedChildren = [NSArray array];
                    }
                    pagingResult = [[AlfrescoPagingResult alloc] initWithArray:sortedChildren hasMoreItems:pagedResult.hasMoreItems totalItems:pagedResult.numItems];
//                    pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedChildren listingContext:listingContext];
                    completionBlock(pagingResult, nil);
                }
            }];
        }
    }];
    return request;
}



- (AlfrescoRequest *)retrieveDocumentsInFolder:(AlfrescoFolder *)folder 
                               completionBlock:(AlfrescoArrayCompletionBlock)completionBlock 
{
    [AlfrescoErrors assertArgumentNotNil:folder argumentName:@"folder"];
    [AlfrescoErrors assertArgumentNotNil:folder.identifier argumentName:@"folder.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];

    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:folder.identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else if (![cmisObject isKindOfClass:[CMISFolder class]])
        {
            NSError *classError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderWrongNodeType];
            completionBlock(nil, classError);
        }
        else
        {
            CMISFolder *folder = (CMISFolder *)cmisObject;
            request.httpRequest = [folder retrieveChildrenWithCompletionBlock:^(CMISPagedResult *pagedResult, NSError *error){
                if (nil == pagedResult)
                {
                    NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                    completionBlock(nil, alfrescoError);
                }
                else
                {
                    NSArray *sortedDocuments = nil;
                    NSArray *documents = [self retrieveItemsWithClassFilter:[AlfrescoDocument class] withArray:pagedResult.resultArray];
                    if (documents.count > 0)
                    {
                        sortedDocuments = [AlfrescoSortingUtils sortedArrayForArray:documents sortKey:self.defaultSortKey ascending:YES];
                    }
                    else
                    {
                        sortedDocuments = [NSArray array];
                    }
                    completionBlock(sortedDocuments, nil);
                }
            }];
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveDocumentsInFolder:(AlfrescoFolder *)folder
                                listingContext:(AlfrescoListingContext *)listingContext
                               completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:folder argumentName:@"folder"];
    [AlfrescoErrors assertArgumentNotNil:folder.identifier argumentName:@"folder.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:folder.identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else if (![cmisObject isKindOfClass:[CMISFolder class]])
        {
            NSError *classError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderWrongNodeType];
            completionBlock(nil, classError);
        }
        else
        {
            CMISFolder *folder = (CMISFolder *)cmisObject;
            request.httpRequest = [folder retrieveChildrenWithCompletionBlock:^(CMISPagedResult *pagedResult, NSError *error){
                if (nil == pagedResult)
                {
                    NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                    completionBlock(nil, alfrescoError);
                }
                else
                {
                    NSArray *sortedDocuments = nil;
                    NSArray *documents = [self retrieveItemsWithClassFilter:[AlfrescoDocument class] withArray:pagedResult.resultArray];
                    if (documents.count > 0)
                    {
                        sortedDocuments = [AlfrescoSortingUtils sortedArrayForArray:documents
                                                                            sortKey:listingContext.sortProperty
                                                                      supportedKeys:self.supportedSortKeys
                                                                         defaultKey:self.defaultSortKey
                                                                          ascending:listingContext.sortAscending];
                    }
                    else
                    {
                        sortedDocuments = [NSArray array];
                    }
                    AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedDocuments listingContext:listingContext];
                    completionBlock(pagingResult, nil);
                }
            }];
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveFoldersInFolder:(AlfrescoFolder *)folder 
                             completionBlock:(AlfrescoArrayCompletionBlock)completionBlock 
{
    [AlfrescoErrors assertArgumentNotNil:folder argumentName:@"folder"];
    [AlfrescoErrors assertArgumentNotNil:folder.identifier argumentName:@"folder.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];

    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:folder.identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else if (![cmisObject isKindOfClass:[CMISFolder class]])
        {
            NSError *classError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderWrongNodeType];
            completionBlock(nil, classError);
        }
        else
        {
            CMISFolder *folder = (CMISFolder *)cmisObject;
            request.httpRequest = [folder retrieveChildrenWithCompletionBlock:^(CMISPagedResult *pagedResult, NSError *error){
                if (nil == pagedResult)
                {
                    NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                    completionBlock(nil, alfrescoError);
                }
                else
                {
                    NSArray *sortedFolders = nil;
                    NSArray *folders = [self retrieveItemsWithClassFilter:[AlfrescoFolder class] withArray:pagedResult.resultArray];
                    if (0 < folders.count)
                    {
                        sortedFolders = [AlfrescoSortingUtils sortedArrayForArray:folders sortKey:self.defaultSortKey ascending:YES];
                    }
                    else
                    {
                        sortedFolders = [NSArray array];
                    }
                    completionBlock(sortedFolders, nil);
                }
            }];
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveFoldersInFolder:(AlfrescoFolder *)folder
                              listingContext:(AlfrescoListingContext *)listingContext
                             completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock 
{
    [AlfrescoErrors assertArgumentNotNil:folder argumentName:@"folder"];
    [AlfrescoErrors assertArgumentNotNil:folder.identifier argumentName:@"folder.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:folder.identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else if (![cmisObject isKindOfClass:[CMISFolder class]])
        {
            NSError *classError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderWrongNodeType];
            completionBlock(nil, classError);
        }
        else
        {
            CMISFolder *folder = (CMISFolder *)cmisObject;
            request.httpRequest = [folder retrieveChildrenWithCompletionBlock:^(CMISPagedResult *pagedResult, NSError *error){
                if (nil == pagedResult)
                {
                    NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                    completionBlock(nil, alfrescoError);
                }
                else
                {
                    NSArray *sortedFolders = nil;
                    NSArray *folders = [self retrieveItemsWithClassFilter:[AlfrescoFolder class] withArray:pagedResult.resultArray];
                    if (0 < folders.count)
                    {
                        sortedFolders = [AlfrescoSortingUtils sortedArrayForArray:folders
                                                                          sortKey:listingContext.sortProperty
                                                                    supportedKeys:self.supportedSortKeys
                                                                       defaultKey:self.defaultSortKey
                                                                        ascending:listingContext.sortAscending];
                    }
                    else
                    {
                        sortedFolders = [NSArray array];
                    }
                    AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:sortedFolders listingContext:listingContext];
                    completionBlock(pagingResult, nil);
                }
            }];
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveNodeWithIdentifier:(NSString *)identifier
                                completionBlock:(AlfrescoNodeCompletionBlock)completionBlock 
{
    [AlfrescoErrors assertArgumentNotNil:identifier argumentName:@"identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];

    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            AlfrescoNode *node = [self.objectConverter nodeFromCMISObject:cmisObject];
            NSError *conversionError = nil;
            if (nil == node)
            {
                conversionError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderFailedToConvertNode];
            }
            completionBlock(node, conversionError);
            
        }
    }];
    return request;
}



- (AlfrescoRequest *)retrieveNodeWithFolderPath:(NSString *)path 
                                completionBlock:(AlfrescoNodeCompletionBlock)completionBlock 
{
    [AlfrescoErrors assertArgumentNotNil:path argumentName:@"path"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObjectByPath:path completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            AlfrescoNode *node = [self.objectConverter nodeFromCMISObject:cmisObject];
            NSError *conversionError = nil;
            if (nil == node)
            {
                conversionError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderFailedToConvertNode];
            }
            completionBlock(node, conversionError);
        }
    }];
    return request;
}


- (AlfrescoRequest *)retrieveNodeWithFolderPath:(NSString *)path
                               relativeToFolder:(AlfrescoFolder *)folder
                                completionBlock:(AlfrescoNodeCompletionBlock)completionBlock 
{
    [AlfrescoErrors assertArgumentNotNil:path argumentName:@"path"];
    [AlfrescoErrors assertArgumentNotNil:folder argumentName:@"folder"];
    [AlfrescoErrors assertArgumentNotNil:folder.identifier argumentName:@"folder.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:folder.identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            CMISFolder *folder = (CMISFolder *)cmisObject;
            NSString *searchPath = [folder.path stringByAppendingPathComponent:path];
            request = [self retrieveNodeWithFolderPath:searchPath completionBlock:completionBlock];
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveParentFolderOfNode:(AlfrescoNode *)node
                                completionBlock:(AlfrescoFolderCompletionBlock)completionBlock 
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession.binding.navigationService retrieveParentsForObject:node.identifier
                                                                                        filter:nil
                                                                                 relationships:CMISIncludeRelationshipBoth
                                                                               renditionFilter:nil
                                                                       includeAllowableActions:YES
                                                                    includeRelativePathSegment:YES
                                                                               completionBlock:^(NSArray *parents, NSError *error){
       if (nil == parents)
       {
           NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
           completionBlock(nil, alfrescoError);
       }
       else
       {
           AlfrescoFolder *parentFolder = nil;
           NSError *folderError = nil;
           for (CMISObjectData * cmisObjectData in parents)
           {
               AlfrescoNode *node = (AlfrescoNode *)[self.objectConverter nodeFromCMISObjectData:cmisObjectData];
               if ([node isKindOfClass:[AlfrescoFolder class]])
               {
                   parentFolder = (AlfrescoFolder *)node;
                   break;
               }
           }
           if (nil == parentFolder)
           {
               folderError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderNoParent];
           }
           completionBlock(parentFolder, folderError);
       }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveRenditionOfNode:(AlfrescoNode *)node
                               renditionName:(NSString *)renditionName
                             completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveRenditionOfNode:(AlfrescoNode *)node
                               renditionName:(NSString *)renditionName
                                outputStream:(NSOutputStream *)outputStream
                             completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveContentOfDocument:(AlfrescoDocument *)document
                               completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
                                 progressBlock:(AlfrescoProgressBlock)progressBlock
{
    [AlfrescoErrors assertArgumentNotNil:document argumentName:@"document"];
    [AlfrescoErrors assertArgumentNotNil:document.identifier argumentName:@"document.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];

    NSString *tmpFile = [NSTemporaryDirectory() stringByAppendingPathComponent:document.name];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession downloadContentOfCMISObject:document.identifier toFile:tmpFile completionBlock:^(NSError *error){
        if (error)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            AlfrescoContentFile *downloadedFile = [[AlfrescoContentFile alloc]initWithUrl:[NSURL fileURLWithPath:tmpFile]];
            completionBlock(downloadedFile, nil);
        }
    } progressBlock:^(unsigned long long bytesDownloaded, unsigned long long bytesTotal){
        if (progressBlock)
        {
            progressBlock(bytesDownloaded, bytesTotal);
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveContentOfDocument:(AlfrescoDocument *)document
                                  outputStream:(NSOutputStream *)outputStream
                               completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
                                 progressBlock:(AlfrescoProgressBlock)progressBlock
{
    [AlfrescoErrors assertArgumentNotNil:document argumentName:@"document"];
    [AlfrescoErrors assertArgumentNotNil:document.identifier argumentName:@"document.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession downloadContentOfCMISObject:document.identifier toOutputStream:outputStream completionBlock:^(NSError *error) {
        if (error)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(NO, alfrescoError);
        }
        else
        {
            completionBlock(YES, nil);
        }
    } progressBlock:^(unsigned long long bytesDownloaded, unsigned long long bytesTotal) {
        if (progressBlock)
        {
            progressBlock(bytesDownloaded, bytesTotal);
        }
    }];
    return request;
}

#pragma mark - Modification methods
- (AlfrescoRequest *)updateContentOfDocument:(AlfrescoDocument *)document
                               contentStream:(AlfrescoContentStream *)contentStream
                             completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                               progressBlock:(AlfrescoProgressBlock)progressBlock
{
    [AlfrescoErrors assertArgumentNotNil:contentStream argumentName:@"contentStream"];
    [AlfrescoErrors assertArgumentNotNil:document argumentName:@"document"];
    [AlfrescoErrors assertArgumentNotNil:document.identifier argumentName:@"document.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:document.identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            CMISDocument *cmisDocument = (CMISDocument *)cmisObject;
            request.httpRequest = [cmisDocument changeContentToContentOfInputStream:contentStream.inputStream
                                                                      bytesExpected:contentStream.length
                                                                           fileName:document.name
                                                                           mimeType:contentStream.mimeType
                                                                          overwrite:YES
                                                                    completionBlock:^(NSError *error){
                if (error)
                {
                    completionBlock(nil, error);
                }
                else
                {
                    NSString *versionSeriesId = [cmisObject.properties propertyValueForId:@"cmis:versionSeriesId"];
                    request.httpRequest = [self.cmisSession retrieveObject:versionSeriesId completionBlock:^(CMISObject *updatedObject, NSError *updatedError){
                        if (nil == updatedObject)
                        {
                            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:updatedError];
                            completionBlock(nil, alfrescoError);
                        }
                        else
                        {
                            AlfrescoDocument *alfrescoDocument = (AlfrescoDocument *)[self.objectConverter nodeFromCMISObject:updatedObject];
                            NSError *alfrescoError = nil;
                            if (nil == alfrescoDocument)
                            {
                                alfrescoError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderFailedToConvertNode];
                            }
                            completionBlock(alfrescoDocument, alfrescoError);
                        }
                    }];
                }
            } progressBlock:^(unsigned long long bytesUploaded, unsigned long long bytesTotal){
                if(progressBlock && 0 < contentStream.length)
                {
                    progressBlock(bytesUploaded, bytesTotal);
                }
            }];
        }
    }];
    return request;
    
}

- (AlfrescoRequest *)updateContentOfDocument:(AlfrescoDocument *)document
                                 contentFile:(AlfrescoContentFile *)file
                             completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                               progressBlock:(AlfrescoProgressBlock)progressBlock
{
    [AlfrescoErrors assertArgumentNotNil:file argumentName:@"file"];
    [AlfrescoErrors assertArgumentNotNil:document argumentName:@"document"];
    [AlfrescoErrors assertArgumentNotNil:document.identifier argumentName:@"document.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:document.identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            CMISDocument *document = (CMISDocument *)cmisObject;
            request.httpRequest = [document changeContentToContentOfFile:[file.fileUrl path] mimeType:file.mimeType overwrite:YES completionBlock:^(NSError *error){
                if (error)
                {
                    completionBlock(nil, error);
                }
                else
                {
                    NSString *versionSeriesId = [cmisObject.properties propertyValueForId:@"cmis:versionSeriesId"];
                    request.httpRequest = [self.cmisSession retrieveObject:versionSeriesId completionBlock:^(CMISObject *updatedObject, NSError *updatedError){
                        if (nil == updatedObject)
                        {
                            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:updatedError];
                            completionBlock(nil, alfrescoError);
                        }
                        else
                        {
                            AlfrescoDocument *alfrescoDocument = (AlfrescoDocument *)[self.objectConverter nodeFromCMISObject:updatedObject];
                            NSError *alfrescoError = nil;
                            if (nil == alfrescoDocument)
                            {
                                alfrescoError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderFailedToConvertNode];
                            }
                            completionBlock(alfrescoDocument, alfrescoError);
                        }
                    }];
                }
            } progressBlock:^(unsigned long long bytesUploaded, unsigned long long bytesTotal){
                if(progressBlock)
                {
                    progressBlock(bytesUploaded, bytesTotal);
                }
            }];
        }
    }];
    return request;    
}


- (AlfrescoRequest *)updatePropertiesOfNode:(AlfrescoNode *)node 
                                 properties:(NSDictionary *)properties
                            completionBlock:(AlfrescoNodeCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:properties argumentName:@"properties"];
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSMutableDictionary *cmisProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
    if ([[properties allKeys] containsObject:kAlfrescoPropertyName])
    {
        NSString *name = [properties valueForKey:kAlfrescoPropertyName];
        AlfrescoLogDebug(@"updatePropertiesOfNode contains key %@ with value %@",kAlfrescoPropertyName, name );
        [cmisProperties setValue:name forKey:@"cmis:name"];
        [cmisProperties removeObjectForKey:kAlfrescoPropertyName];
    }
    
    if (![[cmisProperties allKeys] containsObject:@"cmis:name"])
    {
        AlfrescoLogDebug(@"updatePropertiesOfNode we do NOT have a cmis:name property. so let's set it now to the node name");
        [cmisProperties setValue:node.name forKey:@"cmis:name"];
    }
    
    NSString *cmisNodeType = node.type;
    if ([node.type hasPrefix:kAlfrescoTypeContent])
    {
        cmisNodeType = kCMISPropertyObjectTypeIdValueDocument;
    }
    else if ([node.type hasPrefix:kAlfrescoTypeFolder])
    {
        cmisNodeType = kCMISPropertyObjectTypeIdValueFolder;
    }
    
    NSString *objectTypeId = [properties objectForKey:kCMISPropertyObjectTypeId];
    if (nil != objectTypeId)
    {
        if ([objectTypeId rangeOfString:kAlfrescoTypeFolder].location != NSNotFound)
        {
            objectTypeId = [objectTypeId stringByReplacingOccurrencesOfString:kAlfrescoTypeFolder withString:kCMISPropertyObjectTypeIdValueFolder];
        }
        else if ([objectTypeId rangeOfString:kAlfrescoTypeContent].location != NSNotFound)
        {
            objectTypeId = [objectTypeId stringByReplacingOccurrencesOfString:kAlfrescoTypeContent withString:kCMISPropertyObjectTypeIdValueDocument];            
        }
        [cmisProperties setValue:objectTypeId forKey:kCMISPropertyObjectTypeId];
    }
    else if (objectTypeId == nil && [cmisNodeType hasPrefix:@"cmis:"])
    {
        objectTypeId = cmisNodeType;
        
        // iterate around the aspects the node has and append them (expect system aspects)
        for (NSString *aspectName in node.aspects)
        {
            if (![aspectName hasPrefix:@"sys:"])
            {
                objectTypeId = [objectTypeId stringByAppendingFormat:@",P:%@", aspectName];
            }
        }
        
        AlfrescoLogDebug(@"cmis:objectTypeId = %@", objectTypeId);
        
        // set the fully qualified objectTypeId
        [cmisProperties setValue:objectTypeId forKey:kCMISPropertyObjectTypeId];
    }
    
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request.httpRequest = [self.cmisSession retrieveObject:node.identifier completionBlock:^(CMISObject *cmisObject, NSError *error){
        if (nil == cmisObject)
        {
            NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
            completionBlock(nil, alfrescoError);
        }
        else
        {
            [self.cmisSession.objectConverter
             convertProperties:cmisProperties
             forObjectTypeId:cmisObject.objectType
             completionBlock:^(CMISProperties *convertedProperties, NSError *conversionError){
                 if (nil == convertedProperties)
                 {
                     NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:conversionError];
                     completionBlock(nil, alfrescoError);
                 }
                 else
                 {
                     CMISProperties *updatedProperties = [[CMISProperties alloc] init];
                     NSEnumerator *enumerator = [convertedProperties.propertiesDictionary keyEnumerator];
                     for (NSString *cmisKey in enumerator)
                     {
                         if (![cmisKey isEqualToString:kCMISPropertyObjectTypeId])
                         {
                             CMISPropertyData *propData = [convertedProperties.propertiesDictionary objectForKey:cmisKey];
                             [updatedProperties addProperty:propData];
                         }
                     }
                     updatedProperties.extensions = convertedProperties.extensions;
                     
                     CMISStringInOutParameter *inOutParam = [CMISStringInOutParameter inOutParameterUsingInParameter:cmisObject.identifier];
                     request.httpRequest = [self.cmisSession.binding.objectService
                                            updatePropertiesForObject:inOutParam
                                            properties:updatedProperties
                                            changeToken:nil
                                            completionBlock:^(NSError *updateError){
                                                if (nil != updateError)
                                                {
                                                    NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:updateError];
                                                    completionBlock(nil, alfrescoError);
                                                }
                                                else
                                                {
                                                    NSString *versionSeriesId = [cmisObject.properties propertyValueForId:@"cmis:versionSeriesId"];
                                                    request.httpRequest = [self.cmisSession retrieveObject:versionSeriesId completionBlock:^(CMISObject *updatedCMISObject, NSError *retrievalError){
                                                        if (nil == updatedCMISObject)
                                                        {
                                                            completionBlock(nil, retrievalError);
                                                        }
                                                        else
                                                        {
                                                            AlfrescoNode *resultNode = [self.objectConverter nodeFromCMISObject:updatedCMISObject];
                                                            NSError *conversionError = nil;
                                                            if (nil == resultNode)
                                                            {
                                                                conversionError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderFailedToConvertNode];
                                                            }
                                                            completionBlock(resultNode, conversionError);
                                                        }
                                                    }];
                                                }
                                            }];
                 }
             }];
            
        }
    }];
    return request;
}

- (AlfrescoRequest *)deleteNode:(AlfrescoNode *)node
                completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    AlfrescoLogDebug(@"-------- deleteNode %@ --------", node.name);
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    if ([node isKindOfClass:[AlfrescoDocument class]])
    {
        request.httpRequest = [self.cmisSession.binding.objectService deleteObject:node.identifier allVersions:YES completionBlock:^(BOOL objectDeleted, NSError *error){
            if (!objectDeleted)
            {
                NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                completionBlock(NO, alfrescoError);
            }
            else
            {
                completionBlock(YES, nil);
            }
        }];
    }
    else
    {
        request.httpRequest = [self.cmisSession.binding.objectService deleteTree:node.identifier allVersion:YES unfileObjects:CMISDelete continueOnFailure:YES completionBlock:^(NSArray *failedObjects, NSError *error){
            if (error)
            {
                NSError *alfrescoError = [AlfrescoCMISUtil alfrescoErrorWithCMISError:error];
                completionBlock(NO, alfrescoError);
            }
            else
            {
                completionBlock(YES, nil);
            }
        }];
    }
    return request;
        
}



#pragma mark - Internal methods

// filter the provided array with items that match the provided class type
- (NSArray *)retrieveItemsWithClassFilter:(Class) typeClass withArray:(NSArray *)itemArray
{
    NSMutableArray *filteredArray = [NSMutableArray array];
    for (CMISObject *object in itemArray)
    {
        AlfrescoNode *childNode = [self.objectConverter nodeFromCMISObject:object];
        if ([childNode isKindOfClass:typeClass])
        {
            [filteredArray addObject:childNode];
        }
    }
    return filteredArray;
}

- (void)extractMetadataForNode:(AlfrescoNode *)node alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
{
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionary];
    
    NSArray *components = [node.identifier componentsSeparatedByString:@";"];
    NSString *identifier = node.identifier;
    if (components.count > 1)
    {
        identifier = [components objectAtIndex:0];
    }
    
    [jsonDictionary setValue:identifier forKey:kAlfrescoJSONActionedUponNode];
    [jsonDictionary setValue:kAlfrescoJSONExtractMetadata forKey:kAlfrescoJSONActionDefinitionName];
    NSError *postError = nil;
    NSURL *apiUrl = [AlfrescoURLUtils buildURLFromBaseURLString:[self.session.baseUrl absoluteString] extensionURL:kAlfrescoOnPremiseMetadataExtractionAPI];
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:jsonDictionary
                        options:0
                        error:&postError];
    
    [self.session.networkProvider executeRequestWithURL:apiUrl
                                     session:self.session
                                 requestBody:jsonData
                                                 method:kAlfrescoHTTPPOST
                                        alfrescoRequest:alfrescoRequest
                             completionBlock:^(NSData *data, NSError *error){}];
}

- (void)generateThumbnailForNode:(AlfrescoNode *)node alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
{
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionary];
    [jsonDictionary setValue:kAlfrescoJSONThumbnailName forKey:kAlfrescoThumbnailRendition];
    NSError *postError = nil;
    NSString *requestString = [kAlfrescoOnPremiseThumbnailCreationAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                                withString:[node.identifier stringByReplacingOccurrencesOfString:@"://"
                                                                                                                                                      withString:@"/"]];
    NSURL *apiUrl = [AlfrescoURLUtils buildURLFromBaseURLString:[self.session.baseUrl absoluteString] extensionURL:requestString];
    
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:jsonDictionary
                        options:0
                        error:&postError];
    [self.session.networkProvider executeRequestWithURL:apiUrl
                                                session:self.session
                                            requestBody:jsonData
                                                 method:kAlfrescoHTTPPOST
                                        alfrescoRequest:alfrescoRequest
                                        completionBlock:^(NSData *data, NSError *error){}];
}

- (NSString *)propertyType:(NSString *)type aspects:(NSArray *)aspects isFolder:(BOOL)isFolder
{
    NSMutableString *propertyString = [NSMutableString string];
    if (isFolder)
    {
        [propertyString appendString:kAlfrescoPropertyTypeFolder];
    }
    else
    {
        [propertyString appendString:kAlfrescoPropertyTypeDocument];
    }
    [propertyString appendString:type];
    [propertyString appendString:@","];
    for (NSString *aspect in aspects)
    {
        [propertyString appendString:kAlfrescoPropertyAspect];
        [propertyString appendString:aspect];
        [propertyString appendString:@","];
    }
    return propertyString;
}

- (NSDictionary *)propertiesForName:(NSString *)name
                         properties:(NSDictionary *)properties
                               type:(NSString *)type
                            aspects:(NSArray *)aspects
                           isFolder:(BOOL)isFolder
{
    NSMutableDictionary *processedProperties = [NSMutableDictionary dictionary];
    if (nil != properties)
    {
        [processedProperties addEntriesFromDictionary:properties];
    }
    [processedProperties setValue:name forKey:kCMISPropertyName];
    
    NSMutableString *objectTypeId = [NSMutableString string];
    
    if (nil != type)
    {
        NSString *customType = (isFolder) ? @"F:" : @"D:";
        [objectTypeId appendString:customType];
        [objectTypeId appendString:type];
        NSString *description = [processedProperties valueForKey:kAlfrescoPropertyDescription];
        NSString *title = [processedProperties valueForKey:kAlfrescoPropertyTitle];
        if (nil != title || nil != description)
        {
            [objectTypeId appendString:@", P:cm:titled"];
        }
    }
    else
    {
        NSString *objectTypeIdValue = [processedProperties valueForKey:kCMISPropertyObjectTypeId];
        if (nil == objectTypeIdValue)
        {
            NSString *typeDefinition = (isFolder) ? kCMISPropertyObjectTypeIdValueFolder : kCMISPropertyObjectTypeIdValueDocument;
            [objectTypeId appendString:typeDefinition];
            [objectTypeId appendString:@", P:cm:titled"];
        }
        else
        {
            if ([objectTypeIdValue rangeOfString:kAlfrescoTypeContent].location != NSNotFound)
            {
                NSString *cmisDocumentTypeValue = [objectTypeIdValue stringByReplacingOccurrencesOfString:kAlfrescoTypeContent withString:kCMISPropertyObjectTypeIdValueDocument];
                [objectTypeId appendString:cmisDocumentTypeValue];
            }
            else if ([objectTypeIdValue rangeOfString:kAlfrescoTypeFolder].location != NSNotFound)
            {
                NSString *cmisFolderTypeValue = [objectTypeIdValue stringByReplacingOccurrencesOfString:kAlfrescoTypeFolder withString:kCMISPropertyObjectTypeIdValueFolder];
                [objectTypeId appendString:cmisFolderTypeValue];                
            }
            else
            {
                [objectTypeId appendString:objectTypeIdValue];                
            }
        }
    }
    
    if (nil != aspects)
    {
        [aspects enumerateObjectsUsingBlock:^(NSString *aspect, NSUInteger index, BOOL *stop){
            if (![aspect hasPrefix:@"sys:"])
            {
                [objectTypeId appendString:[NSString stringWithFormat:@", P:%@", aspect]];
            }
        }];
    }
    
    [processedProperties setValue:objectTypeId forKey:kCMISPropertyObjectTypeId];
    
    return processedProperties;
}

#pragma mark - Favorites

- (AlfrescoRequest *)retrieveFavoriteDocumentsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveFavoriteDocumentsWithListingContext:(AlfrescoListingContext *)listingContext
                                                 completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveFavoriteFoldersWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveFavoriteFoldersWithListingContext:(AlfrescoListingContext *)listingContext
                                               completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveFavoriteNodesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveFavoriteNodesWithListingContext:(AlfrescoListingContext *)listingContext
                                             completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)isFavorite:(AlfrescoNode *)node
              	completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)addFavorite:(AlfrescoNode *)node
                 completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)removeFavorite:(AlfrescoNode *)node
                    completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)refreshNode:(AlfrescoNode *)node
                 completionBlock:(AlfrescoNodeCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    AlfrescoRequest *request = [self retrieveNodeWithIdentifier:node.identifier completionBlock:completionBlock];
    return request;
}

- (void)clearFavoritesCache
{
    [self.favoritesCache clear];
}

@end

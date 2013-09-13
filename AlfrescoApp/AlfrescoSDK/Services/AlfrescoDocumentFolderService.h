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
#import "AlfrescoConstants.h"
#import "AlfrescoSession.h"
#import "AlfrescoFolder.h"
#import "AlfrescoDocument.h"
#import "AlfrescoListingContext.h"
#import "AlfrescoRequest.h"
#import "AlfrescoContentStream.h"


/** The AlfrescoDocumentFolderService manages folders and documents of an Alfresco 
 repository. The service provides methods to retrieve documents and folders, but also
 provides methods to create and update documents and folders.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoDocumentFolderService : NSObject
 
/**---------------------------------------------------------------------------------------
 * @name Initialialisation
 *  ---------------------------------------------------------------------------------------
 */

/** Initialises with a standard Cloud or OnPremise session
 
 @param session the AlfrescoSession to initialise the site service with.
 */
- (id)initWithSession:(id<AlfrescoSession>)session;

/**---------------------------------------------------------------------------------------
 * @name Creating folders and documents methods.
 *  ---------------------------------------------------------------------------------------
 */
/** Creates a new folder using the given properties in the given folder.
 
 @param folderName The name of the folder to be created.
 @param folder The parent folder of the new folder.
 @param properties Additional properties that are used to create the folder.
 @param completionBlock The block that's called with the created folder in case the operation succeeds.
 */
- (AlfrescoRequest *)createFolderWithName:(NSString *)folderName
                           inParentFolder:(AlfrescoFolder *)folder
                               properties:(NSDictionary *)properties
                          completionBlock:(AlfrescoFolderCompletionBlock)completionBlock;

/** Creates a new folder using the given properties in the given folder.
 
 @param folderName The name of the folder to be created.
 @param folder The parent folder of the new folder.
 @param properties Additional properties that are used to create the folder.
 @param aspects additional aspects for this folder
 @param completionBlock The block that's called with the created folder in case the operation succeeds.
 */
- (AlfrescoRequest *)createFolderWithName:(NSString *)folderName
                           inParentFolder:(AlfrescoFolder *)folder
                               properties:(NSDictionary *)properties
                                  aspects:(NSArray *)aspects
                          completionBlock:(AlfrescoFolderCompletionBlock)completionBlock;

/** Creates a new folder using the given properties in the given folder.
 
 @param folderName The name of the folder to be created.
 @param folder The parent folder of the new folder.
 @param properties Additional properties that are used to create the folder.
 @param aspects additional aspects for this folder
 @param custom type of properties/aspects to be added/set to the new folder
 @param completionBlock The block that's called with the created folder in case the operation succeeds.
 */
- (AlfrescoRequest *)createFolderWithName:(NSString *)folderName
                           inParentFolder:(AlfrescoFolder *)folder
                               properties:(NSDictionary *)properties
                                  aspects:(NSArray *)aspects
                                     type:(NSString *)type
                          completionBlock:(AlfrescoFolderCompletionBlock)completionBlock;


/** Creates a new document using the contents of a local file. The new document is created within the given folder.
 
 @param documentName The name of the document to be created in the repository
 @param folder The parent folder to create the document in.
 @param file The local file to be uploaded.
 @param properties Additional properties that are used to create the document.
 @param completionBlock The block that's called with the created document in case the operation succeeds.
 @param progressBlock The block that's called with the upload progress.
 */
- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                                contentFile:(AlfrescoContentFile *)file
                                 properties:(NSDictionary *)properties
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock;


/** Creates a new document using the contents of a local file. The new document is created within the given folder.
 
 @param documentName The name of the document to be created in the repository
 @param folder The parent folder to create the document in.
 @param file The local file to be uploaded.
 @param properties Additional properties that are used to create the document.
 @param aspects array of additional aspects to be added
 @param completionBlock The block that's called with the created document in case the operation succeeds.
 @param progressBlock The block that's called with the upload progress.
 */
- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                                contentFile:(AlfrescoContentFile *)file
                                 properties:(NSDictionary *)properties
                                    aspects:(NSArray *)aspects
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock;

/** Creates a new document using the contents of a local file. The new document is created within the given folder.
 
 @param documentName The name of the document to be created in the repository
 @param folder The parent folder to create the document in.
 @param file The local file to be uploaded.
 @param properties Additional properties that are used to create the document.
 @param aspects array of additional aspects to be added
 @param type a custom property type to be added
 @param completionBlock The block that's called with the created document in case the operation succeeds.
 @param progressBlock The block that's called with the upload progress.
 */
- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                                contentFile:(AlfrescoContentFile *)file
                                 properties:(NSDictionary *)properties
                                    aspects:(NSArray *)aspects
                                       type:(NSString *)type
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock;



/** Creates a new document using the input stream provided. The new document is created within the given folder.
 
 @param documentName The name of the document to be created in the repository
 @param folder The parent folder to create the document in.
 @param file The local file to be uploaded.
 @param contentStream An instance of AlfrescoContent stream to be used for data access.
 @param properties Additional properties that are used to create the document.
 @param completionBlock The block that's called with the created document in case the operation succeeds.
 @param progressBlock The block that's called with the upload progress. This can only be used if the fileSize parameter is > 0.
 */
- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                              contentStream:(AlfrescoContentStream *)contentStream
                                 properties:(NSDictionary *)properties
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock;


/** Creates a new document using the input stream provided. The new document is created within the given folder.
 
 @param documentName The name of the document to be created in the repository
 @param folder The parent folder to create the document in.
 @param file The local file to be uploaded.
 @param contentStream An instance of AlfrescoContent stream to be used for data access.
 @param properties Additional properties that are used to create the document.
 @param aspects array of extra aspects to be added
 @param completionBlock The block that's called with the created document in case the operation succeeds.
 @param progressBlock The block that's called with the upload progress. This can only be used if the fileSize parameter is > 0.
 */
- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                              contentStream:(AlfrescoContentStream *)contentStream
                                 properties:(NSDictionary *)properties
                                    aspects:(NSArray *)aspects
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock;

/** Creates a new document using the input stream provided. The new document is created within the given folder.
 
 @param documentName The name of the document to be created in the repository
 @param folder The parent folder to create the document in.
 @param file The local file to be uploaded.
 @param contentStream An instance of AlfrescoContent stream to be used for data access.
 @param properties Additional properties that are used to create the document.
 @param aspects array of extra aspects to be added
 @param type a custom property type to be added
 @param completionBlock The block that's called with the created document in case the operation succeeds.
 @param progressBlock The block that's called with the upload progress. This can only be used if the fileSize parameter is > 0.
 */
- (AlfrescoRequest *)createDocumentWithName:(NSString *)documentName
                             inParentFolder:(AlfrescoFolder *)folder
                              contentStream:(AlfrescoContentStream *)contentStream
                                 properties:(NSDictionary *)properties
                                    aspects:(NSArray *)aspects
                                       type:(NSString *)type
                            completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                              progressBlock:(AlfrescoProgressBlock)progressBlock;



/**---------------------------------------------------------------------------------------
 * @name Retrieval methods.
 *  ---------------------------------------------------------------------------------------
 */
/**
 @param completionBlock Called when the call completes
 */
- (AlfrescoRequest *)retrieveRootFolderWithCompletionBlock:(AlfrescoFolderCompletionBlock)completionBlock;


/**
 @param node the node for which permissions are being queried
 @param completionBlock the block returns an AlfrescoPermissions and NSError object)
 @return the AlfrescoRequest object. If the node has an associated AlfrescoPermissions object, a network request for the node will not be necessary, and the method will return a nil AlfrescoRequest object.
 */
- (AlfrescoRequest *)retrievePermissionsOfNode:(AlfrescoNode *)node 
                               completionBlock:(AlfrescoPermissionsCompletionBlock)completionBlock;


/** Retrieves all the children of the given folder.
 
 @param folder The folder for which the children are retrieved.
 @param completionBlock The block that's called with the retrieved children in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveChildrenInFolder:(AlfrescoFolder *)folder
                              completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


/** Retrieves all the children of the given folder with a listing context.
 
 @param folder The folder for which the children are retrieved.
 @param listingContext The listing context with a paging definition that's used to retrieve the children.
 @param completionBlock The block that's called with the retrieved children in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveChildrenInFolder:(AlfrescoFolder *)folder
                               listingContext:(AlfrescoListingContext *)listingContext
                              completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;


/** Retrieves all the documents in the given folder.
 
 @param folder The folder for which the documents are retrieved.
 @param completionBlock The block that's called with the retrieved documents in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveDocumentsInFolder:(AlfrescoFolder *)folder
                               completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


/** Retrieves all the documents in the given folder with a listing context.
 
 @param folder The folder for which the documents are retrieved.
 @param listingContext The listing context with a paging definition that's used to retrieve the documents.
 @param completionBlock The block that's called with the retrieved documents in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveDocumentsInFolder:(AlfrescoFolder *)folder
                                listingContext:(AlfrescoListingContext *)listingContext
                               completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;


/** Retrieves all the sub folders in the given folder.
 
 @param folder The folder for which the sub folders are retrieved.
 @param completionBlock The block that's called with the retrieved sub folders in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveFoldersInFolder:(AlfrescoFolder *)folder
                             completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


/** Retrieves all the sub folders in the given folder with a listing context
 
 @param folder The folder for which the sub folders are retrieved.
 @param listingContext The listing context with a paging definition that's used to retrieve the sub folders.
 @param completionBlock The block that's called with the retrieved sub folders in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveFoldersInFolder:(AlfrescoFolder *)folder
                              listingContext:(AlfrescoListingContext *)listingContext
                             completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;


/** Retrieves a document or folder with the given node identifier.
 
 @param identifier The node identifier that's used to query for a specific node.
 @param completionBlock The block that's called with the retrieved node in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveNodeWithIdentifier:(NSString *)identifier
                                completionBlock:(AlfrescoNodeCompletionBlock)completionBlock;


/** Retrieves a node from the repository with the given folder path.
 
 An folder path can be for example:
 
 /important.docx
 /work/example.pptx
 
 @param path The folder path that's used to query for a specific node.
 @param completionBlock The block that's called with the retrieved node in case the operation succeeds.
 */ 
- (AlfrescoRequest *)retrieveNodeWithFolderPath:(NSString *)path 
                                completionBlock:(AlfrescoNodeCompletionBlock)completionBlock;


/** Retrieves a node from the repository with the given folder path relative to the given folder.
 
 @param path The folder path that's used to query for a specific node.
 @param folder The root folder that's used to query for a specific node.
 @param completionBlock The block that's called with the retrieved node in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveNodeWithFolderPath:(NSString *)path
                               relativeToFolder:(AlfrescoFolder *)folder
                                completionBlock:(AlfrescoNodeCompletionBlock)completionBlock;


/** Retrieves the parent folder of the given node.
 
 @param node The node for which the parent folder is retrieved.
 @param completionBlock The block that's called with the retrieved parent folder in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveParentFolderOfNode:(AlfrescoNode *)node
                                completionBlock:(AlfrescoFolderCompletionBlock)completionBlock;




/** Retrieves the thumbnail rendition file for the given node.
 
 @param node the AlfrescoNode for which a thumbnail rendition image is to be retrieved.
 @param renditionName The type of thumbnail to be retrieved. For example 'doclib' can be used (defined as _AlfrescoThumbnailRendition_ )
 @param completionBlock The block that's called with the local AlfrescoContentFile containing the thumbnail URL/data.
 */
- (AlfrescoRequest *)retrieveRenditionOfNode:(AlfrescoNode *)node
                               renditionName:(NSString *)renditionName
                             completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock;


/** Retrieves the thumbnail rendition file for the given node.
 
 @param node the AlfrescoNode for which a thumbnail rendition image is to be retrieved.
 @param renditionName The type of thumbnail to be retrieved. For example 'doclib' can be used (defined as _AlfrescoThumbnailRendition_ )
 @param outputStream The output stream to which the rendition image will be written to.
 @param completionBlock The block that's called with the local AlfrescoContentFile containing the thumbnail URL/data.
 */
- (AlfrescoRequest *)retrieveRenditionOfNode:(AlfrescoNode *)node
                               renditionName:(NSString *)renditionName
                                outputStream:(NSOutputStream *)outputStream
                             completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;



/**---------------------------------------------------------------------------------------
 * @name Updating/downloading documents and properties.
 *  ---------------------------------------------------------------------------------------
 */

/** Downloads the content of the given document and stores it in the given file. The delegate object
 will be informed when the content is downloaded.
 
 @param document The document that needs to be downloaded.
 @param completionBlock The block containing an AlfrescoContentFile and NSError object. error will be nil if successful. Otherwise, AlfrescoContentFile will be nil.
 @param progressBlock The block that's called with the download progress.
 */
// 
- (AlfrescoRequest *)retrieveContentOfDocument:(AlfrescoDocument *)document
                               completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
                                 progressBlock:(AlfrescoProgressBlock)progressBlock;


/** Downloads the content of the given document and writes it using the provided outputstream. The delegate object
 will be informed when the content is downloaded.
 
 @param document The document that needs to be downloaded.
 @param outputStream The stream used to write the contents to disk.
 @param completionBlock The block containing an AlfrescoContentFile and NSError object. error will be nil if successful. Otherwise, AlfrescoContentFile will be nil.
 @param progressBlock The block that's called with the download progress.
 */
//
- (AlfrescoRequest *)retrieveContentOfDocument:(AlfrescoDocument *)document
                                  outputStream:(NSOutputStream *)outputStream
                               completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
                    progressBlock:(AlfrescoProgressBlock)progressBlock;
    

/** Updates a document with the contents of a local file.
 
 @param document The document that needs to be updated.
 @param contentFile The Alfresco Content File to be updated.
 @param completionBlock The block that's called with the updated document in case the operation succeeds.
 @param progressBlock The block that's called with the upload progress.
 */

- (AlfrescoRequest *)updateContentOfDocument:(AlfrescoDocument *)document
                                 contentFile:(AlfrescoContentFile *)file
                             completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                               progressBlock:(AlfrescoProgressBlock)progressBlock;

/** Updates a document with the contents of a local file.
 
 @param document The document that needs to be updated.
 @param contentStream An instance of AlfrescoContent stream to be used for data access.
 @param completionBlock The block that's called with the updated document in case the operation succeeds.
 @param progressBlock The block that's called with the upload progress. This can only be used if the fileSize parameter is > 0.
 */

- (AlfrescoRequest *)updateContentOfDocument:(AlfrescoDocument *)document
                               contentStream:(AlfrescoContentStream *)contentStream
                             completionBlock:(AlfrescoDocumentCompletionBlock)completionBlock
                               progressBlock:(AlfrescoProgressBlock)progressBlock;


/** Updates the properties of a specific node.
 
 @param node The node that needs to be updated.
 @param properties The properties that need to be updated for the given node.
 @param completionBlock The block that's called with the updated node in case the operation succeeds.
 */
- (AlfrescoRequest *)updatePropertiesOfNode:(AlfrescoNode *)node
                                 properties:(NSDictionary *)properties
                            completionBlock:(AlfrescoNodeCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Deletes a node.
 *  ---------------------------------------------------------------------------------------
 */

/** Deletes an individual node from the Alfresco repository.
 
 @param node The node that needs to be deleted.
 @param completionBlock The block that's called in case the operation succeeds.
 */
- (AlfrescoRequest *)deleteNode:(AlfrescoNode *)node
                completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;


/**---------------------------------------------------------------------------------------
 * @name Favorite or Unfavorite Documents, Folders, Nodes
 *  ---------------------------------------------------------------------------------------
 */

/** Retrieves a list of favorite documents for current user .
 
 @param completionBlock The block that's called with the retrieved documents in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveFavoriteDocumentsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


/** Retrieves a list of favorite documents with a listing context for current user.
 
 @param listingContext The listing context with a paging definition that's used to retrieve favorite documents.
 @param completionBlock The block that's called with the retrieved documents in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveFavoriteDocumentsWithListingContext:(AlfrescoListingContext *)listingContext
                                                 completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;


/** Retrieves a list of favorite folders for current user.
 
 @param completionBlock The block that's called with the retrieved folders in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveFavoriteFoldersWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


/** Retrieves a list of favorite folders with a listing context for current user.
 
 @param listingContext The listing context with a paging definition that's used to retrieve favorite folders.
 @param completionBlock The block that's called with the retrieved folders in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveFavoriteFoldersWithListingContext:(AlfrescoListingContext *)listingContext
                                               completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;


/** Retrieves a list of favorite nodes for current user.
 
 @param completionBlock The block that's called with the retrieved nodes in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveFavoriteNodesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


/** Retrieves a list of favorite nodes with a listing context for current user.
 
 @param listingContext The listing context with a paging definition that's used to retrieve favorite nodes.
 @param completionBlock The block that's called with the retrieved nodes in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveFavoriteNodesWithListingContext:(AlfrescoListingContext *)listingContext
                                             completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;


/** Determine whether given node is favorite.
 
 @param node The node for which favorite status is being determined
 @param completionBlock The block that's called with current favorite status of the node.
 */
- (AlfrescoRequest *)isFavorite:(AlfrescoNode *)node
              	completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock;


/** Favorite a node.
 
 @param node The node which is to be favorited
 @param completionBlock The block that's called with current favorite status of the node.
 */
- (AlfrescoRequest *)addFavorite:(AlfrescoNode *)node
                 completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock;


/** UnFavorite a node.
 
 @param node The node which is to be unfavorited
 @param completionBlock The block that's called with current favorite status of the node.
 */
- (AlfrescoRequest *)removeFavorite:(AlfrescoNode *)node
                    completionBlock:(AlfrescoFavoritedCompletionBlock)completionBlock;


/** Retrieve the latest (and complete) metadata for the provided node.
 
 @param The node which is to be refreshed with its latest metadata
 @param completionBlock The block that's called with node's complete metadata.
 */
- (AlfrescoRequest *)refreshNode:(AlfrescoNode *)node
                 completionBlock:(AlfrescoNodeCompletionBlock)completionBlock;

/**
 clears the Favorites cache
 */
- (void)clearFavoritesCache;

@end

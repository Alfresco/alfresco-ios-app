/*
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
 */

#import <Foundation/Foundation.h>
#import "CMISSessionParameters.h"
#import "CMISRepositoryInfo.h"
#import "CMISBinding.h"
#import "CMISFolder.h"

@class CMISOperationContext;
@class CMISPagedResult;
@class CMISTypeDefinition;
@class CMISObjectConverter;

@interface CMISSession : NSObject

// Flag to indicate whether the session has been authenticated.
@property (nonatomic, assign, readonly, getter = isAuthenticated) BOOL authenticated;

// The binding object being used for the session.
@property (nonatomic, strong, readonly) id<CMISBinding> binding;

// The parameters used to create this session.
@property (nonatomic, strong) CMISSessionParameters *sessionParameters;

// Information about the repository the session is connected to, will be nil until the session is authenticated.
@property (nonatomic, strong, readonly) CMISRepositoryInfo *repositoryInfo;

//used for converting properties. This can be set to a custom object converter
@property (nonatomic, strong, readonly) CMISObjectConverter *objectConverter;

// *** setup ***

// returns an array of CMISRepositoryInfo objects representing the repositories available at the endpoint.
/**
 * completionBlock returns a list of repositories or nil if unsuccessful
 */
+ (CMISRequest*)arrayOfRepositories:(CMISSessionParameters *)sessionParameters
            completionBlock:(void (^)(NSArray *repositories, NSError *error))completionBlock;


/**
 * completionBlock returns a CMIS session or nil if unsuccessful
 */
+ (CMISRequest*)connectWithSessionParameters:(CMISSessionParameters *)sessionParameters
                     completionBlock:(void (^)(CMISSession *session, NSError * error))completionBlock;

// *** CMIS operations ***

/**
 * Retrieves the root folder for the repository.
 * completionBlock returns the root folder of the repo or nil if unsuccessful
 */
- (CMISRequest*)retrieveRootFolderWithCompletionBlock:(void (^)(CMISFolder *folder, NSError *error))completionBlock;

/**
 * Retrieves the root folder for the repository using the provided operation context.
 * completionBlock returns a folder of the repo or nil if unsuccessful
 */
- (CMISRequest*)retrieveFolderWithOperationContext:(CMISOperationContext *)operationContext
                           completionBlock:(void (^)(CMISFolder *folder, NSError *error))completionBlock;
 
/**
 * Retrieves the object with the given identifier.
 * completionBlock returns the CMIS object or nil if unsuccessful
 */
- (CMISRequest*)retrieveObject:(NSString *)objectId
       completionBlock:(void (^)(CMISObject *object, NSError *error))completionBlock;

/**
  * Retrieves the object with the given identifier, using the provided operation context.
  * completionBlock returns the CMIS object or nil if unsuccessful
  */
- (CMISRequest*)retrieveObject:(NSString *)objectId
      operationContext:(CMISOperationContext *)operationContext
       completionBlock:(void (^)(CMISObject *object, NSError *error))completionBlock;

/**
 * Retrieves the object for the given path.
 * completionBlock returns the CMIS object or nil if unsuccessful
 */
- (CMISRequest*)retrieveObjectByPath:(NSString *)path
             completionBlock:(void (^)(CMISObject *object, NSError *error))completionBlock;

 
/**
 * Retrieves the object for the given path, using the provided operation context.
 * completionBlock returns the CMIS object or nil if unsuccessful
 */
- (CMISRequest*)retrieveObjectByPath:(NSString *)path
            operationContext:(CMISOperationContext *)operationContext
             completionBlock:(void (^)(CMISObject *object, NSError *error))completionBlock;

/**
 * Retrieves the definition for the given type.
 * completionBlock returns the CMIS type definition or nil if unsuccessful
 */
- (CMISRequest*)retrieveTypeDefinition:(NSString *)typeId 
               completionBlock:(void (^)(CMISTypeDefinition *typeDefinition, NSError *error))completionBlock;
/**
 * Retrieves all objects matching the given cmis query.
 * completionBlock returns the search results as a paged results object or nil if unsuccessful.
 */
- (CMISRequest*)query:(NSString *)statement searchAllVersions:(BOOL)searchAllVersion
                                      completionBlock:(void (^)(CMISPagedResult *pagedResult, NSError *error))completionBlock;

/**
 * Retrieves all objects matching the given cmis query, as CMISQueryResult objects.
 * and using the parameters provided in the operation context.
 * completionBlock returns the search results as a paged results object or nil if unsuccessful.
 */
- (CMISRequest*)query:(NSString *)statement searchAllVersions:(BOOL)searchAllVersion
                                     operationContext:(CMISOperationContext *)operationContext
                                      completionBlock:(void (^)(CMISPagedResult *pagedResult, NSError *error))completionBlock;

/**
 * Queries for a specific type of objects.
 * Returns a paged result set, containing CMISObject instances.
 * completionBlock returns the search results as a paged results object or nil if unsuccessful.
 */
- (CMISRequest*)queryObjectsWithTypeid:(NSString *)typeId
                   whereClause:(NSString *)whereClause
             searchAllVersions:(BOOL)searchAllVersion
              operationContext:(CMISOperationContext *)operationContext
               completionBlock:(void (^)(CMISPagedResult *result, NSError *error))completionBlock;


/**
 * Creates a folder in the provided folder.
 * completionBlock returns the object Id of the newly created folder or nil if unsuccessful
 */
- (CMISRequest*)createFolder:(NSDictionary *)properties
            inFolder:(NSString *)folderObjectId
     completionBlock:(void (^)(NSString *objectId, NSError *error))completionBlock;


/**
 * Downloads the content of object with the provided object id to the given path.
 * completionBlock NSError will be nil if successful
 */
- (CMISRequest*)downloadContentOfCMISObject:(NSString *)objectId
                                     toFile:(NSString *)filePath
                            completionBlock:(void (^)(NSError *error))completionBlock
                              progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;

/**
 * Downloads the content of object with the provided object id to the given stream.
 * completionBlock NSError will be nil if successful
 */
- (CMISRequest*)downloadContentOfCMISObject:(NSString *)objectId
                             toOutputStream:(NSOutputStream*)outputStream
                            completionBlock:(void (^)(NSError *error))completionBlock
                              progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;

/**
 * Creates a cmis document using the content from the file path.
 * completionBlock returns object Id of newly created object or nil if unsuccessful
 */
- (CMISRequest*)createDocumentFromFilePath:(NSString *)filePath
                          mimeType:(NSString *)mimeType
                        properties:(NSDictionary *)properties
                          inFolder:(NSString *)folderObjectId
                   completionBlock:(void (^)(NSString *objectId, NSError *error))completionBlock
                     progressBlock:(void (^)(unsigned long long bytesUploaded, unsigned long long bytesTotal))progressBlock;

/**
 * Creates a cmis document using the content from the given stream.
 * completionBlock returns object Id of newly created object or nil if unsuccessful
 */
- (CMISRequest*)createDocumentFromInputStream:(NSInputStream *)inputStream
                             mimeType:(NSString *)mimeType
                           properties:(NSDictionary *)properties
                             inFolder:(NSString *)folderObjectId
                        bytesExpected:(unsigned long long)bytesExpected
                      completionBlock:(void (^)(NSString *objectId, NSError *error))completionBlock
                        progressBlock:(void (^)(unsigned long long bytesUploaded, unsigned long long bytesTotal))progressBlock;
@end

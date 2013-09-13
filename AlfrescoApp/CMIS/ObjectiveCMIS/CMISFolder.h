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
#import "CMISFileableObject.h"
#import "CMISCollection.h"

@class CMISDocument;
@class CMISPagedResult;
@class CMISOperationContext;

@interface CMISFolder : CMISFileableObject

@property (nonatomic, strong, readonly) NSString *path;

/**
 * Retrieves the children of this folder as a paged result.
 *
 * The completionBlock will return paged results with instances of CMISObject or nil if unsuccessful.
 */
- (CMISRequest*)retrieveChildrenWithCompletionBlock:(void (^)(CMISPagedResult *result, NSError *error))completionBlock;

/**
 * Checks if this folder is the root folder.
 */
- (BOOL)isRootFolder;

/**
 * Gets the parent folder object.
 * The completionBlock will return CMISFolder object or nil if unsuccessful.
 */
- (CMISRequest*)retrieveFolderParentWithCompletionBlock:(void (^)(CMISFolder *folder, NSError *error))completionBlock;

/**
 * Retrieves the children of this folder as a paged result using the provided operation context.
 *
 * The completionBlock will return paged results with instances of CMISObject or nil if unsuccessful.
 */
- (CMISRequest*)retrieveChildrenWithOperationContext:(CMISOperationContext *)operationContext completionBlock:(void (^)(CMISPagedResult *result, NSError *error))completionBlock;

/**
 * creates a folder with specified properties
 * completionBlock returns object Id of newly created folder or nil if not successful
 */
- (CMISRequest*)createFolder:(NSDictionary *)properties completionBlock:(void (^)(NSString *objectId, NSError *error))completionBlock;

/**
 * creates a document with specified properties, mime Type
 * completionBlock returns object Id of newly created document or nil if not successful
 */
- (CMISRequest*)createDocumentFromFilePath:(NSString *)filePath
                          mimeType:(NSString *)mimeType
                        properties:(NSDictionary *)properties
                   completionBlock:(void (^)(NSString *objectId, NSError *error))completionBlock
                     progressBlock:(void (^)(unsigned long long bytesUploaded, unsigned long long bytesTotal))progressBlock;

/**
 * creates a document with specified properties, mime Type
 * completionBlock returns object Id of newly created document or nil if not successful
 */
- (CMISRequest*)createDocumentFromInputStream:(NSInputStream *)inputStream
                             mimeType:(NSString *)mimeType
                           properties:(NSDictionary *)properties
                        bytesExpected:(unsigned long long)bytesExpected
                      completionBlock:(void (^)(NSString *objectId, NSError *error))completionBlock
                        progressBlock:(void (^)(unsigned long long bytesUploaded, unsigned long long bytesTotal))progressBlock;


/**
 * creates a document with specified properties, mime Type
 * completionBlock returns list of failed objects (if any) 
 */
- (CMISRequest*)deleteTreeWithDeleteAllVersions:(BOOL)deleteAllversions
                          unfileObjects:(CMISUnfileObject)unfileObjects
                      continueOnFailure:(BOOL)continueOnFailure
                        completionBlock:(void (^)(NSArray *failedObjects, NSError *error))completionBlock;


@end



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

#import "CMISFileableObject.h"

@class CMISOperationContext;
@class CMISRequest;

@interface CMISDocument : CMISFileableObject <NSURLConnectionDataDelegate>

@property (nonatomic, strong, readonly) NSString *contentStreamId;
@property (nonatomic, strong, readonly) NSString *contentStreamFileName;
@property (nonatomic, strong, readonly) NSString *contentStreamMediaType;
@property (readonly) unsigned long long contentStreamLength;

@property (nonatomic, strong, readonly) NSString *versionLabel;
@property (nonatomic, assign, readonly, getter = isLatestVersion) BOOL latestVersion;
@property (nonatomic, assign, readonly, getter = isMajorVersion) BOOL majorVersion;
@property (nonatomic, assign, readonly, getter = isLatestMajorVersion) BOOL latestMajorVersion;
@property (nonatomic, strong, readonly) NSString *versionSeriesId;

/**
 * Retrieves a collection of all versions of this document. 
 * The completionBlock returns collection of all documents or nil if unsuccessful
 */
- (CMISRequest*)retrieveAllVersionsWithCompletionBlock:(void (^)(CMISCollection *allVersionsOfDocument, NSError *error))completionBlock;

/**
 * Retrieves a collection of all versions of this document with paging options.
 * The completionBlock returns collection of all documents or nil if unsuccessful
 */
- (CMISRequest*)retrieveAllVersionsWithOperationContext:(CMISOperationContext *)operationContext completionBlock:(void (^)(CMISCollection *collection, NSError *error))completionBlock;

/**
 * Retrieves the lastest version of this document.
 * The completionBlock returns the CMIS document or nil if unsuccessful
 */
- (CMISRequest*)retrieveObjectOfLatestVersionWithMajorVersion:(BOOL)major completionBlock:(void (^)(CMISDocument *document, NSError *error))completionBlock;

/**
 * Retrieves the lastest version of this document with paging options.
 * The completionBlock returns the CMIS document or nil if unsuccessful
 */
- (CMISRequest*)retrieveObjectOfLatestVersionWithMajorVersion:(BOOL)major
                                     operationContext:(CMISOperationContext *)operationContext
                                      completionBlock:(void (^)(CMISDocument *document, NSError *error))completionBlock;

/**
 * Downloads the content to a local file and returns the filepath.
 * completionBlock will return NSError nil if successful
 */
- (CMISRequest*)downloadContentToFile:(NSString *)filePath
                      completionBlock:(void (^)(NSError *error))completionBlock
                        progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;


/**
 * Downloads the content to an outputstream and returns the handle to the http request in order to allow cancellation.
 * completionBlock will return NSError nil if successful
 */
- (CMISRequest*)downloadContentToOutputStream:(NSOutputStream *)outputStream
                              completionBlock:(void (^)(NSError *error))completionBlock
                                progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;

/**
 * Changes the content of this document to the content of the given file.
 *
 * Optional overwrite flag: If TRUE (default), then the Repository MUST replace the existing content stream for the
 * object (if any) with the input contentStream. If FALSE, then the Repository MUST only set the input
 * contentStream for the object if the object currently does not have a content-stream.
 * completionBlock will return NSError nil if successful
 */
- (CMISRequest*)changeContentToContentOfFile:(NSString *)filePath
                                    mimeType:(NSString *)mimeType
                                   overwrite:(BOOL)overwrite
                             completionBlock:(void (^)(NSError *error))completionBlock
                               progressBlock:(void (^)(unsigned long long bytesUploaded, unsigned long long bytesTotal))progressBlock;

/**
 * Changes the content of this document to the content of the given input stream.
 *
 * Optional overwrite flag: If TRUE (default), then the Repository MUST replace the existing content stream for the
 * object (if any) with the input contentStream. If FALSE, then the Repository MUST only set the input
 * contentStream for the object if the object currently does not have a content-stream.
 * completionBlock will return NSError nil if successful
 */
- (CMISRequest*)changeContentToContentOfInputStream:(NSInputStream *)inputStream
                                      bytesExpected:(unsigned long long)bytesExpected
                                           fileName:(NSString *)fileName
                                           mimeType:(NSString *)mimeType
                                          overwrite:(BOOL)overwrite
                                    completionBlock:(void (^)(NSError *error))completionBlock
                                      progressBlock:(void (^)(unsigned long long bytesUploaded, unsigned long long bytesTotal))progressBlock;

/**
 * Deletes the content of this document.
 * completionBlock will return NSError nil if successful
 */
- (CMISRequest*)deleteContentWithCompletionBlock:(void (^)(NSError *error))completionBlock;

/**
 * Deletes the document from the document store.
 * completionBlock return true if successful
 */
- (CMISRequest*)deleteAllVersionsWithCompletionBlock:(void (^)(BOOL documentDeleted, NSError *error))completionBlock;

@end

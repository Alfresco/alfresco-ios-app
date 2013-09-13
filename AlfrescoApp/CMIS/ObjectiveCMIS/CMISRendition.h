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
#import "CMISRenditionData.h"

@class CMISDocument;
@class CMISOperationContext;
@class CMISSession;
@class CMISRequest;

@interface CMISRendition : CMISRenditionData

/**
 initialiser
 */
- (id)initWithRenditionData:(CMISRenditionData *)renditionData objectId:(NSString *)objectId session:(CMISSession *)session;

/**
 * retrieves the rendition, e.g. thumbnail of a document
 * completionBlock returns the rendition object as CMIS document or nil if unsuccessful
 */
- (CMISRequest*)retrieveRenditionDocumentWithCompletionBlock:(void (^)(CMISDocument *document, NSError *error))completionBlock;

/**
 * retrieves the rendition, e.g. thumbnail of a document
 * completionBlock returns the rendition object as CMIS document or nil if unsuccessful
 */
- (CMISRequest*)retrieveRenditionDocumentWithOperationContext:(CMISOperationContext *)operationContext
                                      completionBlock:(void (^)(CMISDocument *document, NSError *error))completionBlock;

/**
 * downloads the rendition of a document e.g. thumbnail of a document to a file
 * completionBlock returns the rendition object as CMIS document or nil if unsuccessful
 */
- (CMISRequest*)downloadRenditionContentToFile:(NSString *)filePath
                       completionBlock:(void (^)(NSError *error))completionBlock
                         progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;

/**
 * downloads the rendition of a document e.g. thumbnail of a document to a file
 * completionBlock returns the rendition object as CMIS document or nil if unsuccessful
 */
- (CMISRequest*)downloadRenditionContentToOutputStream:(NSOutputStream *)outputStream
                               completionBlock:(void (^)(NSError *error))completionBlock
                                 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;

@end
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


@interface CMISRenditionData : NSObject

/**  Identifies the rendition stream. */
@property (nonatomic, strong) NSString *streamId;

/** The MIME type of the rendition stream. */
@property (nonatomic, strong) NSString *mimeType;

/** Human readable information about the rendition (optional). */
@property (nonatomic, strong) NSString *title;

/** A categorization String associated with the rendition (optional). */
@property (nonatomic, strong) NSString *kind;

/** The length of the rendition stream in bytes (optional). */
@property (nonatomic, strong) NSNumber *length;

/** Typically used for 'image' renditions (expressed as pixels). SHOULD be present if kind = cmis:thumbnail (optional). */
@property (nonatomic, strong) NSNumber *height;

/** Typically used for 'image' renditions (expressed as pixels). SHOULD be present if kind = cmis:thumbnail. */
@property (nonatomic, strong) NSNumber *width;

/**
 *  If specified, then the rendition can also be accessed as a document object in the CMIS services.
 *  If not set, then the rendition can only be accessed via the rendition services. Referential integrity of this ID is repository-specific.
 *
 * TODO: needs to be changed to more generic 'ObjectId'
 */
@property (nonatomic, strong) NSString *renditionDocumentId;

- (id)initWithRenditionData:(CMISRenditionData *)renditionData;

@end
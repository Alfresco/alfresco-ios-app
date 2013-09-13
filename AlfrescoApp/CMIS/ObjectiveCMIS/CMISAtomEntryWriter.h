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

@class CMISProperties;


@interface CMISAtomEntryWriter : NSObject

@property (nonatomic, strong) NSString *contentFilePath;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) CMISProperties *cmisProperties;

/**
 * If YES: the xml will be created and stored fully in-memory.
 * If NO: the xml will be streamed to a file on disk.
 *
 * Defaults to YES;
 */
@property BOOL generateXmlInMemory;

/**
* Generates the atom entry XML for the given properties on this class.
*
* NOTE: if <code>generateXmlInMemory</code> boolean is set to NO, a filepath pointing to a file
* containing the generated atom entry is returned.
* Callers are responsible to remove the file again if not needed anymore.
*
* If set to YES, the return value of this method is the XML is its whole.
*
*/
- (NSString *)generateAtomEntryXml;

- (NSString *)xmlStartElement;

- (NSString *)xmlContentStartElement;

- (NSString *)xmlContentEndElement;

- (NSString *)xmlPropertiesElements;

@end
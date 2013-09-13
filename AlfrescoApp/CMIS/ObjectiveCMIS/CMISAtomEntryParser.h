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
#import "CMISConstants.h"
#import "CMISAtomPubConstants.h"
#import "CMISObjectData.h"
#import "CMISPropertyData.h"
#import "CMISProperties.h"
#import "CMISAllowableActionsParser.h"
#import "CMISAtomPubExtensionElementParser.h"
#import "CMISAtomPubExtensionDataParserBase.h"

@protocol CMISAtomEntryParserDelegate;

@interface CMISAtomEntryParser : CMISAtomPubExtensionDataParserBase <NSXMLParserDelegate, CMISAllowableActionsParserDelegate>

@property (nonatomic, strong, readonly) CMISObjectData *objectData;

/// Designated Initializer
- (id)initWithData:(NSData *)atomData;
/// parse method. returns NO if unsuccessful
- (BOOL)parseAndReturnError:(NSError **)error;

/// Initializes a child parser for an Atom Entry and takes over parsing control while parsing the Atom Entry
+ (id)atomEntryParserWithAtomEntryAttributes:(NSDictionary *)attributes parentDelegate:(id<NSXMLParserDelegate, CMISAtomEntryParserDelegate>)parentDelegate parser:(NSXMLParser *)parser;

@end


@protocol CMISAtomEntryParserDelegate <NSObject>
@optional
- (void)cmisAtomEntryParser:(id)entryParser didFinishParsingCMISObjectData:(CMISObjectData *)cmisObjectData;

@end

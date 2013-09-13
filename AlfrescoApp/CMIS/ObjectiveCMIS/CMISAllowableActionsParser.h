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
#import "CMISAllowableActions.h"
#import "CMISAtomPubExtensionDataParserBase.h"

@class CMISAllowableActionsParser;

@protocol CMISAllowableActionsParserDelegate <NSObject>
@optional
- (void)allowableActionsParser:(CMISAllowableActionsParser *)parser didFinishParsingAllowableActions:(CMISAllowableActions *)allowableActions;

@end


@interface CMISAllowableActionsParser : CMISAtomPubExtensionDataParserBase <NSXMLParserDelegate>

@property (nonatomic, strong) CMISAllowableActions *allowableActions;
/// Designated Initializer
- (id)initWithData:(NSData*)atomData;

/**
 parse method. returns NO if unsuccessful
 */
- (BOOL)parseAndReturnError:(NSError **)error;

/// Delegates parsing to child parser, ensure that the Element is 'allowableActions'
+ (id)allowableActionsParserWithParentDelegate:(id<NSXMLParserDelegate, CMISAllowableActionsParserDelegate>)parentDelegate parser:(NSXMLParser *)parser;

@end

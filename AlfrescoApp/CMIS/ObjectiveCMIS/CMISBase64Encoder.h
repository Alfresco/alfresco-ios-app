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

@interface CMISBase64Encoder : NSObject

/// encodes data into base 64 and returns the result as NSString
+ (NSString *)stringByEncodingText:(NSData *)plainText;

/// returns base64 encoded data for given input data
+ (NSData *)dataByEncodingText:(NSData *)plainText;

/// base64 encodes the content of a file
+ (NSString *)encodeContentOfFile:(NSString *)sourceFilePath;

/// base64 encodes data from an input stream
+ (NSString *)encodeContentFromInputStream:(NSInputStream*)inputStream;

/// base64 encodes data from a source file and appends the encoded result to the given destination file
+ (void)encodeContentOfFile:(NSString *)sourceFilePath appendToFile:(NSString *)destinationFilePath;

/// base64 encodes data from an input stream and appends the encoded data to a given destination file
+ (void)encodeContentFromInputStream:(NSInputStream*)inputStream appendToFile:(NSString *)destinationFilePath;

@end

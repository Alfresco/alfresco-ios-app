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
#import <Foundation/FoundationErrors.h>
#import <Foundation/NSURLError.h>



/** error codes defined in CMIS
 */
typedef enum
{
    //error range for basic errors - not covered in the spec but
    // present in the OpenCMIS Java lib
    kCMISErrorCodeBasicMinimum = 0,
    kCMISErrorCodeBasicMaximum = 255,

    //basic CMIS errors
    kCMISErrorCodeNoReturn = 0,
    kCMISErrorCodeConnection = 1,
    kCMISErrorCodeProxyAuthentication = 2,
    kCMISErrorCodeUnauthorized = 3,
    kCMISErrorCodeNoRootFolderFound = 4,
    kCMISErrorCodeNoRepositoryFound = 5,
    kCMISErrorCodeCancelled = 6,
    
    //error ranges for General errors
    kCMISErrorCodeGeneralMinimum = 256,
    kCMISErrorCodeGeneralMaximum = 511,
    
    //General errors/exceptions as defined in 2.2.1.4.1
    kCMISErrorCodeInvalidArgument = 256,
    kCMISErrorCodeObjectNotFound = 257,
    kCMISErrorCodeNotSupported = 258,
    kCMISErrorCodePermissionDenied = 259,
    kCMISErrorCodeRuntime = 260,
    
    
    //error ranges for CMIS specific errors
    kCMISErrorCodeSpecificMinimum = 512,
    kCMISErrorCodeSpecificMaximum = 1023,
    
    //Specific errors/exceptions as defined in 2.2.1.4.2
    kCMISErrorCodeConstraint = 512,
    kCMISErrorCodeContentAlreadyExists = 513,
    kCMISErrorCodeFilterNotValid = 514,
    kCMISErrorCodeNameConstraintViolation = 515,
    kCMISErrorCodeStorage = 516,
    kCMISErrorCodeStreamNotSupported = 517,
    kCMISErrorCodeUpdateConflict = 518,
    kCMISErrorCodeVersioning = 519
    
}CMISErrorCodes;


extern NSString * const kCMISErrorDomainName;
//to be used in the userInfo dictionary as Localized error description
//Basic Errors
extern NSString * const kCMISErrorDescriptionNoReturn;
extern NSString * const kCMISErrorDescriptionConnection;
extern NSString * const kCMISErrorDescriptionProxyAuthentication;
extern NSString * const kCMISErrorDescriptionUnauthorized;
extern NSString * const kCMISErrorDescriptionNoRootFolderFound;
extern NSString * const kCMISErrorDescriptionRepositoryNotFound;
//General errors as defined in 2.2.1.4.1 of spec
extern NSString * const kCMISErrorDescriptionInvalidArgument;
extern NSString * const kCMISErrorDescriptionObjectNotFound;
extern NSString * const kCMISErrorDescriptionNotSupported;
extern NSString * const kCMISErrorDescriptionPermissionDenied;
extern NSString * const kCMISErrorDescriptionRuntime;
//Specific errors as defined in 2.2.1.4.2
extern NSString * const kCMISErrorDescriptionConstraint;
extern NSString * const kCMISErrorDescriptionContentAlreadyExists;
extern NSString * const kCMISErrorDescriptionFilterNotValid;
extern NSString * const kCMISErrorDescriptionNameConstraintViolation;
extern NSString * const kCMISErrorDescriptionStorage;
extern NSString * const kCMISErrorDescriptionStreamNotSupported;
extern NSString * const kCMISErrorDescriptionUpdateConflict;
extern NSString * const kCMISErrorDescriptionVersioning;

/** This class defines Errors in the Objective-C CMIS library
 
 All CMIS errors are based on NSError class.
 CMIS errors are created either 
 
 - directly. This is the case when an error is captured by one of the methods/classes in the CMIS library
 - indirectly. Errors have been created by classes/methods outside the CMIS library. Example errors created through NSURLConnection. In this case, the underlying error is copied into the CMIS error using the NSUnderlyingErrorKey in the userInfo Dictionary.
 
 */
@interface CMISErrors : NSObject
/** Create a CMIS error based on an underlying error
 
 This is the indirect way of creating CMIS errors
 
 @param error The underlying NSError object
 @param code the CMIS error code
 @return the CMIS error as NSError object with error domain org.apache.chemistry.objectivecmis
 */
+ (NSError *)cmisError:(NSError *)error cmisErrorCode:(CMISErrorCodes)code;
/** Creates a new CMIS error
 
 This is the direct way of creating CMIS errors
 
 @param code the CMIS Error code to be used
 @param detailedDescription a detailed description to be added to the localizedDescription. Use nil if none is available/needed.
 @return the CMIS error as NSError object with error domain org.apache.chemistry.objectivecmis
 */
+ (NSError *)createCMISErrorWithCode:(CMISErrorCodes)code detailedDescription:(NSString *)detailedDescription;
@end


/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile SDK.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/

#import <XCTest/XCTest.h>
#import <AlfrescoSDK-iOS/AlfrescoSDK.h>

@class CMISSession;
@class CMISFolder;

#define TIMEINTERVAL 120
#define TIMEGAP 5
typedef void (^AlfrescoTestBlock)(void);
typedef void (^CMISTestBlock)(void);
typedef void (^AlfrescoSessionTestBlock)(id<AlfrescoSession> session);

@interface AlfrescoBaseTest : XCTestCase

@property (nonatomic, assign) BOOL callbackCompleted;
@property (nonatomic, assign) BOOL lastTestSuccessful;
@property (nonatomic, strong) NSString *lastTestFailureMessage;
@property (nonatomic, strong) AlfrescoDocument *testAlfrescoDocument;
@property (nonatomic, strong) AlfrescoDocumentFolderService *alfrescoDocumentFolderService;
@property (nonatomic, strong) AlfrescoFolder *currentRootFolder;
@property (nonatomic, strong) AlfrescoFolder *testDocFolder;
@property (nonatomic, strong) AlfrescoFolder *testChildFolder;
@property (nonatomic, strong) NSString *unitTestFolder;
@property (nonatomic, strong) id<AlfrescoSession> currentSession;
// Test environment parameters
@property (nonatomic, strong) NSString *testSearchFileName;
@property (nonatomic, strong) NSString *testSearchFileKeywords;
@property (nonatomic, strong) NSString *textKeyWord;
@property (nonatomic, strong) NSString *testModeratedSiteName;
@property (nonatomic, strong) NSString *server;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *secondUsername;
@property (nonatomic, strong) NSString *secondPassword;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *testSiteName;
@property (nonatomic, strong) NSString *moderatedSiteName;
@property (nonatomic, strong) NSString *testFolderPathName;
@property (nonatomic, strong) NSString *fixedFileName;
@property (nonatomic, strong) NSString *verySmallTestFile;
@property (nonatomic, strong) NSString *testImageName;
@property (nonatomic, strong) NSString *exifDateTimeOriginalUTC;
@property (nonatomic, strong) AlfrescoContentFile *testImageFile;
@property (nonatomic, strong) CMISSession *cmisSession;
@property (nonatomic, strong) CMISFolder *cmisRootFolder;
@property (nonatomic, assign) BOOL isCloud;
@property (nonatomic, assign) BOOL setUpSuccess;

+ (NSString *)addTimeStampToFileOrFolderName:(NSString *)filename;
- (BOOL)authenticateOnPremiseServer:(NSMutableDictionary *)parameters;
- (BOOL)authenticateCloudServer;

- (BOOL)retrieveAlfrescoTestFolder;
- (void)waitUntilCompleteWithFixedTimeInterval;
- (BOOL)removeTestDocument;
- (BOOL)uploadTestDocument:(NSString *)filePath;
- (NSDictionary *)setupEnvironmentParameters;
- (void)setUpTestImageFile:(NSString *)filePath;
- (void)resetTestVariables;
- (NSString *)userTestConfigFolder;
- (NSString *)failureMessageFromError:(NSError *)error;

@end

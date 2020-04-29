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

#import "AlfrescoBaseTest.h"
#import "AlfrescoSDKInternalConstants.h"

// kAlfrescoTestServersConfigDirectory is expected to be found in the user's home folder.
// Note: the entry in userhome can be a symbolic link created via "ln -s"
static NSString * const kAlfrescoTestServersConfigDirectory = @"ios-sdk-test-config";
static NSString * const kAlfrescoTestServersPlist = @"test-servers.plist";


@implementation AlfrescoBaseTest

#pragma mark unit test internal methods

- (NSString *)userTestConfigFolder
{
    NSString *userName = [[NSString alloc] initWithCString:getlogin() encoding:NSUTF8StringEncoding];
    return [NSString pathWithComponents:@[@"/Users", userName, kAlfrescoTestServersConfigDirectory]];
}

- (NSDictionary *)setupEnvironmentParameters
{
    NSString *plistFilePath = [self.userTestConfigFolder stringByAppendingPathComponent:kAlfrescoTestServersPlist];
    NSDictionary *plistContents =  [NSDictionary dictionaryWithContentsOfFile:plistFilePath];
    NSDictionary *allEnvironments = [plistContents objectForKey:@"environments"];
    NSDictionary *environment = nil;
    if (nil != allEnvironments)
    {
        // Expecting a "TEST_SERVER" environment variable
        NSDictionary *environmentVariables = [[NSProcessInfo processInfo] environment];
        NSString *serverID = [environmentVariables valueForKey:@"TEST_SERVER"];
        if (nil != serverID)
        {
            environment = (NSDictionary *)[allEnvironments objectForKey:serverID];
        }
    }

    if (nil == environment)
    {
        self.server = @"http://localhost:8080/alfresco";
        self.isCloud = NO;
        self.userName = @"admin";
        self.password = @"admin";
        self.firstName = @"Administrator";
        self.testSiteName = @"ios-sdk-test";
        self.testSearchFileName = @"ios-search-test.txt";
        self.testSearchFileKeywords = @"ios-search-test";
        self.textKeyWord = @"lorem";
        self.unitTestFolder = @"Unit Test Subfolder";
        self.fixedFileName = @"versioned-quote.txt";
        self.testFolderPathName = @"/ios-sdk-test";
        self.exifDateTimeOriginalUTC = @"2001-04-06T11:51:40.000Z";
    }
    else
    {
        self.server = [environment valueForKey:@"server"];
        if ([[environment allKeys] containsObject:@"isCloud"])
        {
            self.isCloud = [[environment valueForKey:@"isCloud"] boolValue];
        }
        else
        {
            self.isCloud = NO;
        }
        self.userName = [environment valueForKey:@"username"];
        self.firstName = [environment valueForKey:@"firstName"];
        self.testSiteName = [environment valueForKey:@"testSite"];
        self.password = [environment valueForKey:@"password"];
        self.testSearchFileName = [environment valueForKey:@"testSearchFile"];
        self.testSearchFileKeywords = [environment valueForKey:@"testSearchFileKeywords"];
        self.textKeyWord = [environment valueForKey:@"textKeyWord"];
        self.unitTestFolder = [environment valueForKey:@"testAddedFolder"];
        self.fixedFileName = [environment valueForKey:@"fixedFileName"];
        self.testFolderPathName = [environment valueForKey:@"docFolder"];
        self.secondUsername = [environment valueForKey:@"secondUsername"];
        self.secondPassword = [environment valueForKey:@"secondPassword"];
        self.moderatedSiteName = [environment valueForKey:@"moderatedSite"];
        self.exifDateTimeOriginalUTC = [environment valueForKey:@"exifDateTimeOriginalUTC"];
    }

    [self resetTestVariables];
    
    return environment;
}

- (void)setUp
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    self.verySmallTestFile = [bundle pathForResource:@"small_test.txt" ofType:nil];
    NSString *testFilePath = [bundle pathForResource:@"test_file.txt" ofType:nil];
    NSString *testImagePath = [bundle pathForResource:@"millenium-dome.jpg" ofType:nil];
    self.testImageName = [testImagePath lastPathComponent];
    [self setupEnvironmentParameters];
    BOOL success = NO;
    if (self.isCloud)
    {
        success = [self authenticateCloudServer];
    }
    else
    {
        success = [self authenticateOnPremiseServer:nil];
    }
    [self resetTestVariables];

    if (success)
    {
        success = [self retrieveAlfrescoTestFolder];
        [self resetTestVariables];
        if (success)
        {
            success = [self uploadTestDocument:testFilePath];
            [self resetTestVariables];
            
            [self setUpTestImageFile:testImagePath];
        }
    }
    self.setUpSuccess = success;
}

- (void)tearDown
{
    [self resetTestVariables];
    if (nil == self.testAlfrescoDocument || nil == self.currentSession)
    {
        self.lastTestSuccessful = YES;
    }
    else
    {
        AlfrescoDocumentFolderService *docFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.currentSession];
        [docFolderService deleteNode:self.testAlfrescoDocument completionBlock:^(BOOL succeeded, NSError *error){
            if (!succeeded)
            {
                self.testAlfrescoDocument = nil;
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [NSString stringWithFormat:@"Could not delete test document. Error message %@ and code %@", error.localizedDescription, @(error.code)];
                self.callbackCompleted = YES;
            }
            else
            {
                self.lastTestSuccessful = YES;
                self.testAlfrescoDocument = nil;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
    }
    XCTAssertTrue(self.lastTestSuccessful, @"removeTestDocument failed");
}

+ (NSString *)addTimeStampToFileOrFolderName:(NSString *)filename
{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH-mm-ss-SSS'"];
    
    NSString *pathExt = [filename pathExtension];
    NSString *strippedString = [filename stringByDeletingPathExtension];
    
    if (pathExt.length > 0)
    {
        return [NSString stringWithFormat:@"%@%@.%@", strippedString, [formatter stringFromDate:currentDate], pathExt];
    }
    
    return [NSString stringWithFormat:@"%@%@", strippedString, [formatter stringFromDate:currentDate]];
}


/*
 @Unique_TCRef 33S1
 */
- (BOOL)uploadTestDocument:(NSString *)filePath
{
    NSURL *fileUrl = [NSURL URLWithString:filePath];

    NSString *newName = [AlfrescoBaseTest addTimeStampToFileOrFolderName:[fileUrl lastPathComponent]];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    AlfrescoContentFile *textContentFile = [[AlfrescoContentFile alloc] initWithData:fileData mimeType:@"text/plain"];
    NSMutableDictionary *props = [NSMutableDictionary dictionaryWithCapacity:4];
    [props setObject:[kCMISPropertyObjectTypeIdValueDocument stringByAppendingString:@",P:cm:titled,P:cm:author"] forKey:kCMISPropertyObjectTypeId];
    [props setObject:@"test file description" forKey:@"cm:description"];
    [props setObject:@"test file title" forKey:@"cm:title"];
    [props setObject:@"test author" forKey:@"cm:author"];

    __block BOOL success = NO;
    AlfrescoDocumentFolderService *docFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.currentSession];
    [docFolderService createDocumentWithName:newName inParentFolder:self.testDocFolder contentFile:textContentFile properties:props completionBlock:^(AlfrescoDocument *document, NSError *error) {
        if (nil == document)
        {
            self.lastTestSuccessful = NO;
            self.lastTestFailureMessage = [NSString stringWithFormat:@"Could not upload test document. Error %@",[error localizedDescription]];
            self.callbackCompleted = YES;
        }
        else
        {
            XCTAssertNotNil(document, @"document should not be nil");
            XCTAssertTrue([document.type isEqualToString:@"cm:content"], @"The test document should be of type cm:content but it is %@", document.type);
            self.lastTestSuccessful = YES;
            self.testAlfrescoDocument = document;
            self.callbackCompleted = YES;
            success = YES;
        }
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        // No-op
    }];
    
    [self waitUntilCompleteWithFixedTimeInterval];
    XCTAssertTrue(self.lastTestSuccessful, @"uploadTestDocument failed");
    return success;
}




/*
 @Unique_TCRef 24S1
 */
- (BOOL)removeTestDocument
{
    __block BOOL success = NO;
    if (nil == self.testAlfrescoDocument)
    {
        self.lastTestSuccessful = YES;
        success = YES;
    }
    else
    {
        AlfrescoDocumentFolderService *docFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.currentSession];
        [docFolderService deleteNode:self.testAlfrescoDocument completionBlock:^(BOOL succeeded, NSError *error){
            if (!succeeded)
            {
                self.testAlfrescoDocument = nil;
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [NSString stringWithFormat:@"Could not delete test document. Error message %@ and code %@", error.localizedDescription, @(error.code)];
                self.callbackCompleted = YES;
            }
            else
            {
                self.lastTestSuccessful = YES;
                self.testAlfrescoDocument = nil;
                self.callbackCompleted = YES;
                success = YES;
            }
        }];
    }
    [self waitUntilCompleteWithFixedTimeInterval];
    XCTAssertTrue(self.lastTestSuccessful, @"removeTestDocument failed");
    return success;
}



/*
 @Unique_TCRef 77S1
 */
- (BOOL)authenticateOnPremiseServer:(NSMutableDictionary *)parameters
{
    __block BOOL success = NO;
    if (self.currentSession)
    {
        self.currentSession = nil;
    }
    
    /**
     * FIXME: Running unit tests from the command line doesn't unlock the keychain which in turn
     *        doesn't allow SSL connections to be made. Apple Bug rdar://10406441 and rdar://8385355
     *        (latter can be viewed at http://openradar.appspot.com/8385355 )
     */
    if (nil == parameters)
    {
        parameters = [NSMutableDictionary dictionary];
    }
    [parameters setValue:[NSNumber numberWithBool:YES] forKey:kAlfrescoAllowUntrustedSSLCertificate];
    
    [AlfrescoRepositorySession connectWithUrl:[NSURL URLWithString:self.server]
                                     username:self.userName
                                     password:self.password
                                     parameters:parameters
                              completionBlock:^(id<AlfrescoSession> session, NSError *error){
                                  if (nil == session)
                                  {
                                      self.lastTestSuccessful = NO;
                                      self.lastTestFailureMessage = [NSString stringWithFormat:@"Session could not be authenticated. Error %@",[error localizedDescription]];
                                      self.callbackCompleted = YES;
                                  }
                                  else
                                  {
                                      XCTAssertNotNil(session,@"Session should not be nil");
                                      self.lastTestSuccessful = YES;
                                      self.currentSession = session;
                                      self.callbackCompleted = YES;
                                      self.currentRootFolder = self.currentSession.rootFolder;
                                      success = YES;
                                  }
    }];
    
    
    [self waitUntilCompleteWithFixedTimeInterval];
    XCTAssertTrue(self.lastTestSuccessful, @"OnPremise Session authentication failed");
    return success;
}


/*
 @Unique_TCRef 59S1
 */
- (BOOL)authenticateCloudServer
{
    __block BOOL success = NO;
    if (self.currentSession)
    {
        self.currentSession = nil;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setValue:self.server forKey:@"org.alfresco.mobile.internal.session.cloud.url"];
    [parameters setValue:[NSNumber numberWithBool:YES] forKey:@"org.alfresco.mobile.internal.session.cloud.basic"];
    [parameters setValue:self.userName forKey:@"org.alfresco.mobile.internal.session.username"];
    [parameters setValue:self.password forKey:@"org.alfresco.mobile.internal.session.password"];
    
    /**
     * FIXME: Running unit tests from the command line doesn't unlock the keychain which in turn
     *        doesn't allow SSL connections to be made. Apple Bug rdar://10406441 and rdar://8385355
     *        (latter can be viewed at http://openradar.appspot.com/8385355 )
     */
    [parameters setValue:[NSNumber numberWithBool:YES] forKey:kAlfrescoAllowUntrustedSSLCertificate];
    
    [AlfrescoCloudSession connectWithOAuthData:nil parameters:parameters completionBlock:^(id<AlfrescoSession> cloudSession, NSError *error){
        if (nil == cloudSession)
        {
            self.lastTestSuccessful = NO;
            self.lastTestFailureMessage = [NSString stringWithFormat:@"Cloud session could not be authenticated. Error %@",[error localizedDescription]];
            AlfrescoLogDebug(@"*** The returned cloudSession is NIL with error message %@ ***",self.lastTestFailureMessage);
            self.callbackCompleted = YES;
        }
        else
        {
            AlfrescoLogDebug(@"*** Cloud session is NOT nil ***");
            XCTAssertNotNil(cloudSession, @"Cloud session should not be nil");
            self.lastTestSuccessful = YES;
            self.currentSession = cloudSession;
            self.callbackCompleted = YES;
            success = YES;
        }
    }];
    

    [self waitUntilCompleteWithFixedTimeInterval];
    XCTAssertTrue(self.lastTestSuccessful, @"Cloud authentication failed");
    return success;
}





/*
 @Unique_TCRef 51S0
 */
- (BOOL)retrieveAlfrescoTestFolder
{
    __block BOOL success = NO;
    AlfrescoDocumentFolderService *dfService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.currentSession];
    [dfService retrieveNodeWithFolderPath:self.testFolderPathName completionBlock:^(AlfrescoNode *node, NSError *error){
        if (nil == node)
        {
            self.lastTestSuccessful = NO;
            self.lastTestFailureMessage = [NSString stringWithFormat:@"Could not get the folder %@ in the DocLib . Error %@",self.testFolderPathName, [error localizedDescription]];
            self.callbackCompleted = YES;
        }
        else
        {
            
            if ([node isKindOfClass:[AlfrescoFolder class]])
            {
                self.lastTestSuccessful = YES;
                self.testDocFolder = (AlfrescoFolder *)node;
                self.currentRootFolder = (AlfrescoFolder *)node;
                success = YES;
            }
            else
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = @"the found node appears to be a document and NOT a folder";
            }
            self.callbackCompleted = YES;
        }
    }];
    [self waitUntilCompleteWithFixedTimeInterval];
    XCTAssertTrue(self.lastTestSuccessful, @"Failure to retrieve test folder");
    return success;
}


- (void)resetTestVariables
{
    self.callbackCompleted = NO;
    self.lastTestSuccessful = NO;
    self.lastTestFailureMessage = @"Test failed";    
}


- (void)setUpTestImageFile:(NSString *)filePath
{
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    AlfrescoContentFile *textContentFile = [[AlfrescoContentFile alloc] initWithData:fileData mimeType:@"image/jpeg"];
    self.testImageFile = textContentFile;
}

- (void)waitAtTheEnd
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:TIMEGAP];
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
    } while ([timeoutDate timeIntervalSinceNow] > 0 );
    XCTAssertTrue(self.callbackCompleted, @"TIME OUT: callback did not complete within %d seconds", TIMEGAP);
}

- (void)waitUntilCompleteWithFixedTimeInterval
{
    if (!self.callbackCompleted)
    {
        NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:TIMEINTERVAL];
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        } while (!self.callbackCompleted && [timeoutDate timeIntervalSinceNow] > 0 );
        XCTAssertTrue(self.callbackCompleted, @"TIME OUT: callback did not complete within %d seconds", TIMEINTERVAL);
    }
}

- (void)removePreExistingUnitTestFolder
{
    AlfrescoDocumentFolderService *dfService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.currentSession];
    __weak AlfrescoDocumentFolderService *weakDocumentService = dfService;
    
    [dfService retrieveNodeWithFolderPath:self.unitTestFolder relativeToFolder:self.currentSession.rootFolder completionBlock:^(AlfrescoNode *node, NSError *error) {
        if (node)
        {
            [weakDocumentService deleteNode:node completionBlock:^(BOOL succeeded, NSError *error) {
                // intentionally do nothing
            }];
        }
    }];
}

- (NSString *)failureMessageFromError:(NSError *)error
{
    // just return if error has not been provided
    if (error == nil)
    {
        return nil;
    }
    
    NSString *message = error.localizedDescription;
    
    // add the failure reason, if there is one!
    if (error.localizedFailureReason != nil)
    {
        message = [message stringByAppendingFormat:@" - %@", error.localizedFailureReason];
    }
    else
    {
        // try looking for an underlying error and output the whole error object
        NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
        if (underlyingError != nil)
        {
            message = [message stringByAppendingFormat:@" - %@", underlyingError];
        }
        else
        {
            // look for HTTP error code as a last resort
            NSNumber *httpStatusCode = error.userInfo[kAlfrescoErrorKeyHTTPResponseCode];
            if (httpStatusCode)
            {
                message = [message stringByAppendingFormat:@" (HTTP Status Code: %d)", [httpStatusCode intValue]];
            }
        }
    }
    
    return message;
}

@end

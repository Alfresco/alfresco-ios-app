/*
 ******************************************************************************
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
 *****************************************************************************
 */

#import "AlfrescoConfigServiceTest.h"
#import "AlfrescoViewConfig.h"
#import "AlfrescoFieldConfig.h"
#import "AlfrescoFieldGroupConfig.h"
#import "AlfrescoConfigInternalConstants.h"
#import "AlfrescoConfigEvaluator.h"
#import "AlfrescoSDKInternalConstants.h"

NSString * const kAlfrescoTestApplicationId = @"com.alfresco.mobile.ios.test";

@interface AlfrescoConfigServiceTest ()
@property (nonatomic, strong) NSString *localConfigFileLocation;
@end

@implementation AlfrescoConfigServiceTest

- (void)setUp
{
    [super setUp];
    
    self.localConfigFileLocation = NSTemporaryDirectory();
}

- (void)tearDown
{
    [super tearDown];
    
    // Delete the local path so that the cached file is not used in follow up test runs
    NSString *completePathToLocalConfig = [NSTemporaryDirectory() stringByAppendingPathComponent:kAlfrescoConfigServiceDefaultFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:completePathToLocalConfig])
    {
        [[NSFileManager defaultManager] removeItemAtPath:completePathToLocalConfig error:nil];
    }
}

- (NSDictionary *)dictionaryForConfigServiceValidTests
{
    NSString *configFolderPath = [NSBundle bundleForClass:self.class].resourcePath;
    NSDictionary *parameters = @{kAlfrescoConfigServiceParameterApplicationId: kAlfrescoTestApplicationId,
                                 kAlfrescoConfigServiceParameterFolder: configFolderPath,
                                 kAlfrescoConfigServiceParameterFileName: @"valid-config-test.json"};
    return parameters;
}

- (NSDictionary *)dictionaryForConfigServiceInvalidTests
{
    NSString *configFolderPath = [NSBundle bundleForClass:self.class].resourcePath;
    NSDictionary *parameters = @{kAlfrescoConfigServiceParameterApplicationId: kAlfrescoTestApplicationId,
                                 kAlfrescoConfigServiceParameterFolder: configFolderPath,
                                 kAlfrescoConfigServiceParameterFileName: @"invalid-config-test.json"};
    return parameters;
}

- (NSDictionary *)dictionaryForConfigServiceEmptyTest
{
    NSString *configFolderPath = [NSBundle bundleForClass:self.class].resourcePath;
    NSDictionary *parameters = @{kAlfrescoConfigServiceParameterApplicationId: kAlfrescoTestApplicationId,
                                 kAlfrescoConfigServiceParameterFolder: configFolderPath,
                                 kAlfrescoConfigServiceParameterFileName: @"empty-config-test.json"};
    return parameters;
}

- (id<AlfrescoSession>)sessionForConfigService
{
    [self.currentSession setObject:kAlfrescoTestApplicationId forParameter:kAlfrescoConfigServiceParameterApplicationId];
    [self.currentSession setObject:self.localConfigFileLocation forParameter:kAlfrescoConfigServiceParameterFolder];
    return self.currentSession;
}

- (AlfrescoDocument *)documentWithAspects
{
    // manually create a document object that is cm:content and has the titled and geographic aspects
    NSDictionary *properties = @{kCMISPropertyContentStreamLength: @(25),
                                 kCMISPropertyContentStreamMediaType: @"text/plain",
                                 kCMISPropertyObjectId: @"1234567890",
                                 kCMISPropertyName: @"dummy.txt",
                                 kCMISPropertyObjectTypeId: @"cm:content",
                                 kAlfrescoNodeAspects: @[@"cm:titled", @"cm:geographic"],
                                 kCMISPropertyCreatedBy: @"mobile",
                                 kCMISPropertyModifiedBy: @"mobile",
                                 kCMISPropertyCreationDate: [NSDate date],
                                 kCMISPropertyModificationDate: [NSDate date],
                                 kAlfrescoModelPropertyTitle: @"Title",
                                 kAlfrescoModelPropertyDescription: @"Description"};
    
    return [[AlfrescoDocument alloc] initWithProperties:properties];
}

- (AlfrescoDocument *)customDocumentWithAspects
{
    // manually create a document object that is fdk:everything and has the titled aspect
    NSDictionary *properties = @{kCMISPropertyContentStreamLength: @(25),
                                 kCMISPropertyContentStreamMediaType: @"text/plain",
                                 kCMISPropertyObjectId: @"1234567890",
                                 kCMISPropertyName: @"dummy.txt",
                                 kCMISPropertyObjectTypeId: @"fdk:everything",
                                 kAlfrescoNodeAspects: @[@"cm:titled", @"cm:geographic", @"audio:audio"],
                                 kCMISPropertyCreatedBy: @"mobile",
                                 kCMISPropertyModifiedBy: @"mobile",
                                 kCMISPropertyCreationDate: [NSDate date],
                                 kCMISPropertyModificationDate: [NSDate date],
                                 kAlfrescoModelPropertyTitle: @"Title",
                                 kAlfrescoModelPropertyDescription: @"Description"};
    
    return [[AlfrescoDocument alloc] initWithProperties:properties];
}

#pragma mark - Valid config tests

- (void)testSetupFromDictionary
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // retrieve basic config information
        [self.configService retrieveConfigInfoWithCompletionBlock:^(AlfrescoConfigInfo *configInfo, NSError *error) {
            if (configInfo == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertTrue([configInfo.schemaVersion isEqualToString:@"0.2"],
                              @"Expected schema version to be 0.2 but it was %@", configInfo.schemaVersion);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testSetupFromSession
{
    if (self.setUpSuccess)
    {
        if (!self.isCloud)
        {
            self.configService = [[AlfrescoConfigService alloc] initWithSession:[self sessionForConfigService]];
            
            // retrieve basic config information
            [self.configService retrieveConfigInfoWithCompletionBlock:^(AlfrescoConfigInfo *configInfo, NSError *error) {
                if (configInfo == nil)
                {
                    self.lastTestSuccessful = NO;
                    self.lastTestFailureMessage = [self failureMessageFromError:error];
                    self.callbackCompleted = YES;
                }
                else
                {
                    XCTAssertTrue([configInfo.schemaVersion isEqualToString:@"0.2"],
                                  @"Expected schema version to be 0.2 but it was %@", configInfo.schemaVersion);
                    
                    self.lastTestSuccessful = YES;
                    self.callbackCompleted = YES;
                }
            }];
            
            [self waitUntilCompleteWithFixedTimeInterval];
            XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
        }
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testRepositoryConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // retrieve the repository config
        [self.configService retrieveRepositoryConfigWithCompletionBlock:^(AlfrescoRepositoryConfig *repoConfig, NSError *error) {
            if (repoConfig == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertTrue([[repoConfig.shareURL absoluteString] isEqualToString:@"http://ec2-176-34-173-67.eu-west-1.compute.amazonaws.com/share"] , @"Expected shareURL to be http://ec2-176-34-173-67.eu-west-1.compute.amazonaws.com/share but was %@", repoConfig.shareURL);
                
                XCTAssertTrue([[repoConfig.cmisURL absoluteString] isEqualToString:@"http://ec2-176-34-173-67.eu-west-1.compute.amazonaws.com/alfresco/cmisatom"] , @"Expected cmisURL to be http://ec2-176-34-173-67.eu-west-1.compute.amazonaws.com/alfresco/cmisatom but was %@", repoConfig.cmisURL);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testProfiles
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // start by retrieving all profiles in the config file
        [self.configService retrieveProfilesWithCompletionBlock:^(NSArray *allProfiles, NSError *allProfilesError) {
            if (allProfiles == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:allProfilesError];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertTrue(allProfiles.count > 0, @"Expected there to be at least one profile");
                
                // try and find the profiles we're expecting
                AlfrescoProfileConfig *defaultProfile = nil;
                AlfrescoProfileConfig *customProfile = nil;
                for (AlfrescoProfileConfig *profile in allProfiles)
                {
                    if ([profile.identifier isEqualToString:@"default"])
                    {
                        defaultProfile = profile;
                    }
                    else if ([profile.identifier isEqualToString:@"custom"])
                    {
                        customProfile = profile;
                    }
                }
                
                // make sure the 2 profiles we're expecting are present
                XCTAssertNotNil(defaultProfile, @"Expected to find a profile named default");
                XCTAssertNotNil(customProfile, @"Expected to find a profile named custom");
                
                // check the profiles have the correct properties
                XCTAssertTrue(defaultProfile.isDefault, @"Expected the default profile to be marked as default");
                XCTAssertTrue([defaultProfile.label isEqualToString:@"Default Profile"],
                              @"Expected default profile label to be 'Default Profile' but was %@", defaultProfile.label);
                XCTAssertTrue([defaultProfile.summary isEqualToString:@"Description of the default profile"],
                              @"Expected default profile summary to be 'Description of the default profile' but was %@", defaultProfile.summary);
                XCTAssertTrue([defaultProfile.rootViewId isEqualToString:@"root-navigation"],
                              @"Expected default profile rootViewId to be 'root-navigation' but was %@", defaultProfile.rootViewId);
                
                XCTAssertFalse(customProfile.isDefault, @"Expected the custom profile to not be marked as default");
                XCTAssertTrue([customProfile.label isEqualToString:@"Custom Profile"],
                              @"Expected custom profile label to be 'Custom Profile' but was %@", customProfile.label);
                XCTAssertTrue([customProfile.summary isEqualToString:@"Description of the custom profile"],
                              @"Expected custom profile summary to be 'Description of the custom profile' but was %@", customProfile.summary);
                XCTAssertTrue([customProfile.rootViewId isEqualToString:@"views-menu-default"],
                              @"Expected custom profile rootViewId to be 'views-menu-default' but was %@", customProfile.rootViewId);
                
                // try retrieving an individual profile
                [self.configService retrieveProfileWithIdentifier:@"custom" completionBlock:^(AlfrescoProfileConfig *profile1, NSError *singleProfileError) {
                    if (profile1 == nil)
                    {
                        self.lastTestSuccessful = NO;
                        self.lastTestFailureMessage = [self failureMessageFromError:singleProfileError];
                        self.callbackCompleted = YES;
                    }
                    else
                    {
                        XCTAssertTrue([profile1.identifier isEqualToString:@"custom"],
                                      @"Expected retrieved profile identifier to be 'custom' but was %@", profile1.identifier);
                        XCTAssertFalse(profile1.isDefault, @"Expected the retrieved profile to not be marked as default");
                        XCTAssertTrue([profile1.label isEqualToString:@"Custom Profile"],
                                      @"Expected retrieved profile label to be 'Custom Profile' but was %@", profile1.label);
                        XCTAssertTrue([profile1.summary isEqualToString:@"Description of the custom profile"],
                                      @"Expected retrieved profile summary to be 'Description of the custom profile' but was %@", profile1.summary);
                        XCTAssertTrue([profile1.rootViewId isEqualToString:@"views-menu-default"],
                                      @"Expected retrieved profile rootViewId to be 'views-menu-default' but was %@", profile1.rootViewId);
                        
                        // try retrieving the default profile
                        [self.configService retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *profile2, NSError *defaultProfileError) {
                            if (profile2 == nil)
                            {
                                self.lastTestSuccessful = NO;
                                self.lastTestFailureMessage = [self failureMessageFromError:defaultProfileError];
                                self.callbackCompleted = YES;
                            }
                            else
                            {
                                XCTAssertTrue([profile2.identifier isEqualToString:@"default"],
                                              @"Expected retrieved profile identifier to be 'default' but was %@", profile2.identifier);
                                XCTAssertTrue(profile2.isDefault, @"Expected the retrieved profile to be marked as default");
                                XCTAssertTrue([profile2.label isEqualToString:@"Default Profile"],
                                              @"Expected retrieved profile label to be 'Default Profile' but was %@", profile2.label);
                                XCTAssertTrue([profile2.summary isEqualToString:@"Description of the default profile"],
                                              @"Expected retrieved profile summary to be 'Description of the default profile' but was %@", profile2.summary);
                                XCTAssertTrue([profile2.rootViewId isEqualToString:@"root-navigation"],
                                              @"Expected retrieved profile rootViewId to be 'root-navigation' but was %@", profile2.rootViewId);
                                
                                self.lastTestSuccessful = YES;
                                self.callbackCompleted = YES;
                            }
                        }];
                    }
                }];
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testFeatureConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // retrieve all the feature config
        [self.configService retrieveFeatureConfigWithCompletionBlock:^(NSArray *allFeatureConfig, NSError *allFeatureConfigError) {
            if (allFeatureConfig == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:allFeatureConfigError];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertTrue(allFeatureConfig.count > 0, @"Expected there to be at least one feature config");
                
                // try and find the features we're expecting
                AlfrescoFeatureConfig *dataProtectionFeature = nil;
                AlfrescoFeatureConfig *storageFeature = nil;
                for (AlfrescoFeatureConfig *feature in allFeatureConfig)
                {
                    if ([feature.identifier isEqualToString:@"com.alfresco.client.feature.dataprotection"])
                    {
                        dataProtectionFeature = feature;
                    }
                    else if ([feature.identifier isEqualToString:@"com.alfresco.client.feature.storage"])
                    {
                        storageFeature = feature;
                    }
                }
                
                // make sure the 2 features we're expecting are present
                XCTAssertNotNil(dataProtectionFeature, @"Expected to find a feature named com.alfresco.client.feature.dataprotection");
                XCTAssertNotNil(storageFeature, @"Expected to find a feature named com.alfresco.client.feature.storage");
                
                // check the features have the correct properties
                XCTAssertTrue([dataProtectionFeature.label isEqualToString:@"Data Protection"],
                              @"Expected data protection feature label to be 'Data Protection' but was %@", dataProtectionFeature.label);
                XCTAssertTrue([dataProtectionFeature.summary isEqualToString:@"Enable data protection by default for all account"],
                              @"Expected data protection feature summary to be 'Enable data protection by default for all account' but was %@", dataProtectionFeature.summary);
                
                XCTAssertTrue([storageFeature.label isEqualToString:@"Storage"],
                              @"Expected data protection feature label to be 'Storage' but was %@", storageFeature.label);
                XCTAssertTrue([storageFeature.summary isEqualToString:@"Define where to store the information in general"],
                              @"Expected data protection feature summary to be 'Define where to store the information in general' but was %@", storageFeature.summary);
                
                // retrieve a feature by identifier
                [self.configService retrieveFeatureConfigWithIdentifier:@"com.alfresco.client.feature.dataprotection" completionBlock:^(AlfrescoFeatureConfig *featureConfig, NSError *featureConfigError) {
                    if (featureConfig == nil)
                    {
                        self.lastTestSuccessful = NO;
                        self.lastTestFailureMessage = [self failureMessageFromError:featureConfigError];
                        self.callbackCompleted = YES;
                    }
                    else
                    {
                        // check we got the right feature config
                        XCTAssertTrue([featureConfig.identifier isEqualToString:@"com.alfresco.client.feature.dataprotection"],
                                      @"Expected retrieved feature identifier to be 'com.alfresco.client.feature.dataprotection' but was %@", featureConfig.identifier);
                        XCTAssertTrue([featureConfig.label isEqualToString:@"Data Protection"],
                                      @"Expected retrieved feature label to be 'Data Protection' but was %@", featureConfig.label);
                        XCTAssertTrue([featureConfig.summary isEqualToString:@"Enable data protection by default for all account"],
                                      @"Expected retrieved feature summary to be 'Enable data protection by default for all account' but was %@", featureConfig.summary);
                        
                        self.lastTestSuccessful = YES;
                        self.callbackCompleted = YES;
                    }
                }];
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testViewConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // retrieve view config for specific view
        [self.configService retrieveViewConfigWithIdentifier:@"view-activities-default" completionBlock:^(AlfrescoViewConfig *config, NSError *error) {
            if (config == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                // check the view is as expected
                XCTAssertTrue([config.identifier isEqualToString:@"view-activities-default"],
                              @"Expected an identifier of 'view-activities-default' but it was %@", config.identifier);
                XCTAssertTrue([config.label isEqualToString:@"Activities"],
                              @"Expected a label of 'Activities' but it was %@", config.label);
                XCTAssertTrue([config.summary isEqualToString:@"Activities Description"],
                              @"Expected a summary of 'Activities Description' but it was %@", config.summary);
                XCTAssertTrue([config.iconIdentifier isEqualToString:@"Activities Icon"],
                              @"Expected a summary of 'Activities Icon' but it was %@", config.iconIdentifier);
                XCTAssertTrue([config.type isEqualToString:@"com.alfresco.client.view.activities"],
                              @"Expected a type of 'com.alfresco.client.view.activities' but it was %@", config.type);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testSimpleViewGroupConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // retrieve view group config for specific view group
        [self.configService retrieveViewGroupConfigWithIdentifier:@"views-menu-default" completionBlock:^(AlfrescoViewGroupConfig *config, NSError *error) {
            if (config == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertTrue([config.identifier isEqualToString:@"views-menu-default"],
                              @"Expected view group config identifier to be 'views-menu-default' but it was %@", config.identifier);
                XCTAssertTrue([config.label isEqualToString:@"Default Menu"],
                              @"Expected view group label of 'Default Menu' but it was %@", config.label);
                
                XCTAssertNotNil(config.items, @"Expected items property to be populated");
                XCTAssertTrue(config.items.count == 3, @"Expected there to be 3 view configurations");
                
                // make sure the first item is a view
                AlfrescoItemConfig *item1 = config.items[0];
                XCTAssertTrue([item1 isKindOfClass:[AlfrescoViewConfig class]], @"Expected the first item to be a view but it was %@", item1);
                AlfrescoViewConfig *view1 = (AlfrescoViewConfig *)item1;
                XCTAssertTrue([view1.identifier isEqualToString:@"view-activities-default"],
                              @"Expected an identifier of 'view-activities-default' but it was %@", view1.identifier);
                XCTAssertTrue([view1.label isEqualToString:@"Activities"],
                              @"Expected a label of 'Activities' but it was %@", view1.label);
                XCTAssertTrue([view1.summary isEqualToString:@"Activities Description"],
                              @"Expected a summary of 'Activities Description' but it was %@", view1.summary);
                XCTAssertTrue([view1.iconIdentifier isEqualToString:@"Activities Icon"],
                              @"Expected a summary of 'Activities Icon' but it was %@", view1.iconIdentifier);
                XCTAssertTrue([view1.type isEqualToString:@"com.alfresco.client.view.activities"],
                              @"Expected a type of 'com.alfresco.client.view.activities' but it was %@", view1.type);
                
                // make sure the second item is a view
                AlfrescoItemConfig *item2 = config.items[1];
                XCTAssertTrue([item2 isKindOfClass:[AlfrescoViewConfig class]], @"Expected the second item to be a view but it was %@", item2);
                AlfrescoViewConfig *view2 = (AlfrescoViewConfig *)item2;
                XCTAssertTrue([view2.identifier isEqualToString:@"view-repository-default"],
                              @"Expected an identifier of 'view-repository-default' but it was %@", view2.identifier);
                XCTAssertTrue([view2.type isEqualToString:@"com.alfresco.client.view.repository"],
                              @"Expected a type of 'com.alfresco.client.view.repository' but it was %@", view2.type);
                XCTAssertNil(view2.label, @"Expected label for view2 to be nil");
                XCTAssertNil(view2.summary, @"Expected summary for view2 to be nil");
                XCTAssertNil(view2.iconIdentifier, @"Expected icon identifier for view2 to be nil");
                XCTAssertNotNil(view2.parameters, @"Expected parameters to be populated");
                XCTAssertTrue(view2.parameters.count == 1,
                              @"Expected there to be 1 parameter but there were %lu", (unsigned long)view2.parameters.count);
                XCTAssertTrue([view2.parameters[@"startLocation"] isEqualToString:@"companyhome"],
                              @"Expected the startLocation parameter to be 'companyhome' but was %@", view2.parameters[@"startLocation"]);
                
                // make sure the third item is a view
                AlfrescoItemConfig *item3 = config.items[2];
                XCTAssertTrue([item3 isKindOfClass:[AlfrescoViewConfig class]], @"Expected the third item to be a view but it was %@", item3);
                AlfrescoViewConfig *view3 = (AlfrescoViewConfig *)item3;
                XCTAssertNil(view3.identifier, @"Expected identifier for view3 to be nil");
                XCTAssertTrue([view3.label isEqualToString:@"Sites"],
                              @"Expected a label of 'Sites' but it was %@", view3.label);
                XCTAssertTrue([view3.summary isEqualToString:@"Sites Description"],
                              @"Expected a summary of 'Sites Description' but it was %@", view3.summary);
                XCTAssertTrue([view3.iconIdentifier isEqualToString:@"Sites Icon"],
                              @"Expected a summary of 'Sites Icon' but it was %@", view3.iconIdentifier);
                XCTAssertTrue([view3.type isEqualToString:@"com.alfresco.client.view.sites"],
                              @"Expected a type of 'com.alfresco.client.view.sites' but it was %@", view3.type);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testViewGroupReferenceConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // retrieve view group config for specific view group
        [self.configService retrieveViewGroupConfigWithIdentifier:@"root-navigation" completionBlock:^(AlfrescoViewGroupConfig *config, NSError *error) {
            if (config == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertTrue([config.identifier isEqualToString:@"root-navigation"],
                              @"Expected view group config identifier to be 'root-navigation' but it was %@", config.identifier);
                XCTAssertTrue([config.label isEqualToString:@"Root Navigation"],
                              @"Expected view group label of 'Root Navigation' but it was %@", config.label);
                
                XCTAssertNotNil(config.items, @"Expected items property to be populated");
                XCTAssertTrue(config.items.count == 2, @"Expected there to be 2 items");
                
                // make sure the first item is a view group
                AlfrescoItemConfig *item1 = config.items[0];
                XCTAssertTrue([item1 isKindOfClass:[AlfrescoViewGroupConfig class]],
                              @"Expected the first item to be a view group but it was %@", item1);
                AlfrescoViewGroupConfig *viewGroup1 = (AlfrescoViewGroupConfig *)item1;
                XCTAssertTrue([viewGroup1.identifier isEqualToString:@"views-menu-default"],
                              @"Expected an identifier of 'views-menu-default' but it was %@", viewGroup1.identifier);
                XCTAssertTrue([viewGroup1.label isEqualToString:@"Default Menu"],
                              @"Expected a label of 'Default Menu' but it was %@", viewGroup1.label);
                XCTAssertTrue(viewGroup1.items.count == 3, @"Expected there to be 3 items");
                XCTAssertTrue([viewGroup1.items[0] isKindOfClass:[AlfrescoViewConfig class]], @"Expected item to be a view but it was %@", viewGroup1.items[0]);
                XCTAssertTrue([viewGroup1.items[1] isKindOfClass:[AlfrescoViewConfig class]], @"Expected item to be a view but it was %@", viewGroup1.items[1]);
                XCTAssertTrue([viewGroup1.items[2] isKindOfClass:[AlfrescoViewConfig class]], @"Expected item to be a view but it was %@", viewGroup1.items[2]);
                
                // make sure the second item is a view
                AlfrescoItemConfig *item2 = config.items[1];
                XCTAssertTrue([item2 isKindOfClass:[AlfrescoViewConfig class]], @"Expected the second item to be a view but it was %@", item2);
                AlfrescoViewConfig *view2 = (AlfrescoViewConfig *)item2;
                XCTAssertTrue([view2.identifier isEqualToString:@"view-tasks"],
                              @"Expected an identifier of 'view-tasks' but it was %@", view2.identifier);
                XCTAssertTrue([view2.type isEqualToString:@"com.alfresco.client.view.tasks"],
                              @"Expected a type of 'com.alfresco.client.view.tasks' but it was %@", view2.type);
                XCTAssertTrue([view2.label isEqualToString:@"Tasks"],
                              @"Expected a label of 'Tasks' but it was %@", view2.label);
                XCTAssertNil(view2.summary, @"Expected summary for view2 to be nil");
                XCTAssertNil(view2.iconIdentifier, @"Expected icon identifier for view2 to be nil");
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testViewSubGroupConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // retrieve view group config for specific view group
        [self.configService retrieveViewGroupConfigWithIdentifier:@"sub-group-test" completionBlock:^(AlfrescoViewGroupConfig *config, NSError *error) {
            if (config == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                // check root
                XCTAssertTrue([config.identifier isEqualToString:@"sub-group-test"],
                              @"Expected view group config identifier to be 'sub-group-test' but it was %@", config.identifier);
                XCTAssertTrue([config.label isEqualToString:@"Sub Group Test"],
                              @"Expected view group label of 'Sub Group Test' but it was %@", config.label);
                XCTAssertTrue(config.items.count == 1, @"Expected there to be 1 item but there was %lu", (unsigned long)config.items.count);
                
                // check level1
                AlfrescoViewGroupConfig *level1 = config.items.firstObject;
                XCTAssertTrue([level1.identifier isEqualToString:@"level1"],
                              @"Expected view group config identifier to be 'level1' but it was %@", level1.identifier);
                XCTAssertTrue([level1.label isEqualToString:@"Level 1"],
                              @"Expected view group label of 'Level 1' but it was %@", level1.label);
                XCTAssertTrue(level1.items.count == 1, @"Expected there to be 1 item but there was %lu", (unsigned long)level1.items.count);
                
                // check level2
                AlfrescoViewGroupConfig *level2 = level1.items.firstObject;
                XCTAssertTrue([level2.identifier isEqualToString:@"level2"],
                              @"Expected view group config identifier to be 'level2' but it was %@", level2.identifier);
                XCTAssertTrue([level2.label isEqualToString:@"Level 2"],
                              @"Expected view group label of 'Level 2' but it was %@", level2.label);
                XCTAssertTrue(level2.items.count == 1, @"Expected there to be 1 item but there was %lu", (unsigned long)level2.items.count);
                
                // check level3
                AlfrescoViewGroupConfig *level3 = level2.items.firstObject;
                XCTAssertTrue([level3.identifier isEqualToString:@"level3"],
                              @"Expected view group config identifier to be 'level3' but it was %@", level3.identifier);
                XCTAssertTrue([level3.label isEqualToString:@"Level 3"],
                              @"Expected view group label of 'Level 3' but it was %@", level3.label);
                XCTAssertTrue(level3.items.count == 2, @"Expected there to be 2 items but there was %lu", (unsigned long)level3.items.count);
                
                AlfrescoViewConfig *level3View = level3.items.firstObject;
                XCTAssertTrue([level3View.identifier isEqualToString:@"viewAtLevel3"],
                              @"Expected level 3 view identifier to be 'viewAtLevel3' but it was %@", level3View.identifier);
                
                AlfrescoViewGroupConfig *level3ViewGroup = level3.items[1];
                XCTAssertTrue([level3ViewGroup.identifier isEqualToString:@"views-menu-default"],
                              @"Expected level 3 view group identifier to be 'views-menu-default' but it was %@", level3ViewGroup.identifier);
                XCTAssertTrue(level3ViewGroup.items.count == 3,
                              @"Expected level 3 view group to have 3 items but there was %lu", (unsigned long)level3ViewGroup.items.count);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testSimpleFormConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        AlfrescoDocument *document = [self documentWithAspects];
        
        // retrieve form config using scope
        AlfrescoConfigScope *scope = [[AlfrescoConfigScope alloc] initWithProfile:kAlfrescoConfigProfileDefaultIdentifier
                                                                          context:@{kAlfrescoConfigScopeContextNode: document}];
        [self.configService retrieveFormConfigWithIdentifier:@"view-properties" scope:scope completionBlock:^(AlfrescoFormConfig *config, NSError *error) {
            if (config == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                // check we got the right form config
                XCTAssertTrue([config.identifier isEqualToString:@"view-properties"],
                              @"Expected form config identifier to be 'view-properties' but was %@", config.identifier);
                XCTAssertTrue([config.label isEqualToString:@"view.properties.title"],
                              @"Expected form config label to be 'view.properties.title' but was %@", config.label);
                XCTAssertTrue([config.summary isEqualToString:@"view.properties.description"],
                              @"Expected form config label to be 'view.properties.description' but was %@", config.summary);
                XCTAssertTrue([config.layout isEqualToString:@"1column"],
                              @"Expected form config label to be '1column' but was %@", config.layout);
                
                // retrieve the field config
                NSArray *groups = config.items;
                XCTAssertTrue(groups.count == 2, @"Expected to find config for 2 field groups");
                
                // get the field config for the type properties group
                NSArray *typeProperties = [groups[0] items];
                XCTAssertTrue(typeProperties.count == 10,
                              @"Expected to find config for 10 fields but there was %lu", (unsigned long)typeProperties.count);
                
                AlfrescoFieldConfig *nameField = typeProperties[0];
                XCTAssertTrue([nameField.modelIdentifier isEqualToString:@"cm:name"],
                              @"Expected first field to be cm:name but was %@", nameField.identifier);
                XCTAssertTrue([nameField.label isEqualToString:@"Name"],
                              @"Expected first field to have label of 'Name' but was %@", nameField.label);
                
                AlfrescoFieldConfig *titleField = typeProperties[1];
                XCTAssertTrue([titleField.modelIdentifier isEqualToString:@"cm:title"],
                              @"Expected second field to be cm:title but was %@", titleField.identifier);
                XCTAssertTrue([titleField.label isEqualToString:@"Title"],
                              @"Expected second field to have label of 'Title' but was %@", titleField.label);
                
                AlfrescoFieldConfig *descriptionField = typeProperties[2];
                XCTAssertTrue([descriptionField.modelIdentifier isEqualToString:@"cm:description"],
                              @"Expected third field to be cm:description but was %@", descriptionField.identifier);
                XCTAssertTrue([descriptionField.label isEqualToString:@"Description"],
                              @"Expected third field to have label of 'Description' but was %@", descriptionField.label);
                
                AlfrescoFieldConfig *mimetypeField = typeProperties[3];
                XCTAssertTrue([mimetypeField.modelIdentifier isEqualToString:@"mimetype"],
                              @"Expected fourth field to be mimetype but was %@", mimetypeField.identifier);
                XCTAssertTrue([mimetypeField.label isEqualToString:@"Mimetype"],
                              @"Expected fourth field to have label of 'Mimetype' but was %@", mimetypeField.label);
                
                AlfrescoFieldConfig *authorField = typeProperties[4];
                XCTAssertTrue([authorField.modelIdentifier isEqualToString:@"cm:author"],
                              @"Expected fifth field to be cm:author but was %@", authorField.identifier);
                XCTAssertTrue([authorField.label isEqualToString:@"Author"],
                              @"Expected fifth field to have label of 'Author' but was %@", authorField.label);
                
                AlfrescoFieldConfig *sizeField = typeProperties[5];
                XCTAssertTrue([sizeField.modelIdentifier isEqualToString:@"size"],
                              @"Expected sixth field to be size but was %@", sizeField.modelIdentifier);
                XCTAssertTrue([sizeField.label isEqualToString:@"Size"],
                              @"Expected sixth field to have label of 'Size' but was %@", sizeField.label);
                
                AlfrescoFieldConfig *creatorField = typeProperties[6];
                XCTAssertTrue([creatorField.modelIdentifier isEqualToString:@"cm:creator"],
                              @"Expected seventh field to be cm:creator but was %@", creatorField.identifier);
                XCTAssertTrue([creatorField.label isEqualToString:@"Created By"],
                              @"Expected seventh field to have label of 'Created By' but was %@", creatorField.label);
                
                AlfrescoFieldConfig *createdField = typeProperties[7];
                XCTAssertTrue([createdField.modelIdentifier isEqualToString:@"cm:created"],
                              @"Expected eigth field to be cm:created but was %@", createdField.identifier);
                XCTAssertTrue([createdField.label isEqualToString:@"Created"],
                              @"Expected eigth field to have label of 'Created' but was %@", creatorField.label);
                
                AlfrescoFieldConfig *modifierField = typeProperties[8];
                XCTAssertTrue([modifierField.modelIdentifier isEqualToString:@"cm:modifier"],
                              @"Expected ninth field to be cm:modifier but was %@", modifierField.identifier);
                XCTAssertTrue([modifierField.label isEqualToString:@"Modified By"],
                              @"Expected ninth field to have label of 'Modified By' but was %@", modifierField.label);
                
                AlfrescoFieldConfig *modifiedField = typeProperties[9];
                XCTAssertTrue([modifiedField.modelIdentifier isEqualToString:@"cm:modified"],
                              @"Expected tenth field to be cm:modified but was %@", modifiedField.identifier);
                XCTAssertTrue([modifiedField.label isEqualToString:@"Modified"],
                              @"Expected tenth field to have label of 'Modified' but was %@", modifiedField.label);
                
                // get the field config for the aspect properties group
                NSArray *aspectProperties = [groups[1] items];
                XCTAssertTrue(aspectProperties.count == 2,
                              @"Expected to find config for 2 fields but there were %lu", (unsigned long)aspectProperties.count);
                
                AlfrescoFieldConfig *latitudeField = aspectProperties[0];
                XCTAssertTrue([latitudeField.modelIdentifier isEqualToString:@"cm:latitude"],
                              @"Expected first aspect field to be cm:latitude but was %@", latitudeField.identifier);
                XCTAssertTrue([latitudeField.label isEqualToString:@"Latitude"],
                              @"Expected first aspect field to have label of 'Latitude' but was %@", latitudeField.label);
                
                AlfrescoFieldConfig *longitudeField = aspectProperties[1];
                XCTAssertTrue([longitudeField.modelIdentifier isEqualToString:@"cm:longitude"],
                              @"Expected second aspect field to be cm:longitude but was %@", longitudeField.identifier);
                XCTAssertTrue([longitudeField.label isEqualToString:@"Longitude"],
                              @"Expected second aspect field to have label of 'Longitude' but was %@", longitudeField.label);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testFieldGroupReferenceConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        AlfrescoDocument *document = [self customDocumentWithAspects];
        
        // retrieve form config using scope
        AlfrescoConfigScope *scope = [[AlfrescoConfigScope alloc] initWithProfile:kAlfrescoConfigProfileDefaultIdentifier
                                                                          context:@{kAlfrescoConfigScopeContextNode: document}];
        [self.configService retrieveFormConfigWithIdentifier:@"view-properties" scope:scope completionBlock:^(AlfrescoFormConfig *config, NSError *error) {
            if (config == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                // check we got the right form config
                XCTAssertTrue([config.identifier isEqualToString:@"view-properties"],
                              @"Expected form config identifier to be 'view-properties' but was %@", config.identifier);
                XCTAssertTrue([config.label isEqualToString:@"view.properties.title"],
                              @"Expected form config label to be 'view.properties.title' but was %@", config.label);
                XCTAssertTrue([config.summary isEqualToString:@"view.properties.description"],
                              @"Expected form config label to be 'view.properties.description' but was %@", config.summary);
                XCTAssertTrue([config.layout isEqualToString:@"1column"],
                              @"Expected form config label to be '1column' but was %@", config.layout);
                
                // check the root field group
                XCTAssertTrue(config.items.count == 3,
                              @"Expected form to have 3 field groups but there were %lu", (unsigned long)config.items.count);
                AlfrescoFieldGroupConfig *typeFieldGroup = config.items.firstObject;
                XCTAssertTrue(typeFieldGroup.items.count == 3,
                              @"Expected root field group to have 3 items but there were %lu", (unsigned long)typeFieldGroup.items.count);
                
                // check the type group
                AlfrescoItemConfig *item1 = typeFieldGroup.items.firstObject;
                XCTAssertTrue([item1 isKindOfClass:[AlfrescoFieldGroupConfig class]],
                              @"Expected the first item to be a field group but it was %@", item1);
                AlfrescoFieldGroupConfig *fieldGroup1 = (AlfrescoFieldGroupConfig *)item1;
                XCTAssertTrue([fieldGroup1.identifier isEqualToString:@"edit:cm:content"],
                              @"Expected field group identifier to be 'edit:cm:content' but was %@", fieldGroup1.identifier);
                XCTAssertTrue(fieldGroup1.items.count == 4,
                              @"Expected field group to have 4 items but there were %lu", (unsigned long)fieldGroup1.items.count);
                
                // check the other type fields
                AlfrescoItemConfig *item2 = typeFieldGroup.items[1];
                XCTAssertTrue([item2 isKindOfClass:[AlfrescoFieldConfig class]],
                              @"Expected the second item to be a field but it was %@", item2);
                AlfrescoFieldConfig *field2 = (AlfrescoFieldConfig *)item2;
                XCTAssertTrue([field2.modelIdentifier isEqualToString:@"fdk:text"],
                              @"Expected field model identifier to be 'fdk:text' but was %@", field2.modelIdentifier);
                XCTAssertTrue([field2.label isEqualToString:@"Text"],
                              @"Expected field model identifier to be 'Text' but was %@", field2.label);
                
                AlfrescoItemConfig *item3 = typeFieldGroup.items[2];
                XCTAssertTrue([item3 isKindOfClass:[AlfrescoFieldConfig class]],
                              @"Expected the third item to be a field but it was %@", item3);
                AlfrescoFieldConfig *field3 = (AlfrescoFieldConfig *)item3;
                XCTAssertTrue([field3.modelIdentifier isEqualToString:@"fdk:int"],
                              @"Expected field model identifier to be 'fdk:int' but was %@", field3.modelIdentifier);
                XCTAssertTrue([field3.label isEqualToString:@"Int"],
                              @"Expected field model identifier to be 'Int' but was %@", field3.label);
                
                // check the aspect groups
                AlfrescoFieldGroupConfig *aspectFieldGroup1 = config.items[1];
                XCTAssertTrue([aspectFieldGroup1.identifier isEqualToString:@"aspect:cm:geographic"],
                              @"Expected group identifier to be 'aspect:cm:geographic' but was %@", aspectFieldGroup1.identifier);
                XCTAssertTrue(aspectFieldGroup1.items.count == 2,
                              @"Expected field group to have 2 items but there were %lu", (unsigned long)aspectFieldGroup1.items.count);
                
                AlfrescoFieldGroupConfig *aspectFieldGroup2 = config.items[2];
                XCTAssertTrue([aspectFieldGroup2.identifier isEqualToString:@"aspect:audio:audio"],
                              @"Expected group identifier to be 'aspect:audio:audio' but was %@", aspectFieldGroup2.identifier);
                XCTAssertTrue(aspectFieldGroup2.items.count == 11,
                              @"Expected field group to have 11 items but there were %lu", (unsigned long)aspectFieldGroup2.items.count);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testFormSubGroupConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // retrieve form config
        [self.configService retrieveFormConfigWithIdentifier:@"sub-group-test" completionBlock:^(AlfrescoFormConfig *config, NSError *error) {
            if (config == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                // check root
                XCTAssertTrue([config.identifier isEqualToString:@"sub-group-test"],
                              @"Expected view group config identifier to be 'sub-group-test' but it was %@", config.identifier);
                XCTAssertTrue([config.label isEqualToString:@"Sub Group Test"],
                              @"Expected view group label of 'Sub Group Test' but it was %@", config.label);
                XCTAssertTrue(config.items.count == 1, @"Expected there to be 1 item but there was %lu", (unsigned long)config.items.count);
                
                // check level1
                AlfrescoFieldGroupConfig *level1 = config.items.firstObject;
                XCTAssertTrue([level1.identifier isEqualToString:@"level1"],
                              @"Expected field group config identifier to be 'level1' but it was %@", level1.identifier);
                XCTAssertTrue([level1.label isEqualToString:@"Level 1"],
                              @"Expected field group label of 'Level 1' but it was %@", level1.label);
                XCTAssertTrue(level1.items.count == 1, @"Expected there to be 1 item but there was %lu", (unsigned long)level1.items.count);
                
                // check level2
                AlfrescoFieldGroupConfig *level2 = level1.items.firstObject;
                XCTAssertTrue([level2.identifier isEqualToString:@"level2"],
                              @"Expected field group config identifier to be 'level2' but it was %@", level2.identifier);
                XCTAssertTrue([level2.label isEqualToString:@"Level 2"],
                              @"Expected field group label of 'Level 2' but it was %@", level2.label);
                XCTAssertTrue(level2.items.count == 1, @"Expected there to be 1 item but there was %lu", (unsigned long)level2.items.count);
                
                // check level3
                AlfrescoFieldGroupConfig *level3 = level2.items.firstObject;
                XCTAssertTrue([level3.identifier isEqualToString:@"level3"],
                              @"Expected field group config identifier to be 'level3' but it was %@", level3.identifier);
                XCTAssertTrue([level3.label isEqualToString:@"Level 3"],
                              @"Expected field group label of 'Level 3' but it was %@", level3.label);
                XCTAssertTrue(level3.items.count == 2, @"Expected there to be 2 items but there was %lu", (unsigned long)level3.items.count);
                
                AlfrescoFieldConfig *level3View = level3.items.firstObject;
                XCTAssertTrue([level3View.modelIdentifier isEqualToString:@"viewAtLevel3"],
                              @"Expected level 3 field model identifier to be 'viewAtLevel3' but it was %@", level3View.modelIdentifier);
                
                AlfrescoFieldGroupConfig *level3FieldGroup = level3.items[1];
                XCTAssertTrue([level3FieldGroup.identifier isEqualToString:@"type:cm:content"],
                              @"Expected level 3 field group identifier to be 'type:cm:content' but it was %@", level3FieldGroup.identifier);
                XCTAssertTrue(level3FieldGroup.items.count == 10,
                              @"Expected level 3 field group to have 10 items but there was %lu", (unsigned long)level3FieldGroup.items.count);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testMissingFormConfigForCustomType
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // manually create a document object has a custom type
        NSDictionary *properties = @{kCMISPropertyContentStreamLength: @(25),
                                     kCMISPropertyContentStreamMediaType: @"text/plain",
                                     kCMISPropertyObjectId: @"1234567890",
                                     kCMISPropertyName: @"dummy.txt",
                                     kCMISPropertyObjectTypeId: @"custom:document",
                                     kAlfrescoNodeAspects: @[@"cm:geographic"],
                                     kCMISPropertyCreatedBy: @"mobile",
                                     kCMISPropertyModifiedBy: @"mobile",
                                     kCMISPropertyCreationDate: [NSDate date],
                                     kCMISPropertyModificationDate: [NSDate date]};
        
        AlfrescoDocument *document = [[AlfrescoDocument alloc] initWithProperties:properties];
        
        // retrieve form config using scope
        AlfrescoConfigScope *scope = [[AlfrescoConfigScope alloc] initWithProfile:kAlfrescoConfigProfileDefaultIdentifier
                                                                          context:@{kAlfrescoConfigScopeContextNode: document}];
        [self.configService retrieveFormConfigWithIdentifier:@"view-properties" scope:scope completionBlock:^(AlfrescoFormConfig *config, NSError *error) {
            if (config == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                // check we got the right form config
                XCTAssertTrue([config.identifier isEqualToString:@"view-properties"],
                              @"Expected form config identifier to be 'view-properties' but was %@", config.identifier);
                
                // check that the config fell back to cm:content config rather than returning nothing
                XCTAssertTrue(config.items.count == 2,
                              @"Expected to find config for 2 field groups but there were %lu", (unsigned long)config.items.count);
                
                // get the field config for the type properties group
                AlfrescoFieldGroupConfig *typePropertiesGroup = config.items[0];
                XCTAssertTrue(typePropertiesGroup.items.count == 10,
                              @"Expected to find config for 10 fields but there was %lu", (unsigned long)typePropertiesGroup.items.count);
                
                // check the first field is cm:name
                AlfrescoFieldConfig *nameField = typePropertiesGroup.items[0];
                XCTAssertTrue([nameField.modelIdentifier isEqualToString:@"cm:name"],
                              @"Expected first field to be cm:name but was %@", nameField.identifier);
                XCTAssertTrue([nameField.label isEqualToString:@"Name"],
                              @"Expected first field to have label of 'Name' but was %@", nameField.label);
                
                // get the field config for the aspect properties group
                AlfrescoFieldGroupConfig *aspectPropertiesGroup = config.items[1];
                XCTAssertTrue(aspectPropertiesGroup.items.count == 2,
                              @"Expected to find config for 2 fields but there were %lu", (unsigned long)aspectPropertiesGroup.items.count);
                
                AlfrescoFieldConfig *latitudeField = aspectPropertiesGroup.items[0];
                XCTAssertTrue([latitudeField.modelIdentifier isEqualToString:@"cm:latitude"],
                              @"Expected first aspect field to be cm:latitude but was %@", latitudeField.identifier);
                XCTAssertTrue([latitudeField.label isEqualToString:@"Latitude"],
                              @"Expected first aspect field to have label of 'Latitude' but was %@", latitudeField.label);
                
                AlfrescoFieldConfig *longitudeField = aspectPropertiesGroup.items[1];
                XCTAssertTrue([longitudeField.modelIdentifier isEqualToString:@"cm:longitude"],
                              @"Expected second aspect field to be cm:longitude but was %@", longitudeField.identifier);
                XCTAssertTrue([longitudeField.label isEqualToString:@"Longitude"],
                              @"Expected second aspect field to have label of 'Longitude' but was %@", longitudeField.label);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testCreationConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // retrieve creation config
        [self.configService retrieveCreationConfigWithCompletionBlock:^(AlfrescoCreationConfig *config, NSError *error) {
            if (config == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                NSArray *documentTypes = config.creatableDocumentTypes;
                NSArray *folderTypes = config.creatableFolderTypes;
                NSArray *mimeTypes = config.creatableMimeTypes;
                
                XCTAssertNil(documentTypes, @"Expected createable document types config to be nil");
                
                XCTAssertNotNil(folderTypes, @"Expected to find createable folder types config");
                XCTAssertTrue(folderTypes.count == 1, @"Expected to find 1 configured folder type");
                AlfrescoItemConfig *folderType1 = folderTypes[0];
                XCTAssertTrue([folderType1.identifier isEqualToString:@"cm:folder"],
                              @"Expected folder type identifier to be 'cm:folder' but it was %@", folderType1.identifier);
                XCTAssertTrue([folderType1.label isEqualToString:@"Default Folder"],
                              @"Expected folder type label to be 'Default Folder' but it was %@", folderType1.label);
                XCTAssertTrue([folderType1.iconIdentifier isEqualToString:@"Default Folder Icon"],
                              @"Expected folder type label to be 'Default Folder Icon' but it was %@", folderType1.iconIdentifier);
                XCTAssertTrue([folderType1.summary isEqualToString:@"Default Description Folder"],
                              @"Expected folder type summary to be 'Default Description Folder' but it was %@", folderType1.summary);
                
                XCTAssertNotNil(mimeTypes, @"Expected to find createable mime types config");
                XCTAssertTrue(mimeTypes.count == 1, @"Expected to find 1 configured mime type");
                AlfrescoItemConfig *mimeType1 = mimeTypes[0];
                XCTAssertTrue([mimeType1.identifier isEqualToString:@"application/vnd.openxmlformats-officedocument.wordprocessingml.document"],
                              @"Expected folder type identifier to be 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' but it was %@", mimeType1.identifier);
                XCTAssertTrue([mimeType1.label isEqualToString:@"Word Document"],
                              @"Expected folder type label to be 'Word Document' but it was %@", mimeType1.label);
                XCTAssertTrue([mimeType1.iconIdentifier isEqualToString:@"Word Icon"],
                              @"Expected folder type label to be 'Word Icon' but it was %@", mimeType1.iconIdentifier);
                XCTAssertTrue([mimeType1.summary isEqualToString:@"Microsoft Office 2007 Word Document"],
                              @"Expected folder type summary to be 'Microsoft Office 2007 Word Document' but it was %@", mimeType1.summary);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testEvaluators
{
    AlfrescoDocument *document = [self customDocumentWithAspects];
    NSDictionary *context = @{kAlfrescoConfigScopeContextNode: document,
                              kAlfrescoConfigScopeContextFormMode: @"edit"};
    AlfrescoConfigScope *scope = [[AlfrescoConfigScope alloc] initWithProfile:kAlfrescoConfigProfileDefaultIdentifier context:context];
    
    if (!self.isCloud)
    {
        // test the repository version evaluator
        NSDictionary *parameters = @{kAlfrescoConfigEvaluatorParameterOperator: @">=",
                                     kAlfrescoConfigEvaluatorParameterMajorVersion: @(4)};
        AlfrescoRepositoryCapabilitiesEvaluator *v4RepoVersionEvaluator = [[AlfrescoRepositoryCapabilitiesEvaluator alloc]
                                                                      initWithIdentifier:kAlfrescoConfigEvaluatorRepositoryCapability
                                                                      parameters:parameters session:self.currentSession];
        if ([self.currentSession.repositoryInfo.majorVersion intValue] >= 4)
        {
            XCTAssertTrue([v4RepoVersionEvaluator evaluate:scope], @"Expected the v4RepoVersionEvaluator evaluator to return true");
        }
        else
        {
            XCTAssertFalse([v4RepoVersionEvaluator evaluate:scope], @"Expected the v4RepoVersionEvaluator evaluator to return false");
        }
        
        parameters = @{kAlfrescoConfigEvaluatorParameterOperator: @"==",
                       kAlfrescoConfigEvaluatorParameterMajorVersion: @(3),
                       kAlfrescoConfigEvaluatorParameterMinorVersion: @(4)};
        AlfrescoRepositoryCapabilitiesEvaluator *v34RepoVersionEvaluator = [[AlfrescoRepositoryCapabilitiesEvaluator alloc]
                                                                       initWithIdentifier:kAlfrescoConfigEvaluatorRepositoryCapability
                                                                       parameters:parameters session:self.currentSession];
        if ([self.currentSession.repositoryInfo.majorVersion intValue] >= 4)
        {
            XCTAssertFalse([v34RepoVersionEvaluator evaluate:scope], @"Expected the v34RepoVersionEvaluator evaluator to return false");
        }
        else
        {
            XCTAssertTrue([v34RepoVersionEvaluator evaluate:scope], @"Expected the v34RepoVersionEvaluator evaluator to return true");
        }
    }
    
    NSDictionary *parameters = @{kAlfrescoConfigEvaluatorParameterOperator: @"==",
                                 kAlfrescoConfigEvaluatorParameterEdition: kAlfrescoRepositoryEditionCloud};
    AlfrescoRepositoryCapabilitiesEvaluator *cloudRepoVersionEvaluator = [[AlfrescoRepositoryCapabilitiesEvaluator alloc]
                                                                     initWithIdentifier:kAlfrescoConfigEvaluatorRepositoryCapability
                                                                     parameters:parameters session:self.currentSession];
    if (self.isCloud)
    {
        XCTAssertTrue([cloudRepoVersionEvaluator evaluate:scope], @"Expected the cloudRepoVersionEvaluator evaluator to return true");
    }
    else
    {
        XCTAssertFalse([cloudRepoVersionEvaluator evaluate:scope], @"Expected the cloudRepoVersionEvaluator evaluator to return false");
    }
    
    // test the profile evaluator
    parameters = @{kAlfrescoConfigEvaluatorParameterProfile: kAlfrescoConfigProfileDefaultIdentifier};
    AlfrescoProfileEvaluator *defaultProfileEvaluator = [[AlfrescoProfileEvaluator alloc]
                                                         initWithIdentifier:kAlfrescoConfigEvaluatorProfile
                                                         parameters:parameters session:self.currentSession];
    XCTAssertTrue([defaultProfileEvaluator evaluate:scope], @"Expected the defaultProfileEvaluator evaluator to return true");
    
    parameters = @{kAlfrescoConfigEvaluatorParameterProfile: @"test-profile"};
    AlfrescoProfileEvaluator *testProfileEvaluator = [[AlfrescoProfileEvaluator alloc]
                                                      initWithIdentifier:kAlfrescoConfigEvaluatorProfile
                                                      parameters:parameters session:self.currentSession];
    XCTAssertFalse([testProfileEvaluator evaluate:scope], @"Expected the testProfileEvaluator evaluator to return false");
    
    // test the node type evaluator
    parameters = @{kAlfrescoConfigEvaluatorParameterTypeName: @"fdk:everything"};
    AlfrescoNodeTypeEvaluator *everythingTypeEvaluator = [[AlfrescoNodeTypeEvaluator alloc]
                                                          initWithIdentifier:kAlfrescoConfigEvaluatorNodeType
                                                          parameters:parameters session:self.currentSession];
    XCTAssertTrue([everythingTypeEvaluator evaluate:scope], @"Expected the everythingTypeEvaluator evaluator to return true");
    
    parameters = @{kAlfrescoConfigEvaluatorParameterTypeName: @"custom:document"};
    AlfrescoNodeTypeEvaluator *missingTypeEvaluator = [[AlfrescoNodeTypeEvaluator alloc]
                                                       initWithIdentifier:kAlfrescoConfigEvaluatorNodeType
                                                       parameters:parameters session:self.currentSession];
    XCTAssertFalse([missingTypeEvaluator evaluate:scope], @"Expected the missingTypeEvaluator evaluator to return false");
    
    // test the aspect evaluator
    parameters = @{kAlfrescoConfigEvaluatorParameterAspectName: @"cm:titled"};
    AlfrescoAspectEvaluator *titledAspectEvaluator = [[AlfrescoAspectEvaluator alloc]
                                                      initWithIdentifier:kAlfrescoConfigEvaluatorAspect
                                                      parameters:parameters session:self.currentSession];
    XCTAssertTrue([titledAspectEvaluator evaluate:scope], @"Expected the titledAspectEvaluator evaluator to return true");
    
    parameters = @{kAlfrescoConfigEvaluatorParameterAspectName: @"cm:dublincore"};
    AlfrescoAspectEvaluator *dublinCoreAspectEvaluator = [[AlfrescoAspectEvaluator alloc]
                                                          initWithIdentifier:kAlfrescoConfigEvaluatorAspect
                                                          parameters:parameters session:self.currentSession];
    XCTAssertFalse([dublinCoreAspectEvaluator evaluate:scope], @"Expected the dublinCoreAspectEvaluator evaluator to return false");
    
    // test form mode
    parameters = @{kAlfrescoConfigEvaluatorParameterMode: @"edit"};
    AlfrescoFormModeEvaluator *editModeEvaluator = [[AlfrescoFormModeEvaluator alloc]
                                                    initWithIdentifier:kAlfrescoConfigEvaluatorFormMode
                                                    parameters:parameters session:self.currentSession];
    XCTAssertTrue([editModeEvaluator evaluate:scope], @"Expected the editModeEvaluator evaluator to return true");
    
    parameters = @{kAlfrescoConfigEvaluatorParameterMode: @"view"};
    AlfrescoFormModeEvaluator *viewModeEvaluator = [[AlfrescoFormModeEvaluator alloc]
                                                    initWithIdentifier:kAlfrescoConfigEvaluatorFormMode
                                                    parameters:parameters session:self.currentSession];
    XCTAssertFalse([viewModeEvaluator evaluate:scope], @"Expected the viewModeEvaluator evaluator to return false");
    
    self.lastTestSuccessful = YES;
    self.callbackCompleted = YES;
}

- (void)testRepoVersionEvaluatorConfig
{
    if (self.setUpSuccess)
    {
        if (!self.isCloud)
        {
            BOOL is42orAbove = NO;
            if (([self.currentSession.repositoryInfo.majorVersion intValue] == 4 && [self.currentSession.repositoryInfo.minorVersion intValue] >= 2) ||
                [self.currentSession.repositoryInfo.majorVersion intValue] >= 5)
            {
                is42orAbove = YES;
            }
            
            self.configService = [[AlfrescoConfigService alloc] initWithSession:[self sessionForConfigService]];
            
            // retrieve view config for specific view
            NSString *viewGroupConfigIdentifier = @"evaluator-test";
            [self.configService retrieveViewGroupConfigWithIdentifier:viewGroupConfigIdentifier completionBlock:^(AlfrescoViewGroupConfig *config, NSError *error) {
                if (config == nil)
                {
                    self.lastTestSuccessful = NO;
                    self.lastTestFailureMessage = [self failureMessageFromError:error];
                    self.callbackCompleted = YES;
                }
                else
                {
                    XCTAssertTrue([config.identifier isEqualToString:viewGroupConfigIdentifier],
                                  @"Expected view group config identifier to be %@ but it was %@", viewGroupConfigIdentifier, config.identifier);
                    XCTAssertTrue([config.label isEqualToString:@"Evaluator Test"],
                                  @"Expected view group label of 'Evaluator Test' but it was %@", config.label);
                    
                    XCTAssertNotNil(config.items, @"Expected items property to be populated");
                    
                    if (is42orAbove)
                    {
                        // we should get 2 items for 4.2 servers and above
                        XCTAssertTrue(config.items.count == 2, @"Expected there to be 2 items");
                    }
                    else
                    {
                        // we should get 1 item for older servers
                        XCTAssertTrue(config.items.count == 1, @"Expected there to be 1 item");
                    }
                    
                    // make sure the first item has the correct identifier
                    AlfrescoItemConfig *item1 = config.items[0];
                    XCTAssertTrue([item1.identifier isEqualToString:@"view-tasks"],
                                  @"Expected an identifier of 'view-tasks' but it was %@", item1.identifier);
                    
                    if (is42orAbove)
                    {
                        // make sure the third item has the correct identifier
                        AlfrescoItemConfig *item2 = config.items[1];
                        XCTAssertTrue([item2.identifier isEqualToString:@"view-my-repository-files"],
                                      @"Expected an identifier of 'view-my-repository-files' but it was %@", item2.identifier);
                        XCTAssertTrue([item2.type isEqualToString:@"com.alfresco.client.view.repository"],
                                      @"Expected a type of 'com.alfresco.client.view.repository' but it was %@", item2.type);
                    }
                    
                    self.lastTestSuccessful = YES;
                    self.callbackCompleted = YES;
                }
            }];
            
            [self waitUntilCompleteWithFixedTimeInterval];
            XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
        }
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testOtherEvaluatorConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceValidTests]];
        
        // create the scope object that should filter out all but one field
        NSDictionary *context1 = @{kAlfrescoConfigScopeContextFormMode: @"edit",
                                  kAlfrescoConfigScopeContextNode: [self documentWithAspects]};
        AlfrescoConfigScope *scope1 = [[AlfrescoConfigScope alloc] initWithProfile:@"custom" context:context1];
        
        [self.configService retrieveFormConfigWithIdentifier:@"evaluator-test" scope:scope1 completionBlock:^(AlfrescoFormConfig *config1, NSError *error1) {
            if (config1 == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error1];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertTrue([config1.identifier isEqualToString:@"evaluator-test"],
                              @"Expected form config identifier to be 'evaluator-test' but was %@", config1.identifier);
                XCTAssertTrue([config1.label isEqualToString:@"Evaluator Test"],
                              @"Expected form config label to be 'Evaluator Test' but was %@", config1.label);
                
                // if all the evaluators have worked there should only be one field
                XCTAssertTrue(config1.items.count == 1,
                              @"Expected there to be 1 item, but there were: %lu", (unsigned long)config1.items.count);
                
                // now make sure they all appear with the correct scope
                NSDictionary *context2 = @{kAlfrescoConfigScopeContextFormMode: @"view",
                                          kAlfrescoConfigScopeContextNode: [self customDocumentWithAspects]};
                AlfrescoConfigScope *scope2 = [[AlfrescoConfigScope alloc] initWithProfile:kAlfrescoConfigProfileDefaultIdentifier context:context2];
                
                [self.configService retrieveFormConfigWithIdentifier:@"evaluator-test" scope:scope2 completionBlock:^(AlfrescoFormConfig *config2, NSError *error2) {
                    if (config2 == nil)
                    {
                        self.lastTestSuccessful = NO;
                        self.lastTestFailureMessage = [self failureMessageFromError:error2];
                        self.callbackCompleted = YES;
                    }
                    else
                    {
                        // there should now be 5 fields present
                        XCTAssertTrue(config2.items.count == 5,
                                      @"Expected there to be 5 items, but there were: %lu", (unsigned long)config2.items.count);
                        
                        self.lastTestSuccessful = YES;
                        self.callbackCompleted = YES;
                    }
                }];
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

#pragma mark - Invalid config tests

- (void)testEmptyConfigFile
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceEmptyTest]];
        
        self.lastTestFailureMessage = @"Unexpected config was returned from an empty config file!";
        
        // make sure all config retrieval methods return nothing
        [self.configService retrieveConfigInfoWithCompletionBlock:^(AlfrescoConfigInfo *configInfo, NSError *configInfoError) {
            if (configInfo == nil)
            {
                [self.configService retrieveRepositoryConfigWithCompletionBlock:^(AlfrescoRepositoryConfig *repoConfig, NSError *repoConfigError) {
                    if (repoConfig == nil)
                    {
                        [self.configService retrieveFeatureConfigWithCompletionBlock:^(NSArray *featureConfig, NSError *featureConfigError) {
                            if (featureConfig.count == 0)
                            {
                                [self.configService retrieveCreationConfigWithCompletionBlock:^(AlfrescoCreationConfig *creationConfig, NSError *creationConfigError) {
                                    if (creationConfig != nil)
                                    {
                                        XCTAssertNil(creationConfig.creatableDocumentTypes, @"Expected creatable document types to be nil");
                                        XCTAssertNil(creationConfig.creatableFolderTypes, @"Expected creatable folder types to be nil");
                                        XCTAssertNil(creationConfig.creatableMimeTypes, @"Expected creatable mime types to be nil");
                                        
                                        [self.configService retrieveProfilesWithCompletionBlock:^(NSArray *profilesConfig, NSError *profilesConfigError) {
                                            if (profilesConfig != nil)
                                            {
                                                XCTAssertTrue(profilesConfig.count == 1,
                                                              @"Expected 1 profile but there were: %lu", (unsigned long)profilesConfig.count);
                                                AlfrescoProfileConfig *profile = profilesConfig.firstObject;
                                                XCTAssertTrue([profile.identifier isEqualToString:kAlfrescoConfigProfileDefaultIdentifier],
                                                              @"Expected the profile identifier to be '%@' but it was: %@",
                                                              kAlfrescoConfigProfileDefaultIdentifier, profile.identifier);
                                                XCTAssertTrue(profile.isDefault, @"Expected profile to be marked as the default profile");
                                                
                                                self.lastTestSuccessful = YES;
                                                self.callbackCompleted = YES;
                                            }
                                            else
                                            {
                                                self.callbackCompleted = YES;
                                            }
                                        }];
                                    }
                                    else
                                    {
                                        self.callbackCompleted = YES;
                                    }
                                }];
                            }
                            else
                            {
                                self.callbackCompleted = YES;
                            }
                        }];
                    }
                    else
                    {
                        self.callbackCompleted = YES;
                    }
                }];
            }
            else
            {
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testInvalidProfileConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceInvalidTests]];
        
        // retrieve an invalid profile
        [self.configService retrieveProfileWithIdentifier:@"invalid" completionBlock:^(AlfrescoProfileConfig *config, NSError *error) {
            
            XCTAssertNil(config, @"Expected config to be nil when retrieving an invalid profile");
            XCTAssertNil(error, @"Expected error to be nil when retrieving an invalid profile");
            
            self.lastTestSuccessful = YES;
            self.callbackCompleted = YES;
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testInvalidRepositoryConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceInvalidTests]];
        
        [self.configService retrieveRepositoryConfigWithCompletionBlock:^(AlfrescoRepositoryConfig *repoConfig, NSError *error) {
            if (repoConfig == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertNil(repoConfig.shareURL, @"Expected shareURL to be nil");
                XCTAssertNil(repoConfig.cmisURL, @"Expected cmisURL to be nil");
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testInvalidFeatureConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceInvalidTests]];
        
        // retrieve an invalid profile
        [self.configService retrieveFeatureConfigWithIdentifier:@"invalid" completionBlock:^(AlfrescoFeatureConfig *config, NSError *error) {
            
            XCTAssertNil(config, @"Expected config to be nil when retrieving an invalid feature");
            XCTAssertNil(error, @"Expected error to be nil when retrieving an invalid feature");
            
            self.lastTestSuccessful = YES;
            self.callbackCompleted = YES;
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testInvalidFeaturesConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceInvalidTests]];
        
        [self.configService retrieveFeatureConfigWithCompletionBlock:^(NSArray *array, NSError *error) {
            if (array == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertTrue(array.count == 0,
                              @"Expected no feature config to be returned but there were %lu", (unsigned long)array.count);
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testInvalidCreationConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceInvalidTests]];
        
        [self.configService retrieveCreationConfigWithCompletionBlock:^(AlfrescoCreationConfig *config, NSError *error) {
            if (config == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertNil(config.creatableDocumentTypes, @"Expected creatable document types to be nil");
                XCTAssertNil(config.creatableFolderTypes, @"Expected creatable folder types to be nil");
                XCTAssertNil(config.creatableMimeTypes, @"Expected creatable mime types to be nil");
                
                self.lastTestSuccessful = YES;
                self.callbackCompleted = YES;
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testInvalidViewConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceInvalidTests]];
        
        [self.configService retrieveViewConfigWithIdentifier:@"missing-view-type" completionBlock:^(AlfrescoViewConfig *config, NSError *error) {
            
            XCTAssertNil(config, @"Expected config to be nil when retrieving an invalid view");
            XCTAssertNil(error, @"Expected error to be nil when retrieving an invalid view");
            
            self.lastTestSuccessful = YES;
            self.callbackCompleted = YES;
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testInvalidViewGroupConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceInvalidTests]];
        
        [self.configService retrieveViewGroupConfigWithIdentifier:@"missing-references" completionBlock:^(AlfrescoViewGroupConfig *config1, NSError *error1) {
            if (config1 == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error1];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertTrue([config1.identifier isEqualToString:@"missing-references"],
                              @"Expected view group config identifier to be 'missing-references' but it was %@", config1.identifier);
                XCTAssertTrue(config1.items.count == 0,
                              @"Expected no items but there were %lu", (unsigned long)config1.items.count);
                
                [self.configService retrieveViewGroupConfigWithIdentifier:@"missing-items" completionBlock:^(AlfrescoViewGroupConfig *config2, NSError *error2) {
                    if (config2 == nil)
                    {
                        self.lastTestSuccessful = NO;
                        self.lastTestFailureMessage = [self failureMessageFromError:error2];
                        self.callbackCompleted = YES;
                    }
                    else
                    {
                        XCTAssertTrue([config2.identifier isEqualToString:@"missing-items"],
                                      @"Expected view group config identifier to be 'missing-items' but it was %@", config2.identifier);
                        XCTAssertTrue(config2.items.count == 0,
                                      @"Expected no items but there were %lu", (unsigned long)config2.items.count);
                        
                        self.lastTestSuccessful = YES;
                        self.callbackCompleted = YES;
                    }
                }];
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

- (void)testInvalidFormConfig
{
    if (self.setUpSuccess)
    {
        self.configService = [[AlfrescoConfigService alloc] initWithDictionary:[self dictionaryForConfigServiceInvalidTests]];
        
        [self.configService retrieveFormConfigWithIdentifier:@"missing-references" completionBlock:^(AlfrescoFormConfig *config1, NSError *error1) {
            if (config1 == nil)
            {
                self.lastTestSuccessful = NO;
                self.lastTestFailureMessage = [self failureMessageFromError:error1];
                self.callbackCompleted = YES;
            }
            else
            {
                XCTAssertTrue([config1.identifier isEqualToString:@"missing-references"],
                              @"Expected view group config identifier to be 'missing-references' but it was %@", config1.identifier);
                XCTAssertTrue(config1.items.count == 0,
                              @"Expected no items but there were %lu", (unsigned long)config1.items.count);
                
                [self.configService retrieveFormConfigWithIdentifier:@"missing-items" completionBlock:^(AlfrescoFormConfig *config2, NSError *error2) {
                    if (config2 == nil)
                    {
                        self.lastTestSuccessful = NO;
                        self.lastTestFailureMessage = [self failureMessageFromError:error2];
                        self.callbackCompleted = YES;
                    }
                    else
                    {
                        XCTAssertTrue([config2.identifier isEqualToString:@"missing-items"],
                                      @"Expected form config identifier to be 'missing-items' but it was %@", config2.identifier);
                        XCTAssertTrue(config2.items.count == 0,
                                      @"Expected no items but there were %lu", (unsigned long)config2.items.count);
                        
                        self.lastTestSuccessful = YES;
                        self.callbackCompleted = YES;
                    }
                }];
            }
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

@end

/*
 ******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

#import "AlfrescoClientBasedConfigService.h"
#import "AlfrescoErrors.h"
#import "AlfrescoPropertyConstants.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoObjectConverter.h"
#import "AlfrescoDocumentFolderService.h"
#import "AlfrescoProfileConfigHelper.h"
#import "AlfrescoFeatureConfigHelper.h"
#import "AlfrescoCreationConfigHelper.h"
#import "AlfrescoViewConfigHelper.h"
#import "AlfrescoFormConfigHelper.h"
#import "AlfrescoConfigEvaluator.h"
#import "AlfrescoLog.h"

/**
 * Configuration service implementation
 */
@interface AlfrescoClientBasedConfigService ()
@property (nonatomic, strong, readwrite) AlfrescoConfigScope *defaultConfigScope;

@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, assign) BOOL isCacheBuilt;
@property (nonatomic, assign) BOOL isCacheBuilding;
@property (nonatomic, strong) NSString *applicationId;
@property (nonatomic, strong) NSURL *localFileURL;

// cached configuration
@property (nonatomic, strong) NSBundle *stringsBundle;
@property (nonatomic, strong) NSDictionary *evaluators;
@property (nonatomic, strong) AlfrescoConfigInfo *configInfo;
@property (nonatomic, strong) AlfrescoRepositoryConfig *repositoryConfig;

// config helpers
@property (nonatomic, strong) AlfrescoProfileConfigHelper *profileConfigHelper;
@property (nonatomic, strong) AlfrescoFeatureConfigHelper *featureConfigHelper;
@property (nonatomic, strong) AlfrescoCreationConfigHelper *creationConfigHelper;
@property (nonatomic, strong) AlfrescoViewConfigHelper *viewConfigHelper;
@property (nonatomic, strong) AlfrescoFormConfigHelper *formConfigHelper;

@end

@implementation AlfrescoClientBasedConfigService

@dynamic defaultConfigScope;

#pragma mark - Initialization methods

- (instancetype)initWithSession:(id<AlfrescoSession>)session
{
    // we can't do much without a session so just return nil
    if (session == nil)
    {
        return nil;
    }
    
    self = [super init];
    if (nil != self)
    {
        self.session = session;
        self.isCacheBuilt = NO;
        self.isCacheBuilding = NO;
        self.defaultConfigScope = [[AlfrescoConfigScope alloc] initWithProfile:kAlfrescoConfigProfileDefaultIdentifier];
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)parameters
{
    self = [super init];
    if (nil != self)
    {
        self.parameters = parameters;
        self.isCacheBuilt = NO;
        self.isCacheBuilding = NO;
        self.defaultConfigScope = [[AlfrescoConfigScope alloc] initWithProfile:kAlfrescoConfigProfileDefaultIdentifier];
    }
    
    return self;
}

- (void)clear
{
    self.isCacheBuilt = NO;
}

- (AlfrescoRequest *)initializeInternalStateWithCompletionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    if (!self.isCacheBuilding)
    {
        self.isCacheBuilding = YES;
        
        if (self.session != nil)
        {
            // pull parameters from session
            self.applicationId = [self.session objectForParameter:kAlfrescoConfigServiceParameterApplicationId];
            
            // TODO: use the internal non localised path, this may require us to use a query
            NSString *configPath = [NSString stringWithFormat:@"/Data Dictionary/Client Configuration/%@/config.json", self.applicationId];
            
            // retrieve the configuration content
            AlfrescoDocumentFolderService *docFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
            AlfrescoRequest *request = nil;
            request = [docFolderService retrieveNodeWithFolderPath:configPath completionBlock:^(AlfrescoNode *configNode, NSError *retrieveNodeError) {
                if (configNode != nil)
                {
                    AlfrescoRequest *contentRequest = [docFolderService retrieveContentOfDocument:(AlfrescoDocument*)configNode completionBlock:^(AlfrescoContentFile *contentFile, NSError *retrieveContentError) {
                        if (configNode != nil)
                        {
                            // TODO: pull all *.strings files from the server's Messages folder and create a bundle from them
                            //self.stringsBundle = [self processRemoteMessageFiles:completionBlock];
                            
                            AlfrescoLogDebug(@"Attempting to read configuration from %@", contentFile.fileUrl.path);
                            
                            // process the JSON
                            [self processJSONData:[NSData dataWithContentsOfFile:contentFile.fileUrl.path]
                                  completionBlock:completionBlock];
                        }
                        else
                        {
                            completionBlock(NO, [AlfrescoErrors alfrescoErrorWithUnderlyingError:retrieveContentError
                                                                            andAlfrescoErrorCode:kAlfrescoErrorCodeConfigInitializationFailed]);
                        }
                    } progressBlock:nil];
                    
                    request.httpRequest = contentRequest.httpRequest;
                }
                else
                {
                    completionBlock(NO, [AlfrescoErrors alfrescoErrorWithUnderlyingError:retrieveNodeError
                                                                    andAlfrescoErrorCode:kAlfrescoErrorCodeConfigInitializationFailed]);
                }
            }];
            
            return request;
        }
        else
        {
            // pull parameters from dictionary
            self.applicationId = self.parameters[kAlfrescoConfigServiceParameterApplicationId];
            NSString *configFolder = self.parameters[kAlfrescoConfigServiceParameterFolder];
            NSString *configFileName = self.parameters[kAlfrescoConfigServiceParameterFileName];
            if (configFileName == nil)
            {
                configFileName = kAlfrescoConfigServiceDefaultFileName;
            }
            
            // strip the extension from the config file name
            NSString* configFileNameWithoutExtension = [[configFileName lastPathComponent] stringByDeletingPathExtension];
            
            // build paths to config json and bundle
            NSString *configFilePath = [NSString stringWithFormat:@"%@/%@", configFolder, configFileName];
            NSString *bundleFilePath = [NSString stringWithFormat:@"%@/%@.bundle", configFolder, configFileNameWithoutExtension];
            
            AlfrescoLogDebug(@"Attempting to load bundle from %@", bundleFilePath);
            
            // try and load the bundle holding the strings
            self.stringsBundle = [NSBundle bundleWithPath:bundleFilePath];
            
            AlfrescoLogDebug(@"Attempting to read configuration from %@", configFilePath);
            
            // process the JSON data from the local file
            [self processJSONData:[NSData dataWithContentsOfFile:configFilePath]
                  completionBlock:completionBlock];
            
            return nil;
        }
    }
    else
    {
        // TODO: handle concurrent requests, for now fail so we explicitly highlight concurrency issues
        completionBlock(NO, [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeConfigInitializationFailed
                                                                        reason:@"Request to initialize config whilst cache is being built"]);
        return nil;
    }
}

- (void)processJSONData:(NSData *)data completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    if (data != nil)
    {
        // parse the JSON
        NSError *error = nil;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (jsonDictionary != nil)
        {
            // build internal state
            [self parseEvaluators:jsonDictionary];
            [self parseConfigInfo:jsonDictionary];
            [self parseRepositoryConfig:jsonDictionary];
            
            self.profileConfigHelper = [[AlfrescoProfileConfigHelper alloc] initWithJSON:jsonDictionary bundle:self.stringsBundle evaluators:self.evaluators];
            [self.profileConfigHelper parse];
            
            self.featureConfigHelper = [[AlfrescoFeatureConfigHelper alloc] initWithJSON:jsonDictionary bundle:self.stringsBundle evaluators:self.evaluators];
            [self.featureConfigHelper parse];
            
            self.creationConfigHelper = [[AlfrescoCreationConfigHelper alloc] initWithJSON:jsonDictionary bundle:self.stringsBundle evaluators:self.evaluators];
            [self.creationConfigHelper parse];
            
            self.viewConfigHelper = [[AlfrescoViewConfigHelper alloc] initWithJSON:jsonDictionary bundle:self.stringsBundle evaluators:self.evaluators];
            [self.viewConfigHelper parse];
            
            self.formConfigHelper = [[AlfrescoFormConfigHelper alloc] initWithJSON:jsonDictionary bundle:self.stringsBundle evaluators:self.evaluators];
            [self.formConfigHelper parse];
            
            // TODO: Determine if we fail if anything mandatory is missing i.e. configInfo?
            
            // set status flags and call completion block
            self.isCacheBuilt = YES;
            self.isCacheBuilding = NO;
            completionBlock(YES, nil);
        }
        else
        {
            self.isCacheBuilding = NO;
            completionBlock(NO, [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing]);
        }
    }
    else
    {
        self.isCacheBuilding = NO;
        completionBlock(NO, [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData]);
    }
}

- (void)parseEvaluators:(NSDictionary *)json
{
    NSMutableDictionary *evaluators = [NSMutableDictionary dictionary];
    
    NSDictionary *configEvaluators = json[kAlfrescoJSONEvaluators];
    for (NSString *evaluatorId in [configEvaluators allKeys])
    {
        NSDictionary *evaluatorJSON = configEvaluators[evaluatorId];
        
        NSString *type = evaluatorJSON[kAlfrescoJSONType];
        NSArray *matchAny = evaluatorJSON[kAlfrescoJSONMatchAny];
        NSArray *matchAll = evaluatorJSON[kAlfrescoJSONMatchAll];
        NSDictionary *parameters = evaluatorJSON[kAlfrescoJSONParams];
        
        // make sure either type OR matchXYZ is present
        if (type != nil && (matchAll != nil || matchAny != nil))
        {
            AlfrescoLogWarning(@"Ignoring evaluator with identifier '%@' as both type and match properties are present", evaluatorId);
            continue;
        }
        // and make sure both match operators are not present
        else if (matchAll != nil && matchAny != nil)
        {
            AlfrescoLogWarning(@"Ignoring evaluator with identifier '%@' as both match properties are present", evaluatorId);
            continue;
        }
        
        // create an instance of the appropriate evaluator class from the JSON with the given parameters
        id<AlfrescoConfigEvaluator> evaluator = nil;
        
        if (type != nil)
        {
            if ([type isEqualToString:kAlfrescoConfigEvaluatorRepositoryVersion])
            {
                evaluator = [[AlfrescoRepositoryVersionEvaluator alloc] initWithIdentifier:evaluatorId
                                                                                parameters:parameters
                                                                                   session:self.session];
            }
            else if ([type isEqualToString:kAlfrescoConfigEvaluatorNodeType])
            {
                evaluator = [[AlfrescoNodeTypeEvaluator alloc] initWithIdentifier:evaluatorId
                                                                       parameters:parameters
                                                                          session:self.session];
            }
            else if ([type isEqualToString:kAlfrescoConfigEvaluatorAspect])
            {
                evaluator = [[AlfrescoAspectEvaluator alloc] initWithIdentifier:evaluatorId
                                                                     parameters:parameters
                                                                        session:self.session];
            }
            else if ([type isEqualToString:kAlfrescoConfigEvaluatorFormMode])
            {
                evaluator = [[AlfrescoFormModeEvaluator alloc] initWithIdentifier:evaluatorId
                                                                       parameters:parameters
                                                                          session:self.session];
            }
            else if ([type isEqualToString:kAlfrescoConfigEvaluatorProfile])
            {
                evaluator = [[AlfrescoProfileEvaluator alloc] initWithIdentifier:evaluatorId
                                                                      parameters:parameters
                                                                         session:self.session];
            }
        }
        else if (matchAny != nil)
        {
            parameters = @{kAlfrescoConfigEvaluatorParameterEvaluatorIds: matchAny,
                           kAlfrescoConfigEvaluatorParameterMatchAll: @(NO)};
            
            evaluator = [[AlfrescoMatchEvaluator alloc] initWithIdentifier:evaluatorId
                                                                   parameters:parameters
                                                                      session:self.session];
        }
        else if (matchAll != nil)
        {
            parameters = @{kAlfrescoConfigEvaluatorParameterEvaluatorIds: matchAll,
                           kAlfrescoConfigEvaluatorParameterMatchAll: @(YES)};
            
            evaluator = [[AlfrescoMatchEvaluator alloc] initWithIdentifier:evaluatorId
                                                                   parameters:parameters
                                                                      session:self.session];
        }
        
        // add the evaluator to the dictionary
        if (evaluator != nil)
        {
            evaluators[evaluatorId] = evaluator;
            AlfrescoLogDebug(@"Stored config for evaluator with id: %@", evaluatorId);
        }
        else
        {
            AlfrescoLogWarning(@"Unrecognised evaluator type: %@", type);
        }
    }
    
    self.evaluators = evaluators;
}

- (void)parseConfigInfo:(NSDictionary *)json
{
    NSDictionary *configInfoJSON = json[kAlfrescoJSONInfo];
    if (configInfoJSON != nil)
    {
        NSNumber *schemaVersion = configInfoJSON[kAlfrescoJSONSchemaVersion];
        if (schemaVersion != nil)
        {
            self.configInfo = [[AlfrescoConfigInfo alloc] initWithDictionary:@{kAlfrescoConfigInfoPropertySchemaVersion: schemaVersion}];
        }
    }
}

- (void)parseRepositoryConfig:(NSDictionary *)json
{
    NSDictionary *repositoryJSON = json[kAlfrescoJSONRepository];
    if (repositoryJSON != nil)
    {
        NSMutableDictionary *repositoryProperties = [NSMutableDictionary dictionary];
        
        NSString *shareURL = repositoryJSON[kAlfrescoJSONShareURL];
        if (shareURL != nil)
        {
            repositoryProperties[kAlfrescoRepositoryConfigPropertyShareURL] = shareURL;
        }
        
        NSString *cmisURL = repositoryJSON[kAlfrescoJSONCMISURL];
        if (cmisURL != nil)
        {
            repositoryProperties[kAlfrescoRepositoryConfigPropertyCMISURL] = cmisURL;
        }

        self.repositoryConfig = [[AlfrescoRepositoryConfig alloc] initWithDictionary:repositoryProperties];
    }
}

#pragma mark - Retrieval methods

- (AlfrescoRequest *)retrieveConfigInfoWithCompletionBlock:(AlfrescoConfigInfoCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock(self.configInfo, nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}

- (AlfrescoRequest *)retrieveDefaultProfileWithCompletionBlock:(AlfrescoProfileConfigCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock(self.profileConfigHelper.defaultProfile, nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}

- (AlfrescoRequest *)retrieveProfileWithIdentifier:(NSString *)identifier
                                   completionBlock:(AlfrescoProfileConfigCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock([self.profileConfigHelper profileConfigForIdentifier:identifier], nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}


- (AlfrescoRequest *)retrieveProfilesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock(self.profileConfigHelper.profiles, nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}


- (AlfrescoRequest *)retrieveRepositoryConfigWithCompletionBlock:(AlfrescoRepositoryConfigCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock(self.repositoryConfig, nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}


- (AlfrescoRequest *)retrieveFeatureConfigWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    return [self retrieveFeatureConfigWithConfigScope:self.defaultConfigScope completionBlock:completionBlock];
}


- (AlfrescoRequest *)retrieveFeatureConfigWithConfigScope:(AlfrescoConfigScope *)scope
                                          completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock([self.featureConfigHelper featureConfigWithScope:scope], nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}


- (AlfrescoRequest *)retrieveFeatureConfigWithIdentifier:(NSString *)identifier
                                         completionBlock:(AlfrescoFeatureConfigCompletionBlock)completionBlock
{
    return [self retrieveFeatureConfigWithIdentifier:identifier scope:self.defaultConfigScope completionBlock:completionBlock];
}


- (AlfrescoRequest *)retrieveFeatureConfigWithIdentifier:(NSString *)identifier
                                                   scope:(AlfrescoConfigScope *)scope
                                         completionBlock:(AlfrescoFeatureConfigCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock([self.featureConfigHelper featureConfigForIdentifier:identifier scope:scope], nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}

- (AlfrescoRequest *)retrieveViewConfigWithIdentifier:(NSString *)identifier
                                      completionBlock:(AlfrescoViewConfigCompletionBlock)completionBlock
{
    return [self retrieveViewConfigWithIdentifier:identifier scope:self.defaultConfigScope completionBlock:completionBlock];
}

- (AlfrescoRequest *)retrieveViewConfigWithIdentifier:(NSString *)identifier
                                                scope:(AlfrescoConfigScope *)scope
                                      completionBlock:(AlfrescoViewConfigCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock([self.viewConfigHelper viewConfigForIdentifier:identifier], nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}


- (AlfrescoRequest *)retrieveViewGroupConfigWithIdentifier:(NSString *)identifier
                                           completionBlock:(AlfrescoViewGroupConfigCompletionBlock)completionBlock
{
    return [self retrieveViewGroupConfigWithIdentifier:identifier scope:self.defaultConfigScope completionBlock:completionBlock];
}


- (AlfrescoRequest *)retrieveViewGroupConfigWithIdentifier:(NSString *)identifier
                                                     scope:(AlfrescoConfigScope *)scope
                                           completionBlock:(AlfrescoViewGroupConfigCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock([self.viewConfigHelper viewGroupConfigForIdentifier:identifier scope:scope], nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}

- (AlfrescoRequest *)retrieveFormConfigWithIdentifier:(NSString *)identifier
                                      completionBlock:(AlfrescoFormConfigCompletionBlock)completionBlock
{
    return [self retrieveFormConfigWithIdentifier:identifier scope:self.defaultConfigScope completionBlock:completionBlock];
}


- (AlfrescoRequest *)retrieveFormConfigWithIdentifier:(NSString *)identifier
                                                scope:(AlfrescoConfigScope *)scope
                                      completionBlock:(AlfrescoFormConfigCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock([self.formConfigHelper formConfigForIdentifier:identifier scope:scope], nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}


- (AlfrescoRequest *)retrieveCreationConfigWithCompletionBlock:(AlfrescoCreationConfigCompletionBlock)completionBlock
{
    return [self retrieveCreationConfigWithConfigScope:self.defaultConfigScope completionBlock:completionBlock];
}


- (AlfrescoRequest *)retrieveCreationConfigWithConfigScope:(AlfrescoConfigScope *)scope
                                           completionBlock:(AlfrescoCreationConfigCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock([self.creationConfigHelper creationConfigWithScope:scope], nil);
        }
        else
        {
            completionBlock(nil, error);
        }
    }];
}

@end

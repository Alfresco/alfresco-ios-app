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

#import "AlfrescoClientBasedConfigService.h"
#import "AlfrescoSDKInternalConstants.h"
#import "AlfrescoConfigPropertyConstants.h"
#import "AlfrescoConfigInternalConstants.h"
#import "AlfrescoProfileConfigHelper.h"
#import "AlfrescoFeatureConfigHelper.h"
#import "AlfrescoCreationConfigHelper.h"
#import "AlfrescoViewConfigHelper.h"
#import "AlfrescoFormConfigHelper.h"
#import "AlfrescoConfigEvaluator.h"

/**
 * Configuration service implementation
 */
@interface AlfrescoClientBasedConfigService ()
@property (nonatomic, strong, readwrite) AlfrescoConfigScope *defaultConfigScope;

//@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, assign) BOOL isCacheBuilt;
@property (nonatomic, assign) BOOL isCacheBuilding;
@property (nonatomic, strong) NSMutableArray *queuedCompletionBlocks;

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

@property (nonatomic, assign) BOOL isUsingCacheData;

@end

@implementation AlfrescoClientBasedConfigService

@dynamic defaultConfigScope;

#pragma mark - Initialization methods

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.isCacheBuilt = NO;
        self.isCacheBuilding = NO;
        self.shouldIgnoreRequests = NO;
        self.defaultConfigScope = [[AlfrescoConfigScope alloc] initWithProfile:kAlfrescoConfigProfileDefaultIdentifier];
        self.queuedCompletionBlocks = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
    }
    return self;
}

- (instancetype)initWithSession:(id<AlfrescoSession>)session
{
    // we can't do much without a session so just return nil
    if (session == nil)
    {
        return nil;
    }
    
    self = [self init];
    if (self)
    {
        self.session = session;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)parameters
{
    self = [self init];
    if (self)
    {
        self.parameters = parameters;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods
- (void)sessionReceived:(NSNotification *)notification
{
    self.session = notification.object;
}

- (void)clear
{
    self.isCacheBuilt = NO;
    self.isCacheBuilding = NO;
}

- (void)queueCompletionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [self.queuedCompletionBlocks addObject:completionBlock];
}

- (void)runAndDequeueAllCompletionBlocksWithSuccess:(BOOL)success error:(NSError *)error
{
    NSArray *completionBlocks = self.queuedCompletionBlocks.copy;
    
    for (AlfrescoBOOLCompletionBlock block in completionBlocks)
    {
        block(success, error);
        [self.queuedCompletionBlocks removeObject:block];
    }
}

- (AlfrescoRequest *)initializeInternalStateWithCompletionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    if (self.isCacheBuilt)
    {
        if (completionBlock != NULL)
        {
            completionBlock(YES, nil);
        }
        return nil;
    }
    
    if (!self.isCacheBuilding)
    {
        self.isCacheBuilding = YES;
        
        void (^runAllCompletionBlocks)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
            self.isCacheBuilding = NO;
            completionBlock(success, error);
            [self runAndDequeueAllCompletionBlocksWithSuccess:success error:error];
        };
        
        if (self.session != nil && self.shouldIgnoreRequests == NO)
        {
            AlfrescoRequest *request = nil;
            AlfrescoSearchService *searchService = [[AlfrescoSearchService alloc] initWithSession:self.session];
            request = [searchService searchWithStatement:kAlfrescoConfigApplicationDirectoryCMISSearchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *appDirectoryContents, NSError *applicationDirectoryError) {
                if (applicationDirectoryError)
                {
                    runAllCompletionBlocks(NO, [AlfrescoErrors alfrescoErrorWithUnderlyingError:applicationDirectoryError andAlfrescoErrorCode:kAlfrescoErrorCodeConfigInitializationFailed]);
                }
                else
                {
                    AlfrescoFolder *dataDictionaryFolder = appDirectoryContents.firstObject;
                    if (dataDictionaryFolder)
                    {
                        // Determine path components
                        NSMutableArray *pathComponents = [NSMutableArray array];
                        /// Add the localised Data Dictionary name
                        [pathComponents addObject:dataDictionaryFolder.name];
                        [pathComponents addObject:kAlfrescoConfigFolderPathToConfigFileRelativeToApplicationDirectory];
                        /// Pull parameters from session
                        NSString *applicationId = [self.session objectForParameter:kAlfrescoConfigServiceParameterApplicationId];
                        if (applicationId)
                        {
                            [pathComponents addObject:applicationId];
                        }
                        /// Add the file name
                        [pathComponents addObject:kAlfrescoConfigServiceDefaultFileName];
                        
                        // Build the full path
                        NSString *configurationFileLocationOnServer = [self buildPathFromPathComponents:pathComponents];
                        
                        // Retrieve the configuration content
                        AlfrescoDocumentFolderService *docFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
                        AlfrescoRequest *nodeRequest = [docFolderService retrieveNodeWithFolderPath:configurationFileLocationOnServer completionBlock:^(AlfrescoNode *configNode, NSError *retrieveNodeError) {
                            if (configNode != nil)
                            {
                                // Has the user provided a location for the configuration file to live?
                                NSString *configDestinationFolderPath = [self.session objectForParameter:kAlfrescoConfigServiceParameterFolder];
                                if (!configDestinationFolderPath)
                                {
                                    configDestinationFolderPath = NSTemporaryDirectory();
                                }
                                
                                NSString *completeFileConfigPath = [configDestinationFolderPath stringByAppendingPathComponent:kAlfrescoConfigServiceDefaultFileName];
                                
                                // Check to see if the file has been modified on the server
                                NSError *attributesError = nil;
                                NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:completeFileConfigPath error:&attributesError];
                                
                                if (attributesError)
                                {
                                    AlfrescoLogError(@"Unable to retrieve attributes for file at path: %@", completeFileConfigPath);
                                }
                                
                                // Only initiate the download if required
                                if (![attributes.fileModificationDate isEqualToDate:configNode.modifiedAt])
                                {
                                    self.isUsingCacheData = NO;
                                    
                                    NSString *temporaryFileConfigPath = [configDestinationFolderPath stringByAppendingPathComponent:kAlfrescoConfigServiceTemporaryFileName];
                                    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:temporaryFileConfigPath append:NO];
                                    
                                    AlfrescoRequest *contentRequest = [docFolderService retrieveContentOfDocument:(AlfrescoDocument *)configNode outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *downloadError) {
                                        if (succeeded)
                                        {
                                            // TODO: pull all *.strings files from the server's Messages folder and create a bundle from them
                                            //self.stringsBundle = [self processRemoteMessageFiles:completionBlock];
                                            
                                            AlfrescoLogDebug(@"Attempting to read configuration from %@", completeFileConfigPath);
                                            
                                            NSError *updateAttributesError = nil;
                                            NSDictionary *updatedAttributes = @{NSFileModificationDate : configNode.modifiedAt};
                                            [[NSFileManager defaultManager] setAttributes:updatedAttributes ofItemAtPath:temporaryFileConfigPath error:&updateAttributesError];
                                            
                                            if (updateAttributesError)
                                            {
                                                AlfrescoLogError(@"Unable to set the attributes: %@ on file at path: %@", updatedAttributes, completeFileConfigPath);
                                            }
                                            
                                            // process the JSON
                                            [self processJSONData:[NSData dataWithContentsOfFile:temporaryFileConfigPath] completionBlock:^(BOOL succeeded, NSError *error) {
                                                // Notify processing is complete
                                                if (succeeded)
                                                {
                                                    // delete old config file
                                                    if ([[AlfrescoFileManager sharedManager] fileExistsAtPath:completeFileConfigPath])
                                                    {
                                                        NSError *deleteError;
                                                        [[AlfrescoFileManager sharedManager] removeItemAtPath:completeFileConfigPath error:&deleteError];
                                                    }
                                                    
                                                    // copy temp config file to it's final path
                                                    NSError *copyError;
                                                    [[AlfrescoFileManager sharedManager] copyItemAtPath:temporaryFileConfigPath toPath:completeFileConfigPath error:&copyError];
                                                    
                                                    // remove temp config file
                                                    if (copyError == nil)
                                                    {
                                                        NSError *deleteError;
                                                        [[AlfrescoFileManager sharedManager] removeItemAtPath:temporaryFileConfigPath error:&deleteError];
                                                        
                                                        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigNewConfigRetrievedFromServerNotification object:nil];
                                                    }
                                                    
                                                    runAllCompletionBlocks(succeeded, error);
                                                }
                                                else
                                                {
                                                    // remove temp config file
                                                    NSError *deleteError;
                                                    [[AlfrescoFileManager sharedManager] removeItemAtPath:temporaryFileConfigPath error:&deleteError];
                                                    
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigBadConfigRetrievedFromServerNotification object:error];
                                                    
                                                    if ([[AlfrescoFileManager sharedManager] fileExistsAtPath:completeFileConfigPath])
                                                    {
                                                        runAllCompletionBlocks(YES, nil);
                                                    }
                                                    else
                                                    {
                                                        runAllCompletionBlocks(NO, error);
                                                    }
                                                }
                                            }];
                                        }
                                        else
                                        {
                                            runAllCompletionBlocks(NO, downloadError);
                                        }
                                    } progressBlock:nil];
                                    
                                    request.httpRequest = contentRequest.httpRequest;
                                }
                                else
                                {
                                    self.isUsingCacheData = YES;
                                    // Process the file we have cached
                                    [self processJSONData:[NSData dataWithContentsOfFile:completeFileConfigPath] completionBlock:runAllCompletionBlocks];
                                }
                            }
                            else
                            {
                                runAllCompletionBlocks(NO, retrieveNodeError);
                            }
                        }];
                        
                        request.httpRequest = nodeRequest.httpRequest;
                        
                    }
                    else
                    {
                        runAllCompletionBlocks(NO, [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeRequestedNodeNotFound]);
                    }
                }
            }];
            
            return request;
        }
        else
        {
            // pull parameters from dictionary
//            NSString *applicationId = self.parameters[kAlfrescoConfigServiceParameterApplicationId];
            NSString *configFolder = self.parameters[kAlfrescoConfigServiceParameterFolder];
            NSString *configFileName = self.parameters[kAlfrescoConfigServiceParameterFileName];
            if (configFileName == nil)
            {
                configFileName = kAlfrescoConfigServiceDefaultFileName;
            }
            
            // strip the extension from the config file name
            NSString *configFileNameWithoutExtension = [[configFileName lastPathComponent] stringByDeletingPathExtension];
            
            // build paths to config json and bundle
            NSString *configFilePath = [NSString stringWithFormat:@"%@/%@", configFolder, configFileName];
            NSString *bundleFilePath = [NSString stringWithFormat:@"%@/%@.bundle", configFolder, configFileNameWithoutExtension];
            
            AlfrescoLogDebug(@"Attempting to load bundle from %@", bundleFilePath);
            
            // try and load the bundle holding the strings
            self.stringsBundle = [NSBundle bundleWithPath:bundleFilePath];
            
            AlfrescoLogDebug(@"Attempting to read configuration from %@", configFilePath);
            
            // process the JSON data from the local file
            [self processJSONData:[NSData dataWithContentsOfFile:configFilePath] completionBlock:runAllCompletionBlocks];
            
            return nil;
        }
    }
    else
    {
        // Queue any requests that are made whilst the cache is built.
        [self queueCompletionBlock:completionBlock];
        return nil;
    }
}

- (void)processJSONData:(NSData *)data completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    // Parsing takes a while so dispatch this work onto a background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
                
                if (completionBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionBlock(YES, nil);
                    });
                }
            }
            else
            {
                self.isCacheBuilding = NO;
                
                if (completionBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionBlock(NO, [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing]);
                    });
                }
            }
        }
        else
        {
            self.isCacheBuilding = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(NO, [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData]);
            });
        }
    });
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
            if ([type isEqualToString:kAlfrescoConfigEvaluatorRepositoryCapability])
            {
                evaluator = [[AlfrescoRepositoryCapabilitiesEvaluator alloc] initWithIdentifier:evaluatorId
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
            else if ([type isEqualToString:kAlfrescoConfigEvaluatorIsUser])
            {
                evaluator = [[AlfrescoIsUserEvaluator alloc] initWithIdentifier:evaluatorId
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

- (NSString *)buildPathFromPathComponents:(NSArray *)pathComponents
{
    NSString *returnString = @"/";
    for (NSString *pathComponent in pathComponents)
    {
        returnString = [returnString stringByAppendingPathComponent:pathComponent];
    }
    
    return returnString;
}

#pragma mark - Retrieval Public Methods

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
        if (completionBlock)
        {
            if (succeeded)
            {
                completionBlock(self.profileConfigHelper.defaultProfile, nil);
            }
            else
            {
                completionBlock(nil, error);
            }
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

- (AlfrescoRequest *)retrieveFeatureConfigWithType:(NSString *)type
                                   completionBlock:(AlfrescoFeatureConfigCompletionBlock)completionBlock
{
    return [self retrieveFeatureConfigWithType:type scope:self.defaultConfigScope completionBlock:completionBlock];
}

- (AlfrescoRequest *)retrieveFeatureConfigWithType:(NSString *)type
                                             scope:(AlfrescoConfigScope *)scope
                                   completionBlock:(AlfrescoFeatureConfigCompletionBlock)completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            completionBlock([self.featureConfigHelper featureConfigForType:type scope:scope], nil);
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

- (AlfrescoRequest *)retrieveViewConfigsWithIdentifiers:(NSArray *)identifiers
                                      completionBlock:(AlfrescoViewConfigsCompletionBlock)completionBlock
{
    return [self retrieveViewConfigsWithIdentifiers:identifiers scope:self.defaultConfigScope completionBlock:completionBlock];
}

- (AlfrescoRequest *)retrieveViewConfigsWithIdentifiers:(NSArray *)identifiers
                                                  scope:(AlfrescoConfigScope *)scope
                                        completionBlock:(AlfrescoViewConfigsCompletionBlock)completionBlock
{
    __weak typeof(self) weakSelf = self;
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if(succeeded)
        {
            __strong typeof(self) strongSelf = weakSelf;
            NSMutableArray *configs = [NSMutableArray new];
            for(NSString *identifier in identifiers)
            {
                AlfrescoViewConfig *config = [strongSelf.viewConfigHelper viewConfigForIdentifier:identifier];
                if (config)
                {
                    [configs addObject:config];
                }
            }
            completionBlock(configs, nil);
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

- (BOOL)isViewType:(NSString *)viewType presentInViewGroupConfig:(AlfrescoViewGroupConfig *)viewGroupConfig
{
    BOOL returnValue = NO;
    for (AlfrescoItemConfig *subItem in viewGroupConfig.items)
    {
        if ([subItem isKindOfClass:[AlfrescoViewGroupConfig class]])
        {
            AlfrescoViewGroupConfig *subItemViewGroupConfig = (AlfrescoViewGroupConfig *)subItem;
            returnValue = [self isViewType:viewType presentInViewGroupConfig:subItemViewGroupConfig];
            if(returnValue)
            {
                break;
            }
        }
        else if ([subItem isKindOfClass:[AlfrescoViewConfig class]])
        {
            AlfrescoViewConfig *subItemViewConfig = (AlfrescoViewConfig *)subItem;
            if([subItemViewConfig.type isEqualToString:viewType])
            {
                returnValue = YES;
                break;
            }
        }
    }
    return returnValue;
}

- (AlfrescoRequest *)isViewWithType:(NSString *)viewType presentInProfile:(AlfrescoProfileConfig *)profile completionBlock:(void (^)(BOOL isViewPresent, NSError *error))completionBlock
{
    return [self initializeInternalStateWithCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            NSString *viewIdentifier = [self.viewConfigHelper viewIdentifierForViewType:viewType];
            if(viewIdentifier)
            {
                if([profile.rootViewId isEqualToString:viewIdentifier])
                {
                    // profile has only sync as root view
                    // sync should be enabled
                    completionBlock(YES, nil);
                }
                else
                {
                    AlfrescoViewGroupConfig *viewGroupConfig = [self.viewConfigHelper viewGroupConfigForIdentifier:profile.rootViewId scope:self.defaultConfigScope];
                    if(viewGroupConfig)
                    {
                        BOOL isViewTypePresent = [self isViewType:viewType presentInViewGroupConfig:viewGroupConfig];
                        // sync should be enabled/disabled based on bool
                        completionBlock(isViewTypePresent, nil);
                    }
                    else
                    {
                        // view group is not found - sync should stay as it is
                        // should return error
                        completionBlock(NO, [NSError new]);
                    }
                }
            }
            else
            {
                // view type was not found in the views config section
                // should disable sync
                completionBlock(NO, nil);
            }
        }
        else
        {
            // should return error
            completionBlock(NO, error);
        }
    }];
}

- (BOOL)isUsingCachedData
{
    return self.isUsingCacheData;
}

@end

/*******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
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

#import "AlfrescoCloudSession.h"
#import "CMISSession.h"
#import "CMISRepositoryService.h"
#import "CMISRepositoryInfo.h"
#import "CMISDateUtil.h"
#import "AlfrescoCMISToAlfrescoObjectConverter.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoErrors.h"
#import "AlfrescoCloudNetwork.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoOAuthData.h"
#import "AlfrescoOAuthAuthenticationProvider.h"
#import "AlfrescoCMISPassThroughAuthenticationProvider.h"
#import "AlfrescoCMISObjectConverter.h"
#import "AlfrescoDefaultNetworkProvider.h"
#import "AlfrescoLog.h"
#import "CMISLog.h"
#import <objc/runtime.h>

@interface AlfrescoCloudSession ()

- (id)initWithParameters:(NSDictionary *)parameters;

- (AlfrescoRequest *)authenticateWithEmailAddress:(NSString *)emailAddress
                                         password:(NSString *)password
                                  completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;

- (AlfrescoRequest *)authenticateWithEmailAddress:(NSString *)emailAddress
                                         password:(NSString *)password
                                          network:(NSString *)network
                                  completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;

- (AlfrescoRequest *)authenticateWithOAuthData:(AlfrescoOAuthData *)oauthData
                               completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;

- (AlfrescoRequest *)authenticateWithOAuthData:(AlfrescoOAuthData *)oauthData
                                       network:(NSString *)network
                               completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;

- (NSArray *)networkArrayFromJSONData:(NSData *)data error:(NSError **)outError;

- (AlfrescoCloudNetwork *)networkFromJSON:(NSDictionary *)networkDictionary;

- (AlfrescoCloudNetwork *)homeNetworkFromArray:(NSArray *)networks;

- (id)authProviderToBeUsed;

- (AlfrescoArrayCompletionBlock)repositoriesWithParameters:(CMISSessionParameters *)parameters
                                           alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
                                           completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;

@property (nonatomic, strong, readwrite) NSURL *baseUrl;
@property (nonatomic, strong, readwrite) NSURL *baseURLWithoutNetwork;
@property (nonatomic, strong) NSURL *cmisUrl;
@property (nonatomic, strong, readwrite) NSMutableDictionary *sessionData;
@property (nonatomic, strong, readwrite) NSMutableDictionary *sessionCache;
@property (nonatomic, strong, readwrite) NSString *personIdentifier;
@property (nonatomic, strong, readwrite) AlfrescoRepositoryInfo *repositoryInfo;
@property (nonatomic, strong, readwrite) AlfrescoFolder *rootFolder;
@property (nonatomic, strong, readwrite) NSString *emailAddress;
@property (nonatomic, strong, readwrite) NSString *password;
@property (nonatomic, strong, readwrite) AlfrescoListingContext *defaultListingContext;
@property (nonatomic, strong, readwrite) NSString * apiKey;
@property (nonatomic, strong, readwrite) id<AlfrescoNetworkProvider> networkProvider;
@property BOOL isUsingBaseAuthenticationProvider;
@property (nonatomic, strong, readwrite) NSArray *unremovableSessionKeys;
@property (nonatomic, strong, readwrite) AlfrescoWorkflowInfo *workflowInfo;
@end


@implementation AlfrescoCloudSession

#pragma mark - Public methods

+ (AlfrescoRequest *)connectWithOAuthData:(AlfrescoOAuthData *)oauthData
                          completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:oauthData argumentName:@"oauthData"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    AlfrescoCloudSession *sessionInstance = [[AlfrescoCloudSession alloc] initWithParameters:nil];
    if (nil != sessionInstance)
    {
        return [sessionInstance authenticateWithOAuthData:oauthData
                                          completionBlock:completionBlock];
    }
    return nil;
}

+ (AlfrescoRequest *)connectWithOAuthData:(AlfrescoOAuthData *)oauthData
                               parameters:(NSDictionary *)parameters
                          completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    AlfrescoCloudSession *sessionInstance = [[AlfrescoCloudSession alloc] initWithParameters:parameters];
    if (nil != sessionInstance)
    {
        BOOL useBasicConnect = NO;
        NSString * username = nil;
        NSString * password = nil;
        if (nil != parameters)
        {
            if ([[parameters allKeys] containsObject:kAlfrescoSessionCloudBasicAuth])
            {
                useBasicConnect = [[parameters valueForKey:kAlfrescoSessionCloudBasicAuth] boolValue];
            }
            if (useBasicConnect)
            {
                username = [parameters valueForKey:kAlfrescoSessionUsername];
                password = [parameters valueForKey:kAlfrescoSessionPassword];
            }
        }
        if (useBasicConnect)
        {
            return [sessionInstance authenticateWithEmailAddress:username
                                                        password:password
                                                 completionBlock:completionBlock];
        }
        else
        {
            [AlfrescoErrors assertArgumentNotNil:oauthData argumentName:@"oauthData"];
            return [sessionInstance authenticateWithOAuthData:oauthData
                                              completionBlock:completionBlock];
        }
    }
    return nil;
}

+ (AlfrescoRequest *)connectWithOAuthData:(AlfrescoOAuthData *)oauthData
                         networkIdentifer:(NSString *)networkIdentifer
                          completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:oauthData argumentName:@"oauthData"];
    [AlfrescoErrors assertArgumentNotNil:networkIdentifer argumentName:@"networkIdentifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    AlfrescoCloudSession *sessionInstance = [[AlfrescoCloudSession alloc] initWithParameters:nil];
    if (nil != sessionInstance)
    {
        return [sessionInstance authenticateWithOAuthData:oauthData
                                                  network:networkIdentifer
                                          completionBlock:completionBlock];
    }
    return nil;
}

+ (AlfrescoRequest *)connectWithOAuthData:(AlfrescoOAuthData *)oauthData
                         networkIdentifer:(NSString *)networkIdentifer
                               parameters:(NSDictionary *)parameters
                          completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:oauthData argumentName:@"oauthData"];
    [AlfrescoErrors assertArgumentNotNil:networkIdentifer argumentName:@"networkIdentifer"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    AlfrescoCloudSession *sessionInstance = [[AlfrescoCloudSession alloc] initWithParameters:parameters];
    if (nil != sessionInstance)
    {
        BOOL useBasicConnect = NO;
        NSString * username = nil;
        NSString * password = nil;
        if (nil != parameters)
        {
            if ([[parameters allKeys] containsObject:kAlfrescoSessionCloudBasicAuth])
            {
                useBasicConnect = [[parameters valueForKey:kAlfrescoSessionCloudBasicAuth] boolValue];
            }
            if (useBasicConnect)
            {
                username = [parameters valueForKey:kAlfrescoSessionUsername];
                password = [parameters valueForKey:kAlfrescoSessionPassword];
            }
        }
        if (useBasicConnect)
        {
            return [sessionInstance authenticateWithEmailAddress:username
                                                        password:password
                                                         network:networkIdentifer
                                                 completionBlock:completionBlock];
        }
        else
        {
            return [sessionInstance authenticateWithOAuthData:oauthData
                                                      network:networkIdentifer
                                              completionBlock:completionBlock];
        }
    }
    return nil;
}

- (AlfrescoRequest *)retrieveNetworksWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
//    __weak AlfrescoCloudSession *weakSelf = self;
    id<AlfrescoAuthenticationProvider> authProvider = [self authProviderToBeUsed];
    [self setObject:authProvider forParameter:kAlfrescoAuthenticationProviderObjectKey];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.networkProvider executeRequestWithURL:self.baseURLWithoutNetwork
                                        session:self alfrescoRequest:request
                                completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *networks = [self networkArrayFromJSONData:data error:&conversionError];
            completionBlock(networks, conversionError);
        }
    }];
    return request;
}

/**
 This is a custom setter method for oauthData. The only use case for this is in case the access token has to be refreshed (AlfrescoCloudSession is instantiated with oauth data).
 This has 2 major consequences:
 1.) we need to recreate the Authentication Provider. This also needs to filter through to the CMIS library/CMIS Session. 
 2.) because we use a custom setter for the oauthData property, AlfrescoCloudSession uses the instance variable _oauthData internally to avoid calling the setter inadvertently.
 
 TODO:
 For now we need to re-initialise/create the CMIS session entirely, even though we only change one parameter on the CMISSessionParameter property of the session.
 Future versions of ObjectiveCMIS lib need to ensure that this won't be necessary and that we will be able to change the parameter 'on the fly'.
 */
- (void)setOauthData:(AlfrescoOAuthData *)oauthData
{
    if (_oauthData == oauthData)
    {
        return;
    }
    if (nil != _oauthData)
    {
        _oauthData = nil;
    }
    _oauthData = oauthData;

    if (nil != _oauthData)
    {
        id<AlfrescoAuthenticationProvider> authProvider = [[AlfrescoOAuthAuthenticationProvider alloc] initWithOAuthData:oauthData];
        [self setObject:authProvider forParameter:kAlfrescoAuthenticationProviderObjectKey];
        AlfrescoCMISPassThroughAuthenticationProvider *passthroughAuthProvider = [[AlfrescoCMISPassThroughAuthenticationProvider alloc] initWithAlfrescoAuthenticationProvider:authProvider];
        CMISSession *cmisSession = [self objectForParameter:kAlfrescoSessionKeyCmisSession];
        if (cmisSession)
        {
            __block CMISSessionParameters *params = [[CMISSessionParameters alloc] initWithBindingType:CMISBindingTypeAtomPub];
            params.atomPubUrl = cmisSession.sessionParameters.atomPubUrl;
            params.authenticationProvider = passthroughAuthProvider;
            params.repositoryId = cmisSession.sessionParameters.repositoryId;
            [params setObject:NSStringFromClass([AlfrescoCMISObjectConverter class]) forKey:kCMISSessionParameterObjectConverterClassName];
            [CMISSession connectWithSessionParameters:params completionBlock:^(CMISSession *newCMISsession, NSError *error){
                if (newCMISsession)
                {
                    [self setObject:newCMISsession forParameter:kAlfrescoSessionKeyCmisSession];
                    AlfrescoCMISToAlfrescoObjectConverter *objectConverter = [[AlfrescoCMISToAlfrescoObjectConverter alloc] initWithSession:self];
                    self.repositoryInfo = [objectConverter repositoryInfoFromCMISSession:newCMISsession];
                    [newCMISsession retrieveRootFolderWithCompletionBlock:^(CMISFolder *rootFolder, NSError *error){
                        if (rootFolder)
                        {
                            self.rootFolder = (AlfrescoFolder *)[objectConverter nodeFromCMISObject:rootFolder];
                        }
                    }];
                    
                }
            }];
        }
    }
}


- (NSArray *)allParameterKeys
{
    return [self.sessionData allKeys];
}

- (id)objectForParameter:(id)key
{
    if ([key hasPrefix:kAlfrescoSessionInternalCache])
    {
        return [self.sessionCache objectForKey:key];
    }
    else
    {
        return [self.sessionData objectForKey:key];
    }
}

- (void)setObject:(id)object forParameter:(id)key
{
    if ([key hasPrefix:kAlfrescoSessionInternalCache])
    {
        [self.sessionCache setObject:object forKey:key];
    }
    else if ([self.unremovableSessionKeys containsObject:key] && ![[self allParameterKeys] containsObject:key])
    {
        [self.sessionData setObject:object forKey:key];
    }
    else
    {
        [self.sessionData setObject:object forKey:key];
    }
}

- (void)addParametersFromDictionary:(NSDictionary *)dictionary
{
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([self.unremovableSessionKeys containsObject:key] && ![[self allParameterKeys] containsObject:key])
        {
            [self.sessionData setObject:obj forKey:key];
        }
        else
        {
            [self.sessionData setObject:obj forKey:key];
        }
    }];
}

- (void)removeParameter:(id)key
{
    if ([key hasPrefix:kAlfrescoSessionInternalCache])
    {
        id cached = [self.sessionCache objectForKey:key];
        if ([cached respondsToSelector:@selector(clear)])
        {
            [cached clear];
        }
        [self.sessionCache removeObjectForKey:key];
    }
    else if (![self.unremovableSessionKeys containsObject:key])
    {
        [self.sessionData removeObjectForKey:key];
    }
}


- (void)clear
{
    [self.sessionCache enumerateKeysAndObjectsUsingBlock:^(NSString *cacheName, id cacheObj, BOOL *stop){
        if ([cacheObj respondsToSelector:@selector(clear)])
        {
            [cacheObj clear];
        }
    }];
    [self.sessionCache removeAllObjects];
}


#pragma mark - Private methods
- (id)authProviderToBeUsed
{
    if (self.isUsingBaseAuthenticationProvider)
    {
        return [[AlfrescoBasicAuthenticationProvider alloc] initWithUsername:self.emailAddress andPassword:self.password];
    }
    else
    {
        /// strictly speaking we could use the property, i.e. self.oauthData here. however, i wanted to be consistent in the use of oauthData and only
        /// use the instance variable internally to avoid the use of self.oauthData as a setter
        return [[AlfrescoOAuthAuthenticationProvider alloc] initWithOAuthData:_oauthData];
    }
}

- (AlfrescoRequest *)authenticateWithOAuthData:(AlfrescoOAuthData *)oauthData
                               completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    self.isUsingBaseAuthenticationProvider = NO;
    NSString *baseURL = kAlfrescoCloudURL;
    if ([[self.sessionData allKeys] containsObject:kAlfrescoSessionCloudURL])
    {
        baseURL = [self.sessionData valueForKey:kAlfrescoSessionCloudURL];
        AlfrescoLogDebug(@"overriding Cloud URL with: %@", baseURL);
    }
    self.baseUrl = [NSURL URLWithString:baseURL];
    self.baseURLWithoutNetwork = [NSURL URLWithString:baseURL];
    _oauthData = oauthData; ///setting oauthData only via instance variable. The setter method recreates a CMIS session and this shouldn't be used here.
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request = [self retrieveNetworksWithCompletionBlock:^(NSArray *networks, NSError *error){
        if (nil == networks)
        {
            completionBlock(nil, error);
        }
        else
        {
            AlfrescoLogDebug(@"found %d networks", networks.count);
            __block AlfrescoCloudNetwork *homeNetwork = [self homeNetworkFromArray:networks];
            if (nil == homeNetwork)
            {
                completionBlock(nil, error);
            }
            else
            {
                request = [self authenticateWithOAuthData:oauthData
                                                  network:homeNetwork.identifier
                                          completionBlock:completionBlock];
            }
            
        }
    }];
    return request;
}


- (AlfrescoRequest *)authenticateWithOAuthData:(AlfrescoOAuthData *)oauthData
                                       network:(NSString *)network
                               completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    self.isUsingBaseAuthenticationProvider = NO;
    NSString *baseURL = kAlfrescoCloudURL;
    if ([[self.sessionData allKeys] containsObject:kAlfrescoSessionCloudURL])
    {
        baseURL = [self.sessionData valueForKey:kAlfrescoSessionCloudURL];
        AlfrescoLogDebug(@"overriding Cloud URL with: %@", baseURL);
    }
    self.baseUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",baseURL,network]];
    self.baseURLWithoutNetwork = [NSURL URLWithString:baseURL];
    _oauthData = oauthData; ///setting oauthData only via instance variable. The setter method recreates a CMIS session and this shouldn't be used here.
    self.personIdentifier = kAlfrescoMe;

    id<AlfrescoAuthenticationProvider> authProvider = [self authProviderToBeUsed];
    [self setObject:authProvider forParameter:kAlfrescoAuthenticationProviderObjectKey];
    AlfrescoCMISPassThroughAuthenticationProvider *passthroughAuthProvider = [[AlfrescoCMISPassThroughAuthenticationProvider alloc] initWithAlfrescoAuthenticationProvider:authProvider];

    __block CMISSessionParameters *params = [[CMISSessionParameters alloc] initWithBindingType:CMISBindingTypeAtomPub];
    NSString *cmisUrl = [[self.baseUrl absoluteString] stringByAppendingString:kAlfrescoCloudCMISPath];
    params.atomPubUrl = [NSURL URLWithString:cmisUrl];
    params.authenticationProvider = passthroughAuthProvider;
    
    // use activiti by default on cloud
    self.workflowInfo = [[AlfrescoWorkflowInfo alloc] initWithSession:self workflowEngine:AlfrescoWorkflowEngineTypeActiviti];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    AlfrescoArrayCompletionBlock repositoryCompletionBlock = [self repositoriesWithParameters:params
                                                                              alfrescoRequest:request
                                                                              completionBlock:completionBlock];
    request.httpRequest = [CMISSession arrayOfRepositories:params completionBlock:repositoryCompletionBlock];
    return request;
    
}

- (AlfrescoArrayCompletionBlock)repositoriesWithParameters:(CMISSessionParameters *)parameters
                                           alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
                                           completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    AlfrescoArrayCompletionBlock arrayCompletionBlock = ^void(NSArray *repositories, NSError *error){
        if (nil == repositories)
        {
            if(completionBlock)
            {
                completionBlock(nil, error);
            }
        }
        else if( 0 == repositories.count)
        {
            error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeNoRepositoryFound];
            if(completionBlock)
            {
                completionBlock(nil, error);
            }
            
        }
        else
        {
            CMISRepositoryInfo *repoInfo = [repositories objectAtIndex:0];
            parameters.repositoryId = repoInfo.identifier;
            [parameters setObject:NSStringFromClass([AlfrescoCMISObjectConverter class]) forKey:kCMISSessionParameterObjectConverterClassName];

            AlfrescoLogDebug(@"URL is %@ and the repo ID is %@ ****", [parameters.atomPubUrl absoluteString], repoInfo.identifier);

            alfrescoRequest.httpRequest = [CMISSession connectWithSessionParameters:parameters
                                                                    completionBlock:^(CMISSession *cmisSession, NSError *error){
                if (nil == cmisSession)
                {
                    if(completionBlock)
                    {
                        completionBlock(nil, error);
                    }
                }
                else
                {
                    [self setObject:cmisSession forParameter:kAlfrescoSessionKeyCmisSession];
                    AlfrescoCMISToAlfrescoObjectConverter *objectConverter = [[AlfrescoCMISToAlfrescoObjectConverter alloc] initWithSession:self];
                    self.repositoryInfo = [objectConverter repositoryInfoFromCMISSession:cmisSession];
                    alfrescoRequest.httpRequest = [cmisSession retrieveRootFolderWithCompletionBlock:^(CMISFolder *rootFolder, NSError *error){
                        if (nil == rootFolder)
                        {
                            if(completionBlock)
                            {
                                completionBlock(nil, error);
                            }
                        }
                        else
                        {
                            self.rootFolder = (AlfrescoFolder *)[objectConverter nodeFromCMISObject:rootFolder];
                            if(completionBlock)
                            {
                                completionBlock(self, nil);
                            }
                        }
                    }];
                    
                }
            }];
            
        }
    };
    return arrayCompletionBlock;
}



/**
This authentication method authorises the user to access the home network assigned to the account. It first searches the available networks for the user
 (using retrieveNetworksWithCompletionBlock) and from within that block proceeds to full authentication for a specific network.
 */
- (AlfrescoRequest *)authenticateWithEmailAddress:(NSString *)emailAddress
                                         password:(NSString *)password
                                  completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    self.isUsingBaseAuthenticationProvider = YES;
    NSString *baseURL = kAlfrescoCloudURL;
    if ([[self.sessionData allKeys] containsObject:kAlfrescoSessionCloudURL])
    {
        baseURL = [self.sessionData valueForKey:kAlfrescoSessionCloudURL];
        AlfrescoLogDebug(@"overriding Cloud URL with: %@", baseURL);
    }
    self.baseUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, kAlfrescoCloudPrecursor]];
    self.baseURLWithoutNetwork = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, kAlfrescoCloudPrecursor]];
    AlfrescoLogDebug(@"baseURLWithoutNetwork = %@", [self.baseURLWithoutNetwork absoluteString]);
    self.emailAddress = emailAddress;
    self.password = password;
    self.personIdentifier = emailAddress;
    __block AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    request = [self retrieveNetworksWithCompletionBlock:^(NSArray *networks, NSError *error){
        if (nil == networks)
        {
            completionBlock(nil, error);
        }
        else
        {
            AlfrescoLogDebug(@"found %d networks",networks.count);
            __block AlfrescoCloudNetwork *homeNetwork = [self homeNetworkFromArray:networks];
            if (nil == homeNetwork)
            {
                completionBlock(nil, error);
            }
            else
            {
                request = [self authenticateWithEmailAddress:emailAddress
                                                    password:password
                                                     network:homeNetwork.identifier
                                             completionBlock:completionBlock];
            }
        }
    }];
    return request;
}

/**
 This method is the full authentication implementation for a specific network, including the home network. It sets up the (CMIS) session, repository info and
 other basic parameters required in the API.
 */
- (AlfrescoRequest *)authenticateWithEmailAddress:(NSString *)emailAddress
                                         password:(NSString *)password
                                          network:(NSString *)network
                                  completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    self.isUsingBaseAuthenticationProvider = YES;
    NSString *baseURL = kAlfrescoCloudURL;
    if ([[self.sessionData allKeys] containsObject:kAlfrescoSessionCloudURL])
    {
        baseURL = [self.sessionData valueForKey:kAlfrescoSessionCloudURL];
        AlfrescoLogDebug(@"overriding Cloud URL with: %@", baseURL);
    }
    self.baseUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@", baseURL, kAlfrescoCloudPrecursor, network]];
    self.baseURLWithoutNetwork = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, kAlfrescoCloudPrecursor]];
    self.emailAddress = emailAddress;
    self.password = password;
    self.personIdentifier = emailAddress;
    
    NSString *cmisUrl = [[self.baseUrl absoluteString] stringByAppendingString:kAlfrescoCloudCMISPath];

    __block CMISSessionParameters *params = [[CMISSessionParameters alloc] initWithBindingType:CMISBindingTypeAtomPub];
    params.username = emailAddress;
    params.password = password;
    params.atomPubUrl = [NSURL URLWithString:cmisUrl];

    id<AlfrescoAuthenticationProvider> authProvider = [self authProviderToBeUsed];
    [self setObject:authProvider forParameter:kAlfrescoAuthenticationProviderObjectKey];

    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    AlfrescoArrayCompletionBlock repositoryCompletionBlock = [self repositoriesWithParameters:params
                                                                              alfrescoRequest:request
                                                                              completionBlock:completionBlock];
    request.httpRequest = [CMISSession arrayOfRepositories:params completionBlock:repositoryCompletionBlock];
    return request;
}

/**
 initialise with custom settings. Settings is an optional parameter and can be nil
 For cloud the metadataextraction/thumbnail creation - available for onpremise services - is disabled.
 The init method will override any values given for both parameters
 */
- (id)initWithParameters:(NSDictionary *)parameters
{
    self = [super init];
    if (nil != self)
    {
        if (nil != parameters)
        {
            self.sessionData = [NSMutableDictionary dictionaryWithDictionary:parameters];
        }
        else
        {
            self.sessionData = [NSMutableDictionary dictionaryWithCapacity:8];
        }
        self.sessionCache = [NSMutableDictionary dictionary];
        [self setObject:[NSNumber numberWithBool:NO] forParameter:kAlfrescoMetadataExtraction];
        [self setObject:[NSNumber numberWithBool:NO] forParameter:kAlfrescoThumbnailCreation];
        
        self.networkProvider = [[AlfrescoDefaultNetworkProvider alloc] init];
        id networkObject = [parameters objectForKey:kAlfrescoNetworkProvider];
        if (networkObject)
        {
            BOOL conformsToAlfrescoNetworkProvider = [networkObject conformsToProtocol:@protocol(AlfrescoNetworkProvider)];
            
            if (conformsToAlfrescoNetworkProvider)
            {
                self.networkProvider = (id<AlfrescoNetworkProvider>)networkObject;
            }
            else
            {
                @throw([NSException exceptionWithName:@"Error with custom network provider"
                                               reason:@"The custom network provider must be an object that conforms to the AlfrescoNetworkProvider protocol"
                                             userInfo:nil]);
            }
        }
        
        self.unremovableSessionKeys = @[kAlfrescoSessionKeyCmisSession, kAlfrescoAuthenticationProviderObjectKey];
                
        // setup defaults
        self.defaultListingContext = [[AlfrescoListingContext alloc] init];
    }
    return self;
}

/**
 Obtains an AlfrescoCloudNetwork object from a set of JSON data
 */
- (AlfrescoCloudNetwork *)networkFromJSON:(NSDictionary *)networkDictionary
{
    AlfrescoCloudNetwork *network = [[AlfrescoCloudNetwork alloc] init];
    network.identifier = [networkDictionary valueForKey:kAlfrescoJSONIdentifier];
    id homeNetworkValidateString = [networkDictionary valueForKey:kAlfrescoJSONHomeNetwork];
    if ([homeNetworkValidateString isKindOfClass:[NSNumber class]])
    {
        NSNumber *number = (NSNumber *)homeNetworkValidateString;
        network.isHomeNetwork = [number boolValue];
    }
    
    id isEnabledValidateString = [networkDictionary valueForKey:kAlfrescoJSONIsEnabled];
    if ([isEnabledValidateString isKindOfClass:[NSNumber class]])
    {
        NSNumber *enabledNumber = (NSNumber *)isEnabledValidateString;
        network.isEnabled = [enabledNumber boolValue];
    }
    
    id paidValidationString = [networkDictionary valueForKey:kAlfrescoJSONPaidNetwork];
    if ([paidValidationString isKindOfClass:[NSNumber class]])
    {
        NSNumber *paidNumber = (NSNumber *)paidValidationString;
        network.isPaidNetwork = [paidNumber boolValue];
    }
    
    id createdAtObject = [networkDictionary valueForKey:kAlfrescoJSONCreatedAt];
    if ([createdAtObject isKindOfClass:[NSString class]])
    {
        NSString *dateString = (NSString *)createdAtObject;
        if (nil != dateString)
        {
            network.createdAt = [CMISDateUtil dateFromString:dateString];
        }
    }
                
    network.subscriptionLevel = [networkDictionary valueForKey:kAlfrescoJSONSubscriptionLevel];
    return network;
}

/**
 parses the JSON data to look for an array containing the Alfresco network details. Once found, it calls the networkFromJSON method
 to set up a AlfrescoCloudNetwork object.
 */
- (NSArray *) networkArrayFromJSONData:(NSData *)data error:(NSError **)outError
{
    if (data == nil)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        else
        {
            NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        return nil;
    }
    NSError *error = nil;
    id jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (nil == jsonDictionary)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        return nil;
    }
    
    if (![jsonDictionary isKindOfClass:[NSDictionary class]])
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    
    id listObject = [jsonDictionary valueForKey:kAlfrescoCloudJSONList];
    if (![listObject isKindOfClass:[NSDictionary class]])
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    id entries = [listObject valueForKey:kAlfrescoCloudJSONEntries];
    if (![entries isKindOfClass:[NSArray class]])
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    NSArray *entriesArray = [NSArray arrayWithArray:entries];
    if (0 == entriesArray.count)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeNoNetworkFound];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeNoNetworkFound];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeNoNetworkFound];
        }
        return nil;
    }
        
    NSMutableArray *resultsArray = [NSMutableArray arrayWithCapacity:entriesArray.count];
    
    for (NSDictionary *entryDict in entriesArray)
    {
        NSDictionary *individualEntry = [entryDict valueForKey:kAlfrescoCloudJSONEntry];
        [resultsArray addObject:[self networkFromJSON:individualEntry]];
    }
    return resultsArray;
    
}


- (AlfrescoCloudNetwork *)homeNetworkFromArray:(NSArray *)networks
{
    AlfrescoCloudNetwork *homeNetwork = nil;
    for (AlfrescoCloudNetwork *network in networks)
    {
        if (network.isEnabled)
        {
            homeNetwork = network;
            if (network.isHomeNetwork)
            {
                break;
            }
        }
    }
    
    return homeNetwork;
}



@end

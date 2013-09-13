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

#import "AlfrescoCloudPersonService.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoPagingUtils.h"
#import "AlfrescoDocumentFolderService.h"
#import "AlfrescoNetworkProvider.h"
#import "AlfrescoLog.h"

@interface AlfrescoCloudPersonService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoCMISToAlfrescoObjectConverter *objectConverter;
@property (nonatomic, weak, readwrite) id<AlfrescoAuthenticationProvider> authenticationProvider;
@end

@implementation AlfrescoCloudPersonService

- (id)initWithSession:(id<AlfrescoSession>)session
{
    if (self = [super init])
    {
        self.session = session;
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoCloudAPIPath];
        self.objectConverter = [[AlfrescoCMISToAlfrescoObjectConverter alloc] initWithSession:self.session];
        id authenticationObject = [session objectForParameter:kAlfrescoAuthenticationProviderObjectKey];
        self.authenticationProvider = nil;
        if ([authenticationObject isKindOfClass:[AlfrescoBasicAuthenticationProvider class]])
        {
            self.authenticationProvider = (AlfrescoBasicAuthenticationProvider *)authenticationObject;
        }
    }
    return self;
}
- (AlfrescoRequest *)retrievePersonWithIdentifier:(NSString *)identifier completionBlock:(AlfrescoPersonCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:identifier argumentName:@"identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoOnPremisePersonAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:identifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                        alfrescoRequest:alfrescoRequest
                                        completionBlock:^(NSData *responseData, NSError *error){
        if (nil == responseData)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            AlfrescoPerson *person = [self alfrescoPersonFromJSONData:responseData error:&conversionError];
            completionBlock(person, conversionError);
        }
    }];
    return alfrescoRequest;
}

- (AlfrescoRequest *)retrieveAvatarForPerson:(AlfrescoPerson *)person completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:person argumentName:@"person"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (nil == person.avatarIdentifier)
    {
        completionBlock(nil, [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodePerson]);
        return nil;
    }
    AlfrescoDocumentFolderService *docService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    return [docService retrieveNodeWithIdentifier:person.avatarIdentifier
                                  completionBlock:^(AlfrescoNode *node, NSError *error){
         
        [docService
         retrieveContentOfDocument:(AlfrescoDocument *)node
         completionBlock:^(AlfrescoContentFile *avatarFile, NSError *avatarError){
             completionBlock(avatarFile, avatarError);
         } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal){}];
         
    }];    
}

- (AlfrescoRequest *)updateProfile:(NSDictionary *)properties completionBlock:(AlfrescoPersonCompletionBlock)completionBlock
{
    /*
    [AlfrescoErrors assertArgumentNotNil:properties argumentName:@"properties"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoCloudInternalAPIPath stringByAppendingString:kAlfrescoCloudPersonAPI];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:[self.session.baseUrl absoluteString] extensionURL:requestString];
    
    NSData *bodyData = [self jsonDataForUpdatingProfile:[self propertiesWithCloudKeys:properties]];
    AlfrescoLogDebug(@"body json: %@", [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding]);
    
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:bodyData
                                                 method:kAlfrescoHTTPPut
                                        alfrescoRequest:alfrescoRequest
                                        completionBlock:^(NSData *responseData, NSError *error) {
                                            if (nil == responseData)
                                            {
                                                completionBlock(nil, error);
                                            }
                                            else
                                            {
                                                AlfrescoLogDebug(@"person: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                                                NSError *conversionError = nil;
                                                AlfrescoPerson *person = [self alfrescoPersonFromJSONData:responseData error:&conversionError];
                                                completionBlock(person, conversionError);
                                            }
                                        }];
    return alfrescoRequest;
    */
    return nil;
}

- (AlfrescoRequest *)search:(NSString *)filter completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:filter argumentName:@"filter"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    return [self searchPeople:filter withListingContext:nil completionBlock:completionBlock];
}

- (AlfrescoRequest *)search:(NSString *)filter
         WithListingContext:(AlfrescoListingContext *)listingContext
            completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:filter argumentName:@"filter"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    AlfrescoRequest *request = [self searchPeople:filter withListingContext:listingContext completionBlock:^(NSArray *array, NSError *error) {
        
        AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:array listingContext:listingContext];
        completionBlock(pagingResult, nil);
    }];
    return request;
}

- (AlfrescoRequest *)searchPeople:(NSString *)filter
               withListingContext:(AlfrescoListingContext *)listingContext
                  completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    NSString *requestString = [kAlfrescoCloudInternalAPIPath stringByAppendingString:kAlfrescoCloudPersonSearchAPI];
    requestString = [requestString stringByReplacingOccurrencesOfString:kAlfrescoSearchFilter withString:filter];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:[self.session.baseUrl absoluteString] extensionURL:requestString listingContext:listingContext];
    
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                        alfrescoRequest:alfrescoRequest
                                        completionBlock:^(NSData *responseData, NSError *error){
                                            if (nil == responseData)
                                            {
                                                completionBlock(nil, error);
                                            }
                                            else
                                            {
                                                NSError *conversionError = nil;
                                                NSArray *people = [self peopleArrayFromJSONData:responseData error:&conversionError];
                                                completionBlock(people, conversionError);
                                            }
                                        }];
    return alfrescoRequest;
}

#pragma mark - private methods
- (AlfrescoPerson *)alfrescoPersonFromJSONData:(NSData *)data error:(NSError *__autoreleasing *)outError
{
    NSMutableDictionary *entryDict = [[AlfrescoObjectConverter dictionaryJSONEntryFromListData:data error:outError] mutableCopy];
    if (nil == entryDict)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            
        }
        return nil;
    }
    AlfrescoCompany *company = [[AlfrescoCompany alloc] initWithProperties:[entryDict objectForKey:kAlfrescoJSONCompany]];
    [entryDict setValue:company forKey:kAlfrescoJSONCompany];
    
    return [[AlfrescoPerson alloc] initWithProperties:entryDict];
}

- (NSArray *)peopleArrayFromJSONData:(NSData *)data error:(NSError *__autoreleasing *)outError
{
    NSMutableDictionary *entries = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:outError];
    if (nil == entries)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            
        }
        return nil;
    }
    
    NSArray *peopleProperties = [entries objectForKey:kAlfrescoJSONPeople];
    NSMutableArray *people = [[NSMutableArray alloc] init];
    
    for (NSDictionary *personProperties in peopleProperties)
    {
        AlfrescoCompany *company = [[AlfrescoCompany alloc] initWithProperties:personProperties];
        [personProperties setValue:company forKey:kAlfrescoJSONCompany];
        AlfrescoPerson *person = [[AlfrescoPerson alloc] initWithProperties:personProperties];
        [people addObject:person];
    }
    return people;
}

- (NSData *)jsonDataForUpdatingProfile:(NSDictionary *)properties
{
    return [NSJSONSerialization dataWithJSONObject:properties options:NSJSONWritingPrettyPrinted error:nil];
}

- (NSDictionary *)propertiesWithCloudKeys:(NSDictionary *)properties
{
    /**
     * Temporary until cloud supports a full person service
     *
    NSDictionary *mappedCloudKeys = @{kAlfrescoPersonPropertyFirstName: kAlfrescoJSONFirstName,
                                      kAlfrescoPersonPropertyLastName: kAlfrescoJSONLastName,
                                      kAlfrescoPersonPropertyJobTitle: kAlfrescoCloudJSONJobTitle,
                                      kAlfrescoPersonPropertyLocation: kAlfrescoJSONLocation,
                                      kAlfrescoPersonPropertyDescription: kAlfrescoJSONDescription,
                                      kAlfrescoPersonPropertyTelephoneNumber: kAlfrescoJSONTelephoneNumber,
                                      kAlfrescoPersonPropertyMobileNumber: kAlfrescoJSONMobileNumber,
                                      kAlfrescoPersonPropertyEmail: kAlfrescoJSONEmail,
                                      kAlfrescoPersonPropertySkypeId: kAlfrescoJSONSkypeId,
                                      kAlfrescoPersonPropertyInstantMessageId: kAlfrescoJSONInstantMessageId,
                                      kAlfrescoPersonPropertyGoogleId: kAlfrescoJSONGoogleId,
                                      kAlfrescoPersonPropertyStatus: kAlfrescoJSONStatus,
                                      kAlfrescoPersonPropertyStatusTime: kAlfrescoJSONStatusTime,
                                      kAlfrescoPersonPropertyCompanyName: kAlfrescoJSONCompanyName,
                                      kAlfrescoPersonPropertyCompanyAddressLine1: kAlfrescoJSONAddressLine1,
                                      kAlfrescoPersonPropertyCompanyAddressLine2: kAlfrescoJSONAddressLine2,
                                      kAlfrescoPersonPropertyCompanyAddressLine3: kAlfrescoJSONAddressLine3,
                                      kAlfrescoPersonPropertyCompanyPostcode: kAlfrescoJSONPostcode,
                                      kAlfrescoPersonPropertyCompanyTelephoneNumber: kAlfrescoJSONTelephoneNumber,
                                      kAlfrescoPersonPropertyCompanyFaxNumber: kAlfrescoJSONFaxNumber,
                                      kAlfrescoPersonPropertyCompanyEmail: kAlfrescoJSONEmail};
     */
    
    NSDictionary *mappedOnPremiseKeys = @{kAlfrescoPersonPropertyFirstName: kAlfrescoJSONFirstName,
                                          kAlfrescoPersonPropertyLastName: kAlfrescoJSONLastName,
                                          kAlfrescoPersonPropertyJobTitle: kAlfrescoJSONJobTitle,
                                          kAlfrescoPersonPropertyLocation: kAlfrescoJSONLocation,
                                          kAlfrescoPersonPropertyDescription: kAlfrescoJSONPersonDescription,
                                          kAlfrescoPersonPropertyTelephoneNumber: kAlfrescoJSONTelephoneNumber,
                                          kAlfrescoPersonPropertyMobileNumber: kAlfrescoJSONMobileNumber,
                                          kAlfrescoPersonPropertyEmail: kAlfrescoJSONEmail,
                                          kAlfrescoPersonPropertySkypeId: kAlfrescoJSONSkype,
                                          kAlfrescoPersonPropertyInstantMessageId: kAlfrescoJSONInstantMessage,
                                          kAlfrescoPersonPropertyGoogleId: kAlfrescoJSONGoogle,
                                          kAlfrescoPersonPropertyStatus: kAlfrescoJSONStatus,
                                          kAlfrescoPersonPropertyStatusTime: kAlfrescoJSONStatusTime,
                                          kAlfrescoPersonPropertyCompanyName: kAlfrescoJSONCompanyName,
                                          kAlfrescoPersonPropertyCompanyAddressLine1: kAlfrescoJSONCompanyAddressLine1,
                                          kAlfrescoPersonPropertyCompanyAddressLine2: kAlfrescoJSONCompanyAddressLine2,
                                          kAlfrescoPersonPropertyCompanyAddressLine3: kAlfrescoJSONCompanyAddressLine3,
                                          kAlfrescoPersonPropertyCompanyPostcode: kAlfrescoJSONCompanyPostcode,
                                          kAlfrescoPersonPropertyCompanyTelephoneNumber: kAlfrescoJSONCompanyTelephone,
                                          kAlfrescoPersonPropertyCompanyFaxNumber: kAlfrescoJSONCompanyFaxNumber,
                                          kAlfrescoPersonPropertyCompanyEmail: kAlfrescoJSONCompanyEmail};
    
    NSArray *propertyKeys = [properties allKeys];
    NSMutableDictionary *updatedProperties = [[NSMutableDictionary alloc] init];
    
    
    for (NSString *key in propertyKeys)
    {
        NSString *mappedKey = [mappedOnPremiseKeys objectForKey:key];
        if (mappedKey)
        {
            [updatedProperties setValue:properties[key] forKey:mappedKey];
        }
    }
    return updatedProperties;
}

@end

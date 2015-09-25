/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile iOS App.
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

#import "CustomFolderService.h"

@interface CustomFolderService ()

@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoSearchService *searchService;

@end

@implementation CustomFolderService

- (instancetype)initWithSession:(id<AlfrescoSession>)session
{
    self = [self init];
    if (self)
    {
        self.session = session;
        self.searchService = [[AlfrescoSearchService alloc] initWithSession:session];
    }
    return self;
}

- (AlfrescoRequest *)retrieveSharedFilesFolderWithCompletionBlock:(AlfrescoFolderCompletionBlock)completionBlock
{
    AlfrescoRequest *request = nil;
    
    NSString *searchQuery = @"SELECT * FROM cmis:folder WHERE CONTAINS ('QNAME:\"app:company_home/app:shared\"')";
    request = [self.searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *array, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            AlfrescoFolder *sharedFolder = array.firstObject;
            completionBlock(sharedFolder, error);
        }
    }];
    
    return request;
}

- (AlfrescoRequest *)retrieveMyFilesFolderWithCompletionBlock:(AlfrescoFolderCompletionBlock)completionBlock
{
    AlfrescoRequest *request = nil;
    
    // MOBILE-2984: The username needs to be escaped using ISO9075 encoding, as there's nothing built-in to do this and this
    // is a temporary fix (CMIS 1.1 will expose the nodeRef of the users home folder) we'll manually replace the commonly used
    // characters manually, namely, "@" and space rather than implementing a complete ISO9075 encoder!
    NSString *escapedUsername = [self.session.personIdentifier stringByReplacingOccurrencesOfString:@"@" withString:@"_x0040_"];
    escapedUsername = [escapedUsername stringByReplacingOccurrencesOfString:@" " withString:@"_x0020_"];
    
    NSString *searchQuery = [NSString stringWithFormat:@"SELECT * FROM cmis:folder WHERE CONTAINS ('QNAME:\"app:company_home/app:user_homes/cm:%@\"')", escapedUsername];
    
    request = [self.searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *array, NSError *error) {
        if (error)
        {
            completionBlock(nil, error);
        }
        else
        {
            AlfrescoFolder *myFilesFolder = array.firstObject;
            completionBlock(myFilesFolder, error);
        }
    }];
    
    return request;
}

@end

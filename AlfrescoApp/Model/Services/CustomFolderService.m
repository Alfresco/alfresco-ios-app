/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) AlfrescoSearchService *searchService;

@property (nonatomic, strong) AlfrescoFolder *sharedFilesFolder;
@property (nonatomic, strong) AlfrescoFolder *myFilesFolder;

@end

@implementation CustomFolderService

- (instancetype)initWithSession:(id<AlfrescoSession>)session
{
    self = [self init];
    if (self)
    {
        _session = session;
    }
    return self;
}

- (void)createAlfrescoServices
{
    self.documentFolderService = self.documentFolderService ?: [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    self.searchService = self.searchService ?: [[AlfrescoSearchService alloc] initWithSession:self.session];
}

- (AlfrescoRequest *)retrieveSharedFilesFolderWithCompletionBlock:(AlfrescoFolderCompletionBlock)completionBlock
{
    AlfrescoRequest *request = nil;
    
    if (self.sharedFilesFolder)
    {
        completionBlock(self.sharedFilesFolder, nil);
    }
    else
    {
        [self createAlfrescoServices];

        NSString *searchQuery = @"SELECT * FROM cmis:folder WHERE CONTAINS ('QNAME:\"app:company_home/app:shared\"')";
        request = [self.searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *array, NSError *error) {
            if (error)
            {
                self.sharedFilesFolder = nil;
                completionBlock(nil, error);
            }
            else
            {
                self.sharedFilesFolder = array.firstObject;
                completionBlock(array.firstObject, nil);
            }
        }];
    }
    return request;
}

- (AlfrescoRequest *)retrieveMyFilesFolderWithCompletionBlock:(AlfrescoFolderCompletionBlock)completionBlock
{
    __block AlfrescoRequest *request = nil;
    
    if (self.myFilesFolder)
    {
        completionBlock(self.myFilesFolder, nil);
    }
    else
    {
        [self createAlfrescoServices];
        
        // Fallback option: attempt to retrieve the home folder using the username
        void (^fallbackHomeFolderRetrieval)(void) = ^{
            NSString *escapedUsername = [[self.session.personIdentifier stringByReplacingOccurrencesOfString:@"@" withString:@"_x0040_"] stringByReplacingOccurrencesOfString:@" " withString:@"_x0020_"];
            NSString *searchQuery = [NSString stringWithFormat:@"SELECT * FROM cmis:folder WHERE CONTAINS ('QNAME:\"app:company_home/app:user_homes/cm:%@\"')", escapedUsername];
            
            request = [self.searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *array, NSError *error) {
                if (error)
                {
                    self.myFilesFolder = nil;
                    completionBlock(nil, error);
                }
                else
                {
                    self.myFilesFolder = array.firstObject;
                    completionBlock(array.firstObject, error);
                }
            }];
        };

        // Alfresco versions 5.0 and newer support retrieving the home folder via cmis:item support
        request = [self.documentFolderService retrieveHomeFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
            if (error)
            {
                fallbackHomeFolderRetrieval();
            }
            else
            {
                self.myFilesFolder = folder;
                completionBlock(folder, error);
            }
        }];
        
        if (!request)
        {
            fallbackHomeFolderRetrieval();
        }
    }
    
    return request;
}

@end

/*******************************************************************************
 * Copyright (C) 2005-2018 Alfresco Software Limited.
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

#import "SearchIndexService.h"
#import "CustomFolderService.h"

static NSString * const kJSONMimeType = @"application/json";
static NSString * const kSearchResultsIndexFileName = @"MobileSearchResultsIndex.json";

@interface SearchIndexService ()

@property (strong, nonatomic) NSMutableDictionary *searchIndexDict;
@property (nonatomic, strong) id<AlfrescoSession> session;

@end

@implementation SearchIndexService

- (void)parseSearchResults:(NSArray *)searchResults session:(id<AlfrescoSession>)session
{
    self.session = session;
}

- (void)saveSearchIndexInMyFiles
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.searchIndexDict options:NSJSONWritingPrettyPrinted error:&error];
    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithData:jsonData mimeType:kJSONMimeType];
    CustomFolderService *customFolderService = [[CustomFolderService alloc] initWithSession:self.session];
    [customFolderService retrieveMyFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        if(folder)
        {
            AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
            [documentService retrieveChildrenInFolder:folder completionBlock:^(NSArray *array, NSError *error) {
                if(array.count)
                {
                    AlfrescoDocument *searchIndexDoc = nil;
                    for(AlfrescoNode *node in array)
                    {
                        if(([node.name isEqualToString:kSearchResultsIndexFileName]) && node.isDocument)
                        {
                            searchIndexDoc = (AlfrescoDocument *)node;
                        }
                    }
                    
                    if(searchIndexDoc)
                    {
                        // should update the index file
                    }
                    else
                    {
                        [documentService createDocumentWithName:kSearchResultsIndexFileName inParentFolder:folder contentFile:contentFile properties:nil completionBlock:^(AlfrescoDocument *document, NSError *error) {
                            if(error)
                            {
                                AlfrescoLogError(@"Failed to upload search results index with error: %@", error);
                            }
                        } progressBlock:nil];
                    }
                }
            }];
        }
    }];
}

@end

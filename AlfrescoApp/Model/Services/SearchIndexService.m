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

static NSString * const kSearchIndexEntryPropertyList = @"list";
static NSString * const kSearchIndexEntryPropertyEntries = @"entries";
static NSString * const kSearchIndexEntryPropertyEntry = @"entry";
static NSString * const kSearchIndexEntryPropertyName = @"name";
static NSString * const kSearchIndexEntryPropertyID = @"id";
static NSString * const kSearchIndexEntryPropertyNodeType = @"nodeType";
static NSString * const kSearchIndexEntryPropertyIsFile = @"isFile";
static NSString * const kSearchIndexEntryPropertyParentID = @"parentId";
static NSString * const kSearchIndexEntryPropertyTrue = @"true";
static NSString * const kSearchIndexEntryPropertyFalse = @"false";

@interface SearchIndexService ()

@property (strong, nonatomic) NSDictionary *searchIndexDict;
@property (nonatomic, strong) id<AlfrescoSession> session;

@end

@implementation SearchIndexService

- (void)parseSearchResults:(NSArray *)searchResults session:(id<AlfrescoSession>)session
{
    self.session = session;
    
    if(searchResults.count)
    {
        NSMutableArray *entriesArr = [NSMutableArray array];
        for (AlfrescoDocument *document in searchResults)
        {
            NSDictionary *searchIndexEntry = [self searchIndexEntryFromDocument:document];
            [entriesArr addObject:@{kSearchIndexEntryPropertyEntry : searchIndexEntry}];
        }
        
        NSDictionary *entriesDict = @{kSearchIndexEntryPropertyEntries : entriesArr};
        self.searchIndexDict = @{kSearchIndexEntryPropertyList : entriesDict};
    }
}


#pragma mark -
#pragma mark Private interface

- (NSDictionary *)searchIndexEntryFromDocument:(AlfrescoDocument *)document
{
    NSMutableDictionary *searchIndexEntryDict = [NSMutableDictionary dictionary];
    searchIndexEntryDict[kSearchIndexEntryPropertyName] = document.name;
    searchIndexEntryDict[kSearchIndexEntryPropertyID] = [self normalizedNodeIdentifierForIdentifierString:document.identifier];
    searchIndexEntryDict[kSearchIndexEntryPropertyNodeType] = document.type;
    searchIndexEntryDict[kSearchIndexEntryPropertyIsFile] = document.isDocument ? kSearchIndexEntryPropertyTrue : kSearchIndexEntryPropertyFalse;
    
    return searchIndexEntryDict;
}

- (NSString *)normalizedNodeIdentifierForIdentifierString:(NSString *)identifierString
{
    NSUInteger indexOfVersionSeparator = [identifierString rangeOfString:@";"].location;
    return [identifierString substringToIndex:indexOfVersionSeparator];
}

- (void)appendSearchIndexDataEntriesFromURL:(NSURL *)fileURL
{
    if (fileURL)
    {
        NSString *jsonString = [[NSString alloc] initWithContentsOfURL:fileURL
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];
        
        NSDictionary *existingSearchIndexDict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                                                options:NSJSONReadingMutableContainers
                                                                                  error:nil];
        NSMutableArray *existingEntriesArr = existingSearchIndexDict[kSearchIndexEntryPropertyList][kSearchIndexEntryPropertyEntries];
        NSSet *existingEntriesSet = [NSSet setWithArray:existingEntriesArr];
        
        NSArray *additionalEntriesArr = self.searchIndexDict[kSearchIndexEntryPropertyList][kSearchIndexEntryPropertyEntries];
        
        NSIndexSet *unionResult = [NSIndexSet indexSet];
        unionResult = [additionalEntriesArr indexesOfObjectsPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return ![existingEntriesSet containsObject:obj[kSearchIndexEntryPropertyEntry][kSearchIndexEntryPropertyID]] &&
                   ![obj[kSearchIndexEntryPropertyEntry][kSearchIndexEntryPropertyName] isEqualToString:kSearchResultsIndexFileName];
        }];
        
        [existingEntriesArr addObjectsFromArray:[additionalEntriesArr objectsAtIndexes:unionResult]];
        
        NSDictionary *entriesDict = @{kSearchIndexEntryPropertyEntries : existingEntriesArr};
        self.searchIndexDict = @{kSearchIndexEntryPropertyList : entriesDict};
    }
    else
    {
        AlfrescoLogError(@"Search index cannot be found");
    }
}

- (AlfrescoContentFile *)contentFileFromSearchResultsIndexDict
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.searchIndexDict options:NSJSONWritingPrettyPrinted error:&error];
    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithData:jsonData mimeType:kJSONMimeType];
    return contentFile;
}

- (void)saveSearchIndexInMyFiles
{
    CustomFolderService *customFolderService = [[CustomFolderService alloc] initWithSession:self.session];
    [customFolderService retrieveMyFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        if(folder)
        {
            AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
            [documentService retrieveChildrenInFolder:folder completionBlock:^(NSArray *array, NSError *error) {
                if(!error)
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
                        [documentService retrieveContentOfDocument:searchIndexDoc completionBlock:^(AlfrescoContentFile *contentFile, NSError *error) {
                            if(!error)
                            {
                                [self appendSearchIndexDataEntriesFromURL:contentFile.fileUrl];
                                [documentService updateContentOfDocument:searchIndexDoc contentFile:[self contentFileFromSearchResultsIndexDict] completionBlock:^(AlfrescoDocument *document, NSError *error) {
                                    if(error)
                                    {
                                        AlfrescoLogError(@"Failed to upload search results index with error: %@", error);
                                    }
                                } progressBlock:nil];
                            }
                        } progressBlock:nil];
                    }
                    else
                    {
                        [documentService createDocumentWithName:kSearchResultsIndexFileName inParentFolder:folder contentFile:[self contentFileFromSearchResultsIndexDict] properties:nil completionBlock:^(AlfrescoDocument *document, NSError *error) {
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

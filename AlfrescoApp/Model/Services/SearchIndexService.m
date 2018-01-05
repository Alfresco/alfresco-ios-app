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

@property (nonatomic, strong) NSDictionary                  *searchIndexDict;
@property (nonatomic, strong) id<AlfrescoSession>           session;
@property (nonatomic, strong) CustomFolderService           *customFolderService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;

@end

@implementation SearchIndexService

- (void)parseSearchResults:(NSArray *)searchResults session:(id<AlfrescoSession>)session
{
    self.session = session;
    
    NSMutableArray *newEntriesArr = [NSMutableArray array];
    for (AlfrescoDocument *document in searchResults)
    {
        NSDictionary *searchIndexEntry = [self searchIndexEntryFromDocument:document];
        [newEntriesArr addObject:@{kSearchIndexEntryPropertyEntry : searchIndexEntry}];
    }
    
    NSMutableArray *existingEntriesArr = self.searchIndexDict[kSearchIndexEntryPropertyList][kSearchIndexEntryPropertyEntries];
    self.searchIndexDict = [self searchIndexDictionaryByMergingNewEntries:newEntriesArr
                                                        toExistingEntries:existingEntriesArr];
}

- (void)saveSearchIndexInMyFiles
{
    self.customFolderService = [[CustomFolderService alloc] initWithSession:self.session];
    
    __weak typeof(self) weakSelf = self;
    [self.customFolderService retrieveMyFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        if(folder)
        {
            __strong typeof(self) strongSelf = weakSelf;
            
            strongSelf.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:strongSelf.session];
            [strongSelf.documentService retrieveChildrenInFolder:folder completionBlock:^(NSArray *array, NSError *error) {
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
                        [weakSelf.documentService retrieveContentOfDocument:searchIndexDoc completionBlock:^(AlfrescoContentFile *contentFile, NSError *error) {
                            if(!error)
                            {
                                [weakSelf appendSearchIndexDataEntriesFromURL:contentFile.fileUrl];
                                [weakSelf.documentService updateContentOfDocument:searchIndexDoc contentFile:[self contentFileFromSearchResultsIndexDict] completionBlock:^(AlfrescoDocument *document, NSError *error) {
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
                        [weakSelf.documentService createDocumentWithName:kSearchResultsIndexFileName
                                                          inParentFolder:folder
                                                             contentFile:[self contentFileFromSearchResultsIndexDict]
                                                              properties:nil
                                                         completionBlock:^(AlfrescoDocument *document, NSError *error) {
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

- (NSDictionary *)searchIndexDictionaryByMergingNewEntries:(NSArray *)newSearchIndexEntriesArr
                                         toExistingEntries:(NSArray *)existingSearchIndexEntriesArr {
    NSSet *existingEntriesSet = [NSSet setWithArray:existingSearchIndexEntriesArr];
    
    NSIndexSet *unionResult = [NSIndexSet indexSet];
    unionResult = [newSearchIndexEntriesArr indexesOfObjectsPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return ![existingEntriesSet containsObject:obj[kSearchIndexEntryPropertyEntry][kSearchIndexEntryPropertyID]] &&
        ![obj[kSearchIndexEntryPropertyEntry][kSearchIndexEntryPropertyName] isEqualToString:kSearchResultsIndexFileName];
    }];
    
    NSMutableArray *existingEntries = [NSMutableArray arrayWithArray:existingSearchIndexEntriesArr];
    [existingEntries addObjectsFromArray:[newSearchIndexEntriesArr objectsAtIndexes:unionResult]];
    
    NSDictionary *entriesDict = @{kSearchIndexEntryPropertyEntries : existingEntries};
    return @{kSearchIndexEntryPropertyList : entriesDict};
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
        NSArray *newEntriesArr = self.searchIndexDict[kSearchIndexEntryPropertyList][kSearchIndexEntryPropertyEntries];
        
        self.searchIndexDict = [self searchIndexDictionaryByMergingNewEntries:newEntriesArr
                                                            toExistingEntries:existingEntriesArr];
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

@end

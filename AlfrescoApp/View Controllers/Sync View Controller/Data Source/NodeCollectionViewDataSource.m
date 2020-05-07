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

#import "NodeCollectionViewDataSource.h"
#import "DocumentCollectionViewDataSource.h"
#import "FolderCollectionViewDataSource.h"

@implementation NodeCollectionViewDataSource

+ (void)collectionViewDataSourceWithNodeRef:(NSString *)nodeRef session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext
{
    AlfrescoDocumentFolderService *documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    
    [documentFolderService retrieveNodeWithIdentifier:nodeRef completionBlock:^(AlfrescoNode *nodeRefNode, NSError *nodeRefError) {
        if (nodeRefError)
        {
            [delegate requestFailedWithError:nodeRefError stringFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found")];
        }
        else
        {
            if ([nodeRefNode isKindOfClass:[AlfrescoFolder class]])
            {
                FolderCollectionViewDataSource *folderDataSource = [[FolderCollectionViewDataSource alloc] initWithFolder:(AlfrescoFolder *)nodeRefNode folderDisplayName:nil folderPermissions:nil session:session delegate:delegate listingContext:listingContext];
                [delegate setNodeDataSource:folderDataSource];
            }
            else if([nodeRefNode isKindOfClass:[AlfrescoDocument class]])
            {
                DocumentCollectionViewDataSource *documentDataSource = [[DocumentCollectionViewDataSource alloc] initWithDocument:(AlfrescoDocument *)nodeRefNode session:session delegate:delegate];
                [delegate setNodeDataSource:documentDataSource];
                [delegate selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            }
        }
    }];
}

@end

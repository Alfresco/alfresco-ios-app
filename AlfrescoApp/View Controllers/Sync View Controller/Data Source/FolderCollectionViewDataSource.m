/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

#import "FolderCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"

@implementation FolderCollectionViewDataSource

- (instancetype)initWithFolder:(AlfrescoFolder *)folder folderDisplayName:(NSString *)folderDisplayName folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    AlfrescoNode *folderNode = nil;
    if(folder)
    {
        folderNode = folder;
    }
    else
    {
        folderNode = [session rootFolder];
        if(!folderNode)
        {
            __weak typeof(self) weakSelf = self;
            [self.documentService retrieveRootFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
                if (folder)
                {
                    [weakSelf setupWithParentNode:folder folderDisplayName:folderDisplayName folderPermissions:permissions session:session delegate:delegate];
                }
                else
                {
                    [delegate requestFailedWithError:error stringFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found")];
                }
            }];
        }
    }
    
    if(folderNode)
    {
        [self setupWithParentNode:folderNode folderDisplayName:folderDisplayName folderPermissions:permissions session:session delegate:delegate];
    }
    
    return self;
}

- (instancetype)initWithFolderRef:(NSString *)folderRef folderDisplayName:(NSString *)folderDisplayName folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    AlfrescoDocumentFolderService *documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    
    [documentFolderService retrieveNodeWithIdentifier:folderRef completionBlock:^(AlfrescoNode *nodeRefNode, NSError *nodeRefError) {
        if (nodeRefError)
        {
            [delegate requestFailedWithError:nodeRefError stringFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found")];
        }
        else
        {
            if ([nodeRefNode isKindOfClass:[AlfrescoFolder class]])
            {
                [self setupWithParentNode:nodeRefNode folderDisplayName:folderDisplayName folderPermissions:permissions session:session delegate:delegate];
            }
            else if([nodeRefNode isKindOfClass:[AlfrescoDocument class]])
            {
//                self.collectionViewData = [NSMutableArray arrayWithObject:nodeRefNode];
//                [self hideHUD];
//                [self hidePullToRefreshView];
//                self.folderDisplayName = nodeRefNode.title;
//                [self reloadCollectionView];
//                [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            }
        }
    }];
    
    return self;
}

- (instancetype)initWithFolderPath:(NSString *)folderPath folderDisplayName:(NSString *)folderDisplayName folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    AlfrescoDocumentFolderService *documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    
    [documentFolderService retrieveNodeWithFolderPath:folderPath completionBlock:^(AlfrescoNode *folderPathNode, NSError *folderPathNodeError) {
        if (folderPathNodeError)
        {
            [delegate requestFailedWithError:folderPathNodeError stringFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found")];
        }
        else
        {
            if ([folderPathNode isKindOfClass:[AlfrescoFolder class]])
            {
                [self setupWithParentNode:folderPathNode folderDisplayName:folderDisplayName folderPermissions:permissions session:session delegate:delegate];
            }
            else
            {
                AlfrescoLogError(@"Node returned wwith path; %@, is not a folder node", folderPath);
            }
        }
    }];
    
    return self;
}

- (void)setupWithFolderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)folderDisplayName
{
    self.parentFolderPermissions = permissions;
    if(folderDisplayName)
    {
        self.screenTitle = folderDisplayName;
    }
}

- (void)setupWithParentNode:(AlfrescoNode *)node folderDisplayName:(NSString *)folderDisplayName folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    [self setupWithParentNode:node session:session delegate:delegate];
    [self setupWithFolderPermissions:permissions folderDisplayName:folderDisplayName];
}

@end

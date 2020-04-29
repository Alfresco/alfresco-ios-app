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

#import "FolderCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"
#import "CustomFolderService.h"

@interface FolderCollectionViewDataSource()

@property (nonatomic, strong) CustomFolderService *customFolderService;

@end

@implementation FolderCollectionViewDataSource

- (instancetype)initWithFolder:(AlfrescoFolder *)folder folderDisplayName:(NSString *)folderDisplayName folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    
    self.shouldAllowMultiselect = YES;
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
            self.session = session;
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

- (instancetype)initWithFolderPath:(NSString *)folderPath folderDisplayName:(NSString *)folderDisplayName folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    __weak typeof(self) weakSelf = self;
    self.session = session;
    self.shouldAllowMultiselect = YES;
    
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    
    [self.documentService retrieveNodeWithFolderPath:folderPath completionBlock:^(AlfrescoNode *folderPathNode, NSError *folderPathNodeError) {
        if (folderPathNodeError)
        {
            [delegate requestFailedWithError:folderPathNodeError stringFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found")];
        }
        else
        {
            if ([folderPathNode isKindOfClass:[AlfrescoFolder class]])
            {
                [weakSelf setupWithParentNode:folderPathNode folderDisplayName:folderDisplayName folderPermissions:permissions session:session delegate:delegate];
            }
            else
            {
                AlfrescoLogError(@"Node returned wwith path; %@, is not a folder node", folderPath);
            }
        }
    }];
    
    return self;
}

- (instancetype)initWithCustomFolderType:(CustomFolderServiceFolderType)folderType folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.session = session;
    self.shouldAllowMultiselect = YES;
    self.delegate = delegate;
    
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    
    if(displayName)
    {
        self.screenTitle = displayName;
    }
    self.customFolderService = [[CustomFolderService alloc] initWithSession:self.session];
    __weak typeof (self) weakSelf = self;
    AlfrescoFolderCompletionBlock completionBlock = ^(AlfrescoFolder *folder, NSError *error) {
        if (error)
        {
            [delegate requestFailedWithError:error stringFormat:nil];
        }
        else if (folder == nil)
        {
            [delegate requestFailedWithError:nil stringFormat:NSLocalizedString(@"error.alfresco.folder.notfound", @"Folder not found")];
        }
        else
        {
            [weakSelf setupWithParentNode:folder folderDisplayName:displayName folderPermissions:nil session:session delegate:delegate];
        }
    };
    
    switch (folderType)
    {
        case CustomFolderServiceFolderTypeMyFiles:
        {
            [self.customFolderService retrieveMyFilesFolderWithCompletionBlock:completionBlock];
            break;
        }
        case CustomFolderServiceFolderTypeSharedFiles:
        {
            [self.customFolderService retrieveSharedFilesFolderWithCompletionBlock:completionBlock];
            break;
        }
            
        default:
            break;
    }
    
    return self;
}

- (void)setupWithFolderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)folderDisplayName
{
    if(permissions)
    {
        self.parentFolderPermissions = permissions;
    }
    else
    {
        [self retrieveAndSetPermissionsOfCurrentFolder];
    }
    
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

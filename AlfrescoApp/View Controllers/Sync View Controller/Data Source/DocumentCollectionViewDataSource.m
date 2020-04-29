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

#import "DocumentCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"

@interface DocumentCollectionViewDataSource ()

@property (nonatomic, strong) NSString *documentPath;
@property (nonatomic, strong) AlfrescoDocument *document;

@end

@implementation DocumentCollectionViewDataSource

- (instancetype)initWithDocumentPath:(NSString *)documentPath session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.documentPath = documentPath;
    self.session = session;
    self.delegate = delegate;
    
    self.shouldAllowMultiselect = YES;
    __weak typeof(self) weakSelf = self;
    [self.documentService retrieveNodeWithFolderPath:documentPath completionBlock:^(AlfrescoNode *node, NSError *error) {
        if (error)
        {
            [weakSelf.delegate requestFailedWithError:error stringFormat:nil];
        }
        else if (node == nil)
        {
            [weakSelf.delegate requestFailedWithError:nil stringFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found")];
        }
        else
        {
            weakSelf.document = (AlfrescoDocument *)node;
            [weakSelf setupWithDocument:weakSelf.document];
        }
    }];
    
    return self;
}

- (instancetype)initWithDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.session = session;
    self.delegate = delegate;
    self.document = document;
    [self setupWithDocument:self.document];
    
    return self;
}

- (void)setupWithDocument:(AlfrescoDocument *)document
{
    self.dataSourceCollection = [NSMutableArray arrayWithObject:document];
    [self.delegate dataSourceUpdated];
    [self.delegate selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
}

- (void)reloadDataSource
{
    [self setupWithDocument:self.document];
}

@end

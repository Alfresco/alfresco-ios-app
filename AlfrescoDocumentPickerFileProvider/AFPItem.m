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

#import "AFPItem.h"
#import "UserAccount.h"
#import "AFPItemMetadata.h"
#import "AFPItemIdentifier.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "AlfrescoNode+Utilities.h"
#import "RealmSyncNodeInfo.h"
#import "AlfrescoFileManager+Extensions.h"

@interface AFPItem()

@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) AlfrescoNode *node;

@property (nonatomic, readwrite, copy) NSString *itemIdentifier;
@property (nonatomic, readwrite, copy) NSString *parentItemIdentifier;
@property (nonatomic, readwrite, copy) NSString *filename;
@property (nonatomic, readwrite, copy) NSDate *creationDate;
@property (nonatomic, readwrite, copy) NSDate *contentModificationDate;
@property (nonatomic, readwrite, copy) NSNumber *documentSize;
@property (nonatomic, readwrite, copy) NSString *typeIdentifier;

@end

@implementation AFPItem

- (instancetype)initWithRootContainterItem
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.itemIdentifier = NSFileProviderRootContainerItemIdentifier;
    self.filename = @"";
    self.typeIdentifier = @"public.folder";
    
    
    return self;
}

- (instancetype)initWithUserAccount:(UserAccount *)account
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.account = account;
    self.parentItemIdentifier = NSFileProviderRootContainerItemIdentifier;
    self.itemIdentifier = [AFPItemIdentifier itemIdentifierForSuffix:nil andAccount:account];
    self.filename = self.account.accountDescription;
    self.typeIdentifier = @"public.folder";
    
    return self;
}

- (instancetype)initWithLocalFilesPath:(NSString *)path
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.parentItemIdentifier = kFileProviderLocalFilesPrefix;
    self.itemIdentifier = [AFPItemIdentifier itemIdentifierForLocalFilename:[path lastPathComponent]];
    self.filename = [path lastPathComponent];
    NSError *attributesError = nil;
    NSDictionary *attributes = [[AlfrescoFileManager sharedManager] attributesOfItemAtPath:path error:&attributesError];
    if(!attributesError)
    {
        self.documentSize = attributes[kAlfrescoFileSize];
    }
    self.typeIdentifier = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)CFBridgingRetain([self.filename pathExtension]), NULL));
    
    return self;
}

- (instancetype)initWithItemMetadata:(AFPItemMetadata *)itemMetadata
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    if([itemMetadata.identifier isEqualToString:kFileProviderLocalFilesPrefix])
    {
        self.parentItemIdentifier = NSFileProviderRootContainerItemIdentifier;
    }
    else
    {
        self.parentItemIdentifier = itemMetadata.parentFolder.identifier;
    }
    self.itemIdentifier = itemMetadata.identifier;
    self.filename = itemMetadata.name;
    self.node = itemMetadata.alfrescoNode;
    [self updateMetadataWithNodeInfo];
    
    return self;
}

- (instancetype)initWithSyncedNode:(RealmSyncNodeInfo *)node parentItemIdentifier:(NSFileProviderItemIdentifier)parentItemIdentifier
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.parentItemIdentifier = parentItemIdentifier;
    self.node = node.alfrescoNode;
    self.filename = node.title;
    
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:parentItemIdentifier];
    self.itemIdentifier = [AFPItemIdentifier itemIdentifierForSyncNode:node forAccountIdentifier:accountIdentifier];
    [self updateMetadataWithNodeInfo];
    
    return self;
}

- (instancetype)initWithImportedDocumentAtURL:(NSURL *)fileURL resourceValues:(NSDictionary *)resourceValues parentItemIdentifier:(NSFileProviderItemIdentifier)parentItemIdentifier
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.parentItemIdentifier = parentItemIdentifier;
    self.filename = resourceValues[NSURLNameKey];
    self.creationDate = resourceValues[NSURLCreationDateKey];
    self.contentModificationDate = resourceValues[NSURLContentModificationDateKey];
    self.typeIdentifier = resourceValues[NSURLTypeIdentifierKey];
    self.documentSize = resourceValues[NSURLTotalFileSizeKey];
    self.itemIdentifier = [AFPItemIdentifier itemIdentifierForFilename:self.filename andFileParentIdentifier:parentItemIdentifier];
    
    return self;
}

- (NSURL *)fileURL
{
    // in this implementation, all paths are structured as <base storage directory>/<item identifier>/<item file name>
    NSFileProviderManager *manager = [NSFileProviderManager defaultManager];
    NSURL *perItemDirectory = [manager.documentStorageURL URLByAppendingPathComponent:self.itemIdentifier isDirectory:YES];
    NSURL *fileURL = [perItemDirectory URLByAppendingPathComponent:self.filename isDirectory:NO];
    return fileURL;
}

- (BOOL)isDownloaded
{
    if (_documentSize.unsignedLongValue)
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)isMostRecentVersionDownloaded
{
    return [self isDownloaded];
}

#pragma mark - Private methods

- (void)updateMetadataWithNodeInfo
{
    if(self.node.isDocument)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *pathToFile = self.fileURL.path;
        
        if ([fileManager fileExistsAtPath:pathToFile])
        {
            AlfrescoDocument *document = (AlfrescoDocument *)self.node;
            self.documentSize = [NSNumber numberWithLongLong:document.contentLength];
        }
        
        self.typeIdentifier = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)CFBridgingRetain([self.node.name pathExtension]), NULL));
    }
    else
    {
        self.typeIdentifier = @"public.folder";
    }
}

#pragma mark - NSFileProviderItemProtocol
- (NSFileProviderItemCapabilities)capabilities
{
    if(self.node.isDocument || self.parentItemIdentifier == kFileProviderLocalFilesPrefix)
    {
        return NSFileProviderItemCapabilitiesAllowsAll;
    }
    return NSFileProviderItemCapabilitiesAllowsAll | NSFileProviderItemCapabilitiesAllowsAddingSubItems | NSFileProviderItemCapabilitiesAllowsContentEnumerating;
}

@end

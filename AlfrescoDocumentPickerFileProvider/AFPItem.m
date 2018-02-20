/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
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

@interface AFPItem()

@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) AlfrescoNode *node;

@property (nonatomic, readwrite, copy) NSString *parentItemIdentifier;
@property (nonatomic, readwrite, copy) NSString *itemIdentifier;
@property (nonatomic, readwrite, copy) NSString *filename;
@property (nonatomic, readwrite, getter=isDownloaded) BOOL downloaded;

@end

@implementation AFPItem

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
    
    return self;
}

- (instancetype)initWithItemMetadata:(AFPItemMetadata *)itemMetadata
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.parentItemIdentifier = itemMetadata.parentFolder.identifier;
    self.itemIdentifier = itemMetadata.identifier;
    self.filename = itemMetadata.name;
    self.node = itemMetadata.alfrescoNode;
    
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
    self.downloaded = YES;
    
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:parentItemIdentifier];
    self.itemIdentifier = [AFPItemIdentifier itemIdentifierForSyncNode:node forAccountIdentifier:accountIdentifier];
    
    return self;
}

#pragma mark - NSFileProviderItemProtocol
- (NSFileProviderItemCapabilities)capabilities
{
    return NSFileProviderItemCapabilitiesAllowsAll;
}

- (NSString *)typeIdentifier
{
    if(self.node.isDocument)
    {
        NSString *filename = self.node.name;
        NSString *UTI = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)CFBridgingRetain([filename pathExtension]), NULL));
        return UTI;
    }
    return @"public.folder";
}

- (BOOL)isDownloaded
{
    return _downloaded;
}

- (NSNumber *)documentSize
{
    NSNumber *size = [NSNumber numberWithLongLong:0];
    if(self.node.isDocument)
    {
        AlfrescoDocument *document = (AlfrescoDocument *)self.node;
        size = [NSNumber numberWithLongLong:document.contentLength];
    }
    return size;
}

@end

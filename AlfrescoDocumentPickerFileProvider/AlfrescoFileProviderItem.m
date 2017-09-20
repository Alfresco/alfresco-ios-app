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

#import "AlfrescoFileProviderItem.h"
#import "UserAccount.h"
#import "FileProviderAccountInfo.h"
#import "AlfrescoFileProviderItemIdentifier.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface AlfrescoFileProviderItem()

@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) NSString *privateParentItemIdentifier;
@property (nonatomic, strong) NSString *privateItemIdentifier;
@property (nonatomic, strong) NSString *privateFilename;

@end

@implementation AlfrescoFileProviderItem

- (instancetype)initWithUserAccount:(UserAccount *)account
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.account = account;
    self.privateParentItemIdentifier = NSFileProviderRootContainerItemIdentifier;
    self.privateItemIdentifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:nil andAccount:account];
    self.privateFilename = self.account.accountDescription;
    
    return self;
}

- (instancetype)initWithAccountInfo:(FileProviderAccountInfo *)accountInfo
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.privateParentItemIdentifier = accountInfo.parentFolder.identifier? : accountInfo.accountIdentifier;
    self.privateItemIdentifier = accountInfo.identifier;
    self.privateFilename = accountInfo.name;
    
    return self;
}

- (instancetype)initWithAlfrescoNode:(AlfrescoNode *)node parentItemIdentifier:(NSFileProviderItemIdentifier)parentItemIdentifier
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.privateParentItemIdentifier = parentItemIdentifier;
    NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedFolderIdenfitier:parentItemIdentifier];
    self.privateItemIdentifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForFolderRef:[self nodeRefWithoutVersionID:node.identifier] andAccountIdentifier:accountIdentifier];
    self.privateFilename = node.name;
    self.node = node;
    
    return self;
}

#pragma mark - NSFileProviderItemProtocol
- (NSFileProviderItemIdentifier)itemIdentifier
{
    return self.privateItemIdentifier;
}

- (NSFileProviderItemCapabilities)capabilities
{
    return NSFileProviderItemCapabilitiesAllowsAll;
}

- (NSString *)filename
{
    return self.privateFilename;
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

- (NSFileProviderItemIdentifier)parentItemIdentifier
{
    return self.privateParentItemIdentifier;
}

- (NSString *)nodeRefWithoutVersionID:(NSString *)originalIdentifier
{
    NSString *cleanNodeRef = nil;
    
    NSArray *strings = [originalIdentifier componentsSeparatedByString:@";"];
    if (strings.count > 0)
    {
        cleanNodeRef = strings[0];
    }
    else
    {
        cleanNodeRef = originalIdentifier;
    }
    
    return cleanNodeRef;
}

@end

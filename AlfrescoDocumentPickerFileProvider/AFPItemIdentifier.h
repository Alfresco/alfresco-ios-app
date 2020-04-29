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

#import <Foundation/Foundation.h>
@class UserAccount;
@class RealmSyncNodeInfo;

@interface AFPItemIdentifier : NSObject

+ (NSFileProviderItemIdentifier)getAccountIdentifierFromEnumeratedIdentifier:(NSFileProviderItemIdentifier)enumeratedIdentifier;
+ (NSFileProviderItemIdentifier)itemIdentifierForSuffix:(NSString *)suffix andAccount:(UserAccount *)account;
+ (NSFileProviderItemIdentifier)itemIdentifierForSuffix:(NSString *)suffix andAccountIdentifier:(NSString *)accountIdentifier;
+ (NSFileProviderItemIdentifier)itemIdentifierForLocalFilename:(NSString *)filename;
+ (NSFileProviderItemIdentifier)itemIdentifierForIdentifier:(NSString *)identifier typePath:(NSString *)typePath andAccountIdentifier:(NSString *)accountIdentifier;
+ (NSFileProviderItemIdentifier)itemIdentifierForFilename:(NSString *)filename andFileParentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier;
+ (AlfrescoFileProviderItemIdentifierType)itemIdentifierTypeForIdentifier:(NSString *)identifier;
+ (NSString *)alfrescoIdentifierFromItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier;
+ (NSString *)filenameFromItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier;
+ (NSFileProviderItemIdentifier)itemIdentifierForSyncNode:(RealmSyncNodeInfo *)syncNode forAccountIdentifier:(NSString *)accountIdentifier;

@end

/*
 ******************************************************************************
 * Copyright (C) 2005-2012 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile SDK.
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
 *****************************************************************************
 */

#import <Foundation/Foundation.h>
#import "AlfrescoPermissions.h"

/** The AlfrescoNode represents a node that's stored in the Alfresco repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@class CMISFolder, CMISObject, CMISDocument, CMISObjectData, CMISQueryResult;

extern NSString * const kAlfrescoPermissionsObjectKey;

@interface AlfrescoNode : NSObject <NSCoding>

/// The unique identifier of the node.
@property (nonatomic, strong, readonly) NSString *identifier;


/// The name of the node.
@property (nonatomic, strong, readonly) NSString *name;


/// The title of the node.
@property (nonatomic, strong, readonly) NSString *title;


/// The description of the node.
@property (nonatomic, strong, readonly) NSString *summary;


/// The object type of the node i.e. cm:content.
@property (nonatomic, strong, readonly) NSString *type;


/// The id of the user that created the node.
@property (nonatomic, strong, readonly) NSString *createdBy;


/// The date the node was created.
@property (nonatomic, strong, readonly) NSDate *createdAt;


/// The id of the user that last modified the node.
@property (nonatomic, strong, readonly) NSString *modifiedBy;


/// The date the node was last modified.
@property (nonatomic, strong, readonly) NSDate *modifiedAt;


/// A dictionary of AlfrescoProperty objects representing the properties stored on the node.
@property (nonatomic, strong, readonly) NSDictionary *properties;


/// The list of aspects the node has applied.
@property (nonatomic, strong, readonly) NSArray *aspects;


/// Specifies whether this node represents a folder.
@property (nonatomic, assign, readonly) BOOL isFolder;


/// Specifies whether this node represents a document.
@property (nonatomic, assign, readonly) BOOL isDocument;


/**---------------------------------------------------------------------------------------
 * @name Property and Aspect Getters.
 *  ---------------------------------------------------------------------------------------
 */

/** Returns the value of a property with the given name, nil will be returned if a property with the given name does not exist.
 
 @param propertyName The name of the property for which the value will be retrieved.
 */
- (id)propertyValueWithName:(NSString *)propertyName;


/** Determines whether the node has an aspect with the given name applied.
 
 @param aspectName The name of the aspect that will be searched for.
 */
- (BOOL)hasAspectWithName:(NSString *)aspectName;

- (id)initWithProperties:(NSDictionary *)properties;

@end

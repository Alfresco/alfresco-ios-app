/*
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
 */

#import <Foundation/Foundation.h>

// Binding type
typedef enum 
{
    CMISBindingTypeAtomPub,
    CMISBindingTypeCustom
} CMISBindingType;

// Base type
typedef enum
{
    CMISBaseTypeDocument,
    CMISBaseTypeFolder,
    CMISBaseTypeRelationship,
    CMISBaseTypePolicy
} CMISBaseType;

typedef enum
{
    CMISIncludeRelationshipNone,
    CMISIncludeRelationshipSource,
    CMISIncludeRelationshipTarget,
    CMISIncludeRelationshipBoth
} CMISIncludeRelationship;

// Property types
typedef enum
{
    CMISPropertyTypeBoolean = 0,
    CMISPropertyTypeId,
    CMISPropertyTypeInteger,
    CMISPropertyTypeDateTime,
    CMISPropertyTypeDecimal,
    CMISPropertyTypeHtml,
    CMISPropertyTypeString,
    CMISPropertyTypeUri
} CMISPropertyType;

// Property cardinality options
typedef enum
{
    CMISCardinalitySingle,
    CMISCardinalityMulti
} CMISCardinality;

// Property updatability options
typedef enum
{
    CMISUpdatabilityReadOnly,
    CMISUpdatabilityReadWrite,
    CMISUpdatabilityWhenCheckedOut,
    CMISUpdatabilityOnCreate
} CMISUpdatability;

// Allowable action type
typedef enum
{
    CMISActionCanDeleteObject,
    CMISActionCanUpdateProperties,
    CMISActionCanGetProperties,
    CMISActionCanGetObjectRelationships,
    CMISActionCanGetObjectParents,
    CMISActionCanGetFolderParent,
    CMISActionCanGetFolderTree,
    CMISActionCanGetDescendants,
    CMISActionCanMoveObject,
    CMISActionCanDeleteContentStream,
    CMISActionCanCheckOut,
    CMISActionCanCancelCheckOut,
    CMISActionCanCheckIn,
    CMISActionCanSetContentStream,
    CMISActionCanGetAllVersions,
    CMISActionCanAddObjectToFolder,
    CMISActionCanRemoveObjectFromFolder,
    CMISActionCanGetContentStream,
    CMISActionCanApplyPolicy,
    CMISActionCanGetAppliedPolicies,
    CMISActionCanRemovePolicy,
    CMISActionCanGetChildren,
    CMISActionCanCreateDocument,
    CMISActionCanCreateFolder,
    CMISActionCanCreateRelationship,
    CMISActionCanDeleteTree,
    CMISActionCanGetRenditions,
    CMISActionCanGetACL,
    CMISActionCanApplyACL
} CMISActionType;

// AllowableAction String Array, the objects defined MUST be in the same order as those in enum CMISActionType
#define CMISAllowableActionsArray @"canDeleteObject", @"canUpdateProperties", @"canGetProperties", \
    @"canGetObjectRelationships", @"canGetObjectParents", @"canGetFolderParent", @"canGetFolderTree", \
    @"canGetDescendants", @"canMoveObject", @"canDeleteContentStream", @"canCheckOut", \
    @"canCancelCheckOut",  @"canCheckIn", @"canSetContentStream", @"canGetAllVersions", \
    @"canAddObjectToFolder", @"canRemoveObjectFromFolder", @"canGetContentStream", @"canApplyPolicy", \
    @"canGetAppliedPolicies", @"canRemovePolicy", @"canGetChildren", @"canCreateDocument", @"canCreateFolder", \
    @"canCreateRelationship", @"canDeleteTree", @"canGetRenditions", @"canGetACL", @"canApplyACL", nil

// Extension Levels
typedef enum
{
    CMISExtensionLevelObject,
    CMISExtensionLevelProperties,
    CMISExtensionLevelAllowableActions
    // TODO expose the remaining extensions as they are implemented
    // CMISExtensionLevelAcl, CMISExtensionLevelPolicies, CMISExtensionLevelChangeEvent

} CMISExtensionLevel;

// UnfileObject
typedef enum
{
    CMISUnfile,
    CMISDeleteSingleFiled,
    CMISDelete,  // default
} CMISUnfileObject;

@interface CMISEnums : NSObject 

+ (NSString *)stringForIncludeRelationShip:(CMISIncludeRelationship)includeRelationship;
+ (NSString *)stringForUnfileObject:(CMISUnfileObject)unfileObject;

@end
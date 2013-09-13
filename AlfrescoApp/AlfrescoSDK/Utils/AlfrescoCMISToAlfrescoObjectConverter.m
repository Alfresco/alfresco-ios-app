/*******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
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
 ******************************************************************************/

#import "AlfrescoCMISToAlfrescoObjectConverter.h"
#import "CMISDocument.h"
#import "CMISSession.h"
#import "CMISQueryResult.h"
#import "CMISObjectConverter.h"
#import "CMISEnums.h"
#import "CMISConstants.h"
#import "CMISQueryResult.h"
#import "AlfrescoActivityEntry.h"
#import "AlfrescoComment.h"
#import "AlfrescoProperty.h"
#import "AlfrescoPermissions.h"
#import "AlfrescoErrors.h"
#import <objc/runtime.h>
#import "AlfrescoInternalConstants.h"
#import "AlfrescoRepositoryCapabilities.h"
#import "AlfrescoRepositorySession.h"
#import "AlfrescoCloudSession.h"
#import "AlfrescoCMISUtil.h"
#import "AlfrescoCMISFolder.h"
#import "AlfrescoCMISDocument.h"

@interface AlfrescoCMISToAlfrescoObjectConverter ()
@property (nonatomic, assign) BOOL isCloud;
@property (nonatomic, strong)id<AlfrescoSession>session;
@end

@implementation AlfrescoCMISToAlfrescoObjectConverter

- (id)initWithSession:(id<AlfrescoSession>)session
{
    if (self = [super init])
    {
        self.session = session;
        if ([self.session isKindOfClass:[AlfrescoCloudSession class]])
        {
            self.isCloud = YES;
        }
        else
        {
            self.isCloud = NO;
        }
    }
    
    return self;
}

- (AlfrescoRepositoryInfo *)repositoryInfoFromCMISSession:(CMISSession *)cmisSession
{
    NSMutableDictionary *repoDictionary = [NSMutableDictionary dictionary];
    NSString *productName = cmisSession.repositoryInfo.productName;
    NSString *identifier = cmisSession.repositoryInfo.identifier;
    NSString *summary = cmisSession.repositoryInfo.desc;
    NSString *version = cmisSession.repositoryInfo.productVersion;
    NSArray *versionArray = [version componentsSeparatedByString:@"."];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSNumber *majorVersionNumber = [formatter numberFromString:[versionArray objectAtIndex:0]];
    NSNumber *minorVersionNumber = [formatter numberFromString:[versionArray objectAtIndex:1]];
    NSArray *buildArray = [[versionArray objectAtIndex:2] componentsSeparatedByString:@"("];
    NSNumber *maintenanceVersion = [formatter numberFromString:[[buildArray objectAtIndex:0] stringByReplacingOccurrencesOfString:@" " withString:@""]];
    NSString *buildNumber =  [[buildArray objectAtIndex:1] stringByReplacingOccurrencesOfString:@")" withString:@""];   
    

    
    NSMutableDictionary *capabilities = [NSMutableDictionary dictionary];
    if (self.isCloud)
    {
        [repoDictionary setObject:kAlfrescoCloudEdition forKey:kAlfrescoRepositoryEdition];
        [repoDictionary setObject:identifier forKey:kAlfrescoRepositoryIdentifier];
        [repoDictionary setObject:summary forKey:kAlfrescoRepositorySummary];
        [repoDictionary setObject:productName forKey:kAlfrescoRepositoryName];
        
        [capabilities setValue:[NSNumber numberWithBool:YES] forKey:kAlfrescoCapabilityLike];
        [capabilities setValue:[NSNumber numberWithBool:YES] forKey:kAlfrescoCapabilityCommentsCount];
    }
    else
    {
        [repoDictionary setObject:productName forKey:kAlfrescoRepositoryName];
        if ([productName rangeOfString:kAlfrescoRepositoryCommunity].location != NSNotFound)
        {
            [repoDictionary setObject:kAlfrescoRepositoryCommunity forKey:kAlfrescoRepositoryEdition];
        }
        else
        {
            [repoDictionary setObject:kAlfrescoRepositoryEnterprise forKey:kAlfrescoRepositoryEdition];
        }
        [repoDictionary setObject:identifier forKey:kAlfrescoRepositoryIdentifier];
        [repoDictionary setObject:summary forKey:kAlfrescoRepositorySummary];
        [repoDictionary setObject:version forKey:kAlfrescoRepositoryVersion];
        [repoDictionary setObject:majorVersionNumber forKey:kAlfrescoRepositoryMajorVersion];
        [repoDictionary setObject:minorVersionNumber forKey:kAlfrescoRepositoryMinorVersion];
        [repoDictionary setObject:maintenanceVersion forKey:kAlfrescoRepositoryMaintenanceVersion];
        [repoDictionary setObject:buildNumber forKey:kAlfrescoRepositoryBuildNumber];
        if ([majorVersionNumber intValue] < 4)
        {
            [capabilities setValue:[NSNumber numberWithBool:NO] forKey:kAlfrescoCapabilityLike];
            [capabilities setValue:[NSNumber numberWithBool:NO] forKey:kAlfrescoCapabilityCommentsCount];
        }
        else
        {
            [capabilities setValue:[NSNumber numberWithBool:YES] forKey:kAlfrescoCapabilityLike];
            [capabilities setValue:[NSNumber numberWithBool:YES] forKey:kAlfrescoCapabilityCommentsCount];
        }
    }

    AlfrescoRepositoryCapabilities *repoCapabilities = [[AlfrescoRepositoryCapabilities alloc] initWithProperties:capabilities];
    [repoDictionary setValue:repoCapabilities forKey:kAlfrescoRepositoryCapabilities];
    AlfrescoRepositoryInfo *alfrescoRepositoryInfo = [[AlfrescoRepositoryInfo alloc] initWithProperties:repoDictionary];
    return alfrescoRepositoryInfo;
}

- (AlfrescoFolder *)folderFromCMISFolder:(CMISFolder *)cmisFolder
                              properties:(NSDictionary *)properties
{
    if (nil == properties)
    {
        properties = [NSMutableDictionary dictionary];
    }
    NSString *emptyString = @"(null)";
    NSString *identifier = cmisFolder.identifier;
    NSString *name = cmisFolder.name;
    NSString *objectType = cmisFolder.objectType;
    NSString *createdBy = cmisFolder.createdBy;
    NSString *lastModifiedBy = cmisFolder.lastModifiedBy;
    if (![identifier isEqualToString:emptyString])
    {
        [properties setValue:identifier forKey:kCMISPropertyObjectId];
    }
    if (![name isEqualToString:emptyString])
    {
        [properties setValue:name forKey:kCMISPropertyName];
    }
    if (![objectType isEqualToString:emptyString])
    {
        NSString *alfrescoObjectType = [objectType stringByReplacingOccurrencesOfString:kCMISPropertyObjectTypeIdValueFolder withString:kAlfrescoTypeFolder];
        [properties setValue:[AlfrescoCMISToAlfrescoObjectConverter propertyValueWithoutPrecursor:alfrescoObjectType] forKey:kCMISPropertyObjectTypeId];
    }
    if (![createdBy isEqualToString:emptyString])
    {
        [properties setValue:createdBy forKey:kCMISPropertyCreatedBy];
    }
    if (![lastModifiedBy isEqualToString:emptyString])
    {
        [properties setValue:lastModifiedBy forKey:kCMISPropertyModifiedBy];
    }
    [properties setValue:cmisFolder.creationDate forKey:kCMISPropertyCreationDate];
    [properties setValue:cmisFolder.lastModificationDate forKey:kCMISPropertyModificationDate];
    return [[AlfrescoFolder alloc] initWithProperties:properties];
    
}

- (AlfrescoDocument *)documentFromCMISDocument:(CMISDocument *)cmisDocument
                                    properties:(NSDictionary *)properties
{
    if (nil == properties)
    {
        properties = [NSMutableDictionary dictionary];
    }
    NSString *emptyString = @"(null)";
    NSString *identifier = cmisDocument.identifier;
    NSString *name = cmisDocument.name;
    NSString *objectType = cmisDocument.objectType;
    NSString *createdBy = cmisDocument.createdBy;
    NSString *lastModifiedBy = cmisDocument.lastModifiedBy;
    NSString *versionLabel = cmisDocument.versionLabel;
    NSString *contentStreamMediaType = cmisDocument.contentStreamMediaType;

    if (![identifier isEqualToString:emptyString])
    {
        [properties setValue:identifier forKey:kCMISPropertyObjectId];
    }
    if (![name isEqualToString:emptyString])
    {
        [properties setValue:name forKey:kCMISPropertyName];
    }
    if (![objectType isEqualToString:emptyString])
    {
        NSString *alfrescoObjectType = [objectType stringByReplacingOccurrencesOfString:kCMISPropertyObjectTypeIdValueDocument withString:kAlfrescoTypeContent];
        [properties setValue:[AlfrescoCMISToAlfrescoObjectConverter propertyValueWithoutPrecursor:alfrescoObjectType] forKey:kCMISPropertyObjectTypeId];
    }
    if (![createdBy isEqualToString:emptyString])
    {
        [properties setValue:createdBy forKey:kCMISPropertyCreatedBy];
    }
    if (![lastModifiedBy isEqualToString:emptyString])
    {
        [properties setValue:lastModifiedBy forKey:kCMISPropertyModifiedBy];
    }
    if (![versionLabel isEqualToString:emptyString])
    {
        [properties setValue:versionLabel forKey:kCMISPropertyVersionLabel];
    }
    if (![contentStreamMediaType isEqualToString:emptyString])
    {
        [properties setValue:contentStreamMediaType forKey:kCMISPropertyContentStreamMediaType];
    }
    
    [properties setValue:cmisDocument.creationDate forKey:kCMISPropertyCreationDate];
    [properties setValue:cmisDocument.lastModificationDate forKey:kCMISPropertyModificationDate];
    NSNumber *length = [NSNumber numberWithInt:cmisDocument.contentStreamLength];
    [properties setValue:length forKey:kCMISPropertyContentStreamLength];
    NSNumber *isLatest = [NSNumber numberWithBool:cmisDocument.isLatestVersion];
    [properties setValue:isLatest forKey:kCMISPropertyIsLatestVersion];
    
    return [[AlfrescoDocument alloc] initWithProperties:properties];
    
}

- (AlfrescoNode *)nodeFromCMISObject:(CMISObject *)cmisObject
{
    NSMutableDictionary *propertyDictionary = [NSMutableDictionary dictionary];

    CMISProperties *properties = cmisObject.properties;
    NSArray *propertyArray = [properties propertyList];
    
    NSMutableDictionary *alfPropertiesDict = [NSMutableDictionary dictionary];
    for (CMISPropertyData *propData in propertyArray)
    {
        NSMutableDictionary *propertyDictionary = [NSMutableDictionary dictionary];
        NSString *propertyStringType = propData.identifier;
        NSNumber *propTypeIndex = [NSNumber numberWithInt:[AlfrescoCMISToAlfrescoObjectConverter typeForCMISProperty:propertyStringType]];
        [propertyDictionary setValue:propTypeIndex forKey:kAlfrescoPropertyType];
        if(propData.values != nil && propData.values.count > 1)
        {
            [propertyDictionary setValue:[NSNumber numberWithBool:YES] forKey:kAlfrescoPropertyIsMultiValued];
            [propertyDictionary setValue:propData.values forKey:kAlfrescoPropertyValue];
        }
        else 
        {
            [propertyDictionary setValue:[NSNumber numberWithBool:NO] forKey:kAlfrescoPropertyIsMultiValued];
            [propertyDictionary setValue:propData.firstValue forKey:kAlfrescoPropertyValue];
        }
        AlfrescoProperty *alfProperty = [[AlfrescoProperty alloc] initWithProperties:propertyDictionary];
        [alfPropertiesDict setObject:alfProperty forKey:propData.identifier];
    }
    
    [propertyDictionary setValue:alfPropertiesDict forKey:kAlfrescoNodeProperties];
    
    AlfrescoNode *node = nil;
    if ([cmisObject isKindOfClass:[CMISFolder class]])
    {
        if ([cmisObject isKindOfClass:[AlfrescoCMISFolder class]])
        {
            AlfrescoCMISFolder *folder = (AlfrescoCMISFolder *)cmisObject;
            NSMutableArray *strippedAspectTypes = [NSMutableArray array];
            for (NSString * type in folder.aspectTypes)
            {
                NSString *correctedString = [AlfrescoCMISToAlfrescoObjectConverter propertyValueWithoutPrecursor:type];
                [strippedAspectTypes addObject:correctedString];
            }
            NSString *title = [folder.properties propertyValueForId:kAlfrescoPropertyTitle];
            if (![title isEqualToString:@"(null)"])
            {
                [propertyDictionary setValue:title forKey:kAlfrescoPropertyTitle];
            }
            NSString *description = [folder.properties propertyValueForId:kAlfrescoPropertyDescription];
            if (![description isEqualToString:@"(null)"])
            {
                [propertyDictionary setValue:description forKey:kAlfrescoPropertyDescription];
            }
            [propertyDictionary setValue:strippedAspectTypes forKey:kAlfrescoNodeAspects];
        }
        
        node = [self folderFromCMISFolder:(CMISFolder *)cmisObject properties:propertyDictionary];
    }
    else if ([cmisObject isKindOfClass:[CMISDocument class]])
    {
        if ([cmisObject isKindOfClass:[AlfrescoCMISDocument class]])
        {
            AlfrescoCMISDocument *document = (AlfrescoCMISDocument *)cmisObject;
            NSMutableArray *strippedAspectTypes = [NSMutableArray array];
            for (NSString * type in document.aspectTypes)
            {
                NSString *correctedString = [AlfrescoCMISToAlfrescoObjectConverter propertyValueWithoutPrecursor:type];
                [strippedAspectTypes addObject:correctedString];
            }
            NSString *title = [document.properties propertyValueForId:kAlfrescoPropertyTitle];
            if (![title isEqualToString:@"(null)"])
            {
                [propertyDictionary setValue:title forKey:kAlfrescoPropertyTitle];
            }
            NSString *description = [document.properties propertyValueForId:kAlfrescoPropertyDescription];
            if (![description isEqualToString:@"(null)"])
            {
                [propertyDictionary setValue:description forKey:kAlfrescoPropertyDescription];
            }
            
            [propertyDictionary setValue:strippedAspectTypes forKey:kAlfrescoNodeAspects];
        }
        
        node = [self documentFromCMISDocument:(CMISDocument *)cmisObject properties:propertyDictionary];
    }
    if (nil != node)
    {
        CMISAllowableActions *allowableActions = cmisObject.allowableActions;
        NSSet *actionSet = [allowableActions allowableActionTypesSet];
        
        AlfrescoPermissions *permissions = [[AlfrescoPermissions alloc] initWithPermissions:actionSet];
        objc_setAssociatedObject(node, &kAlfrescoPermissionsObjectKey, permissions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return node;
}

- (AlfrescoNode *)nodeFromCMISObjectData:(CMISObjectData *)cmisObjectData
{
    CMISSession *cmisSession = [self.session objectForParameter:kAlfrescoSessionKeyCmisSession];
//    CMISObjectConverter *cmisObjectConverter = [[CMISObjectConverter alloc] initWithSession:cmisSession];
    
    CMISObject *cmisObject = [cmisSession.objectConverter convertObject:cmisObjectData];
    return [self nodeFromCMISObject:cmisObject];
}

- (AlfrescoDocument *)documentFromCMISQueryResult:(CMISQueryResult *)cmisQueryResult
{
    CMISSession *cmisSession = [self.session objectForParameter:kAlfrescoSessionKeyCmisSession];
    CMISObjectData *data = [[CMISObjectData alloc] init];
    data.identifier = [[cmisQueryResult propertyForId:kCMISPropertyObjectId] firstValue];
    data.baseType = CMISBaseTypeDocument;
    data.properties = cmisQueryResult.properties;
    data.allowableActions = cmisQueryResult.allowableActions;
//    CMISObjectConverter *cmisObjectConverter = [[CMISObjectConverter alloc] initWithSession:cmisSession];
    
    CMISObject *cmisObject = [cmisSession.objectConverter convertObject:data];
    return (AlfrescoDocument *)[self nodeFromCMISObject:cmisObject];
}

#pragma mark internal methods

+ (AlfrescoPropertyType)typeForCMISProperty:(NSString *)propertyIdentifier
{
    if ([[propertyIdentifier lowercaseString] hasSuffix:kAlfrescoCMISPropertyTypeInt]) 
    {
        return AlfrescoPropertyTypeInteger;
    }
    else if ([[propertyIdentifier lowercaseString] hasSuffix:kAlfrescoCMISPropertyTypeBoolean]) 
    {
        return AlfrescoPropertyTypeBoolean;
    }
    else if ([[propertyIdentifier lowercaseString] hasSuffix:kAlfrescoCMISPropertyTypeDatetime]) 
    {
        return AlfrescoPropertyTypeDateTime;
    }
    else if ([[propertyIdentifier lowercaseString] hasSuffix:kAlfrescoCMISPropertyTypeDecimal]) 
    {
        return AlfrescoPropertyTypeDecimal;
    }
    else if ([[propertyIdentifier lowercaseString] hasSuffix:kAlfrescoCMISPropertyTypeId]) 
    {
        return AlfrescoPropertyTypeId;
    }
    return AlfrescoPropertyTypeString;
}

+ (NSString *)propertyValueWithoutPrecursor:(NSString *)value
{
    if ([value hasPrefix:@"P:"])
    {
        return [value stringByReplacingOccurrencesOfString:@"P:" withString:@""];
    }
    else if([value hasPrefix:@"D:"])
    {
        return [value stringByReplacingOccurrencesOfString:@"D:" withString:@""];
    }
    else if ([value hasPrefix:@"F:"])
    {
        return [value stringByReplacingOccurrencesOfString:@"F:" withString:@""];
    }
    return value;
}

@end

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

//
// AlfrescoCMISObjectConverter 
//
#import "AlfrescoCMISObjectConverter.h"
#import "CMISConstants.h"
#import "CMISErrors.h"
#import "CMISSession.h"
#import "CMISTypeDefinition.h"
#import "CMISPropertyDefinition.h"
#import "AlfrescoCMISDocument.h"
#import "AlfrescoCMISFolder.h"
#import "CMISDateUtil.h"
#import "AlfrescoErrors.h"
#import "AlfrescoConstants.h"

@interface AlfrescoCMISObjectConverter ()
- (void)retrieveAspectTypeDefinitionsFromObjectID:(NSString *)objectID completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;
- (CMISTypeDefinition *)mainTypeFromArray:(NSArray *)typeArray;
- (NSArray *)aspectTypesFromTypeArray:(NSArray *)typeArray;
@property (nonatomic, weak) CMISSession *session;

@end


@implementation AlfrescoCMISObjectConverter

- (id)initWithSession:(CMISSession *)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
    }
    return self;
}

- (CMISObject *)convertObject:(CMISObjectData *)objectData
{
    CMISObject *object = nil;

    if (objectData.baseType == CMISBaseTypeDocument)
    {
        object = [[AlfrescoCMISDocument alloc] initWithObjectData:objectData session:self.session];
    }
    else if (objectData.baseType == CMISBaseTypeFolder)
    {
        object = [[AlfrescoCMISFolder alloc] initWithObjectData:objectData session:self.session];
    }

    return object;
}




- (void)convertProperties:(NSDictionary *)properties forObjectTypeId:(NSString *)objectTypeId completionBlock:(void (^)(CMISProperties *, NSError *))completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:properties argumentName:@"properties"];
    NSObject *objectTypeIdValue = [properties objectForKey:kCMISPropertyObjectTypeId];
    NSString *objectTypeIdString = nil;
    
    if ([objectTypeIdValue isKindOfClass:[NSString class]])
    {
        objectTypeIdString = (NSString *)objectTypeIdValue;
    }
    else if ([objectTypeIdValue isKindOfClass:[CMISPropertyData class]])
    {
        objectTypeIdString = [(CMISPropertyData *)objectTypeIdValue firstValue];
    }
    else if (objectTypeId)
    {
        objectTypeIdString = objectTypeId;
    }
    
    if (nil == objectTypeIdString)
    {
        completionBlock( nil, [CMISErrors createCMISErrorWithCode:kCMISErrorCodeInvalidArgument detailedDescription:@"Type property must be set"]);
        return;
    }
    
    [self retrieveAspectTypeDefinitionsFromObjectID:objectTypeIdString completionBlock:^(NSArray *returnedTypes, NSError *error){
        if (0 == returnedTypes.count)
        {
            completionBlock(nil, [CMISErrors cmisError:error cmisErrorCode:kCMISErrorCodeRuntime]);
            return;
        }
        else
        {
            CMISTypeDefinition *mainTypeDefinition = [self mainTypeFromArray:returnedTypes];
            NSArray *aspectTypes = [self aspectTypesFromTypeArray:returnedTypes];
            // Split type properties from aspect properties
            NSMutableDictionary *typeProperties = [NSMutableDictionary dictionary];
            NSMutableDictionary *aspectProperties = [NSMutableDictionary dictionary];
            NSMutableDictionary *aspectPropertyDefinitions = [NSMutableDictionary dictionary];
            
            // Loop over all provided properties and put them in the right dictionary
            for (NSString *propertyId in properties)
            {
                id propertyValue = [properties objectForKey:propertyId];
                
                if ([propertyId isEqualToString:kCMISPropertyObjectTypeId])
                {
                    [typeProperties setValue:propertyValue forKey:kCMISPropertyObjectTypeId];
                }
                else if ([mainTypeDefinition propertyDefinitionForId:propertyId])
                {
                    [typeProperties setObject:propertyValue forKey:propertyId];
                }
                else
                {
                    [aspectProperties setObject:propertyValue forKey:propertyId];
                    
                    // Find matching property definition
                    BOOL matchingPropertyDefinitionFound = NO;
                    uint index = 0;
                    while (!matchingPropertyDefinitionFound && index < aspectTypes.count)
                    {
                        CMISTypeDefinition *aspectType = [aspectTypes objectAtIndex:index];
                        if (aspectType.propertyDefinitions != nil)
                        {
                            CMISPropertyDefinition *aspectPropertyDefinition = [aspectType propertyDefinitionForId:propertyId];
                            if (aspectPropertyDefinition != nil)
                            {
                                [aspectPropertyDefinitions setObject:aspectPropertyDefinition forKey:propertyId];
                                matchingPropertyDefinitionFound = YES;
                            }
                        }
                        index++;
                    }
                    // If no match was found, throw an exception
                    if (!matchingPropertyDefinitionFound)
                    {
                        NSError *typeError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeInvalidArgument
                                                         detailedDescription:[NSString stringWithFormat:@"Property '%@' is neither an object type property nor an aspect property", propertyId]];
                        completionBlock(nil, typeError);
                        return;
                    }
                }
            }
            // Create an array to hold all converted stuff
            NSMutableArray *alfrescoExtensions = [NSMutableArray array];
            
            // Convert the aspect types stuff to CMIS extensions
            for (CMISTypeDefinition *aspectType in aspectTypes)
            {
                CMISExtensionElement *extensionElement = [[CMISExtensionElement alloc] initLeafWithName:@"aspectsToAdd"
                                                                                           namespaceUri:@"http://www.alfresco.org" attributes:nil value:aspectType.id];
                [alfrescoExtensions addObject:extensionElement];
            }

            // Convert the aspect properties
            if (aspectProperties.count > 0)
            {
                NSMutableArray *propertyExtensions = [NSMutableArray array];
                
                for (NSString *propertyId in aspectProperties)
                {
                    CMISPropertyDefinition *aspectPropertyDefinition = [aspectPropertyDefinitions objectForKey:propertyId];
                    if (aspectPropertyDefinition == nil)
                    {
                        NSError *typeError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeInvalidArgument
                                                         detailedDescription:[NSString stringWithFormat:@"Unknown aspect property: %@", propertyId]];
                        completionBlock(nil, typeError);
                        return;
                    }
                    
                    
                    NSString *name = nil;
                    switch (aspectPropertyDefinition.propertyType)
                    {
                        case CMISPropertyTypeBoolean:
                            name = @"propertyBoolean";
                            break;
                        case CMISPropertyTypeDateTime:
                            name = @"propertyDateTime";
                            break;
                        case CMISPropertyTypeInteger:
                            name = @"propertyInteger";
                            break;
                        case CMISPropertyTypeDecimal:
                            name = @"propertyDecimal";
                            break;
                        case CMISPropertyTypeId:
                            name = @"propertyId";
                            break;
                        case CMISPropertyTypeHtml:
                            name = @"propertyHtml";
                            break;
                        case CMISPropertyTypeUri:
                            name = @"propertyUri";
                            break;
                        default:
                            name = @"propertyString";
                            break;
                    }
                    
                    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
                    [attributes setObject:aspectPropertyDefinition.id forKey:@"propertyDefinitionId"];
                    
                    NSMutableArray *propertyValues = [NSMutableArray array];
                    id value = [aspectProperties objectForKey:propertyId];
                    if (value != nil)
                    {
                        NSString *stringValue = nil;
                        if ([value isKindOfClass:[NSString class]])
                        {
                            stringValue = value;
                        }
                        else if ([value isKindOfClass:[CMISPropertyData class]])
                        {
                            stringValue = ((CMISPropertyData *) value).firstValue;
                        }
                        else
                        {
                            switch (aspectPropertyDefinition.propertyType)
                            {
                                case CMISPropertyTypeBoolean:
                                    stringValue = ((NSNumber *)value).boolValue ? @"true" : @"false";
                                    break;
                                case CMISPropertyTypeDateTime:
                                    stringValue = [self stringFromDate:((NSDate *)value)];
                                    break;
                                case CMISPropertyTypeInteger:
                                    stringValue = [NSString stringWithFormat:@"%d", ((NSNumber *)value).intValue];
                                    break;
                                case CMISPropertyTypeDecimal:
                                    stringValue = [NSString stringWithFormat:@"%f", ((NSNumber *)value).floatValue];
                                    break;
                                default:
                                    stringValue = value;
                                    break;
                            }
                        }
                        
                        CMISExtensionElement *valueExtensionElement = [[CMISExtensionElement alloc] initLeafWithName:@"value"
                                                                                                        namespaceUri:@"http://docs.oasis-open.org/ns/cmis/core/200908/" attributes:nil value:stringValue];
                        [propertyValues addObject:valueExtensionElement];
                    }
                    
                    
                    CMISExtensionElement *aspectPropertyExtensionElement = [[CMISExtensionElement alloc] initNodeWithName:name
                                                                                                             namespaceUri:@"http://docs.oasis-open.org/ns/cmis/core/200908/" attributes:attributes children:propertyValues];
                    [propertyExtensions addObject:aspectPropertyExtensionElement];
                }
                
                [alfrescoExtensions addObject: [[CMISExtensionElement alloc] initNodeWithName:@"properties"
                                                                                 namespaceUri:@"http://www.alfresco.org" attributes:nil children:propertyExtensions]];
            }
            // Cmis doesn't understand aspects, so we must replace the objectTypeId if needed
            if ([typeProperties objectForKey:kCMISPropertyObjectTypeId] != nil)
            {
                [typeProperties setValue:mainTypeDefinition.id forKey:kCMISPropertyObjectTypeId];
            }

            [super convertProperties:typeProperties forObjectTypeId:mainTypeDefinition.id completionBlock:^(CMISProperties *result, NSError *error){
                if (nil == result)
                {
                    completionBlock(nil, error);
                }
                else
                {
                    if (alfrescoExtensions.count > 0)
                    {
                        result.extensions = [NSArray arrayWithObject:[[CMISExtensionElement alloc] initNodeWithName:@"setAspects"
                                                                                                       namespaceUri:@"http://www.alfresco.org" attributes:nil children:alfrescoExtensions]];
                    }
                    completionBlock(result, nil);
                }
            }];
        }
    }];
}

- (CMISTypeDefinition *)mainTypeFromArray:(NSArray *)typeArray
{
    CMISTypeDefinition *typeDefinition = nil;
    for (CMISTypeDefinition * type in typeArray)
    {
        if ([type.id hasPrefix:@"cmis:"] || [type.id hasPrefix:@"D:"] || [type.id hasPrefix:@"F:"])
        {
            typeDefinition = type;
            break;
        }
    }
    return typeDefinition;
}

- (NSArray *)aspectTypesFromTypeArray:(NSArray *)typeArray
{
    NSMutableArray *aspects = [NSMutableArray array];
    for (CMISTypeDefinition * type in typeArray)
    {
        if (![type.id hasPrefix:@"cmis:"] && ![type.id hasPrefix:@"D:"] && ![type.id hasPrefix:@"F:"])
        {
            [aspects addObject:type];
        }
    }    
    return aspects;
}



- (void)retrieveAspectTypeDefinitionsFromObjectID:(NSString *)objectID completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    NSArray *components = [objectID componentsSeparatedByString:@","];
    __block NSMutableArray *aspects = [NSMutableArray array];
    
    if (1 == components.count)
    {
        NSString *trimmedString = [objectID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.session.binding.repositoryService retrieveTypeDefinition:trimmedString completionBlock:^(CMISTypeDefinition *typeDefinition, NSError *error){
            if (nil == typeDefinition)
            {
                completionBlock(nil, error);
            }
            else
            {
                [aspects addObject:typeDefinition];
                completionBlock(aspects, nil);
            }
        }];
    }
    else
    {
        __block int index = 1;
        for (NSString *type  in components)
        {
            NSString *trimmedString = [type stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (![trimmedString isEqualToString:@""])
            {
                [self.session.binding.repositoryService retrieveTypeDefinition:trimmedString completionBlock:^(CMISTypeDefinition *typeDefinition, NSError *error){
                    if (nil != typeDefinition)
                    {
                        [aspects addObject:typeDefinition];
                    }
                    if (index == components.count)
                    {
                        completionBlock(aspects , nil);
                    }
                    index = index + 1;
                }];
            }
        }
    }
    
    
}



#pragma mark Helper methods

- (NSString *)stringFromDate:(NSDate *)date
{
    return [CMISDateUtil stringFromDate:date];
}


@end
/*
 ******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

#import "AlfrescoFormConfigHelper.h"
#import "AlfrescoConstants.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoPropertyConstants.h"
#import "AlfrescoLog.h"
#import "AlfrescoFieldConfig.h"
#import "AlfrescoFieldGroupConfig.h"
#import "AlfrescoNode.h"

@interface AlfrescoFormConfigHelper ()
@property (nonatomic, strong) NSDictionary *fields;
@property (nonatomic, strong) NSMutableDictionary *fieldGroupConfigData;
@property (nonatomic, strong) NSMutableDictionary *formConfigData;
@end

@implementation AlfrescoFormConfigHelper

#pragma mark - Public methods

-(void)parse
{
    // TODO: parse validation rules
    
    [self parseFields:self.json[kAlfrescoJSONFields]];
    [self parseFieldGroups:self.json[kAlfrescoJSONFieldGroups]];
    [self parseForms:self.json[kAlfrescoJSONForms]];
}

- (AlfrescoFormConfig *)formConfigForIdentifier:(NSString *)identifier scope:(AlfrescoConfigScope *)scope;
{
    AlfrescoFormConfig *formConfig = nil;
    
    // find the best matching form data object for the given identifier.
    AlfrescoGroupConfigData *requestedFormData = [self formDataForIdentifier:identifier scope:scope];
    
    if (requestedFormData != nil)
    {
        // resolve the data objects into real config objects
        formConfig = [self resolveFormConfigFromData:requestedFormData scope:scope];
    }
    
    AlfrescoLogDebug(@"Returning form config for identifier '%@': %@", identifier, formConfig);
    
    return formConfig;
}

#pragma mark - Parsing methods

- (void)parseFields:(NSDictionary *)fieldsJSON
{
    NSMutableDictionary *fieldsDictionary = [NSMutableDictionary dictionary];
    for (NSString *fieldId in [fieldsJSON allKeys])
    {
        NSDictionary *fieldJSON = fieldsJSON[fieldId];
        
        NSMutableDictionary *fieldProperties = [self fieldDataFromJSON:fieldJSON fieldId:fieldId];
        if (fieldProperties != nil)
        {
            AlfrescoFieldConfig *fieldConfig = [[AlfrescoFieldConfig alloc] initWithDictionary:fieldProperties];
            fieldsDictionary[fieldId] = fieldConfig;
            
            AlfrescoLogDebug(@"Stored config for field with id: %@", fieldId);
        }
    }
    
    self.fields = fieldsDictionary;
}

- (void)parseFieldGroups:(NSDictionary *)fieldGroupsJSON
{
    self.fieldGroupConfigData = [NSMutableDictionary dictionary];
    
    for (NSString *groupId in [fieldGroupsJSON allKeys])
    {
        NSDictionary *fieldGroupJSON = fieldGroupsJSON[groupId];
        
        // recursively parse the field groups
        AlfrescoGroupConfigData *fieldGroupConfigData = [self fieldGroupDataFromJSON:fieldGroupJSON groupId:groupId];
        self.fieldGroupConfigData[groupId] = fieldGroupConfigData;
        
        AlfrescoLogDebug(@"Stored config data for field group with id: %@", groupId);
    }
}

- (void)parseForms:(NSArray *)formsJSON
{
    self.formConfigData = [NSMutableDictionary dictionary];
    
    for (NSDictionary *formJSON in formsJSON)
    {
        AlfrescoGroupConfigData *formConfigData = [self formDataFromJSON:formJSON];
        if (formConfigData != nil)
        {
            NSString *identifier = formConfigData.properties[kAlfrescoBaseConfigPropertyIdentifier];
            
            NSMutableArray *storedArray = self.formConfigData[identifier];
            if (storedArray != nil)
            {
                [storedArray addObject:formConfigData];
            }
            else
            {
                self.formConfigData[identifier] = [NSMutableArray arrayWithObject:formConfigData];
            }
            
            AlfrescoLogDebug(@"Stored config data for form with id: %@", identifier);
        }
    }
}

- (NSMutableDictionary *)fieldDataFromJSON:(NSDictionary *)fieldJSON fieldId:(NSString *)fieldId
{
    NSString *modelId = fieldJSON[kAlfrescoJSONModelId];
    
    if (modelId == nil)
    {
        AlfrescoLogWarning(@"Ignoring field config with id '%@' as a model-id has not been provided", fieldId);
        return nil;
    }
    
    // extract common properties
    NSMutableDictionary *fieldProperties = [self configPropertiesFromJSON:fieldJSON];
    
    // set the model id of the field
    fieldProperties[kAlfrescoFieldConfigPropertyModelIdentifier] = modelId;
    
    // set the id of the field, if provided
    if (fieldId != nil)
    {
        fieldProperties[kAlfrescoBaseConfigPropertyIdentifier] = fieldId;
    }
    
    // TODO: process validation
    
    return fieldProperties;
}

- (AlfrescoGroupConfigData *)fieldGroupDataFromJSON:(NSDictionary *)fieldGroupJSON groupId:(NSString *)groupId
{
    // extract common properties
    NSMutableDictionary *fieldGroupProperties = [self configPropertiesFromJSON:fieldGroupJSON];
    
    // set the id of the field group, if provided
    if (groupId != nil)
    {
        fieldGroupProperties[kAlfrescoBaseConfigPropertyIdentifier] = groupId;
    }
    
    // create config data object
    AlfrescoGroupConfigData *fieldGroupConfigData = [AlfrescoGroupConfigData new];
    fieldGroupConfigData.properties = fieldGroupProperties;
    fieldGroupConfigData.evaluator = fieldGroupJSON[kAlfrescoJSONEvaluator];
    
    // process potential items, recursively
    fieldGroupConfigData.potentialItems = [self itemsDataFromJSON:fieldGroupJSON[kAlfrescoJSONItems]];
    
    return fieldGroupConfigData;
}

- (AlfrescoGroupConfigData *)formDataFromJSON:(NSDictionary *)formJSON
{
    NSString *identifier = formJSON[kAlfrescoJSONIdentifier];
    
    if (identifier == nil)
    {
        AlfrescoLogWarning(@"Ignoring form config without identifier: %@", formJSON);
        return nil;
    }
    
    // extract common properties
    NSMutableDictionary *formProperties = [self configPropertiesFromJSON:formJSON];
    
    // process layout
    NSString *layout = formJSON[kAlfrescoJSONLayout];
    if (layout != nil)
    {
        formProperties[kAlfrescoFormConfigPropertyLayout] = layout;
    }
    
    // create config data object
    AlfrescoGroupConfigData *formConfigData = [AlfrescoGroupConfigData new];
    formConfigData.properties = formProperties;
    formConfigData.evaluator = formJSON[kAlfrescoJSONEvaluator];
    
    // process potential items, recursively
    formConfigData.potentialItems = [self itemsDataFromJSON:formJSON[kAlfrescoJSONItems]];
    
    return formConfigData;
}

- (NSArray *)itemsDataFromJSON:(NSArray *)itemsJSON
{
    NSMutableArray *potentialItemsArray = [NSMutableArray array];
    for (NSDictionary *groupItemJSON in itemsJSON)
    {
        NSString *itemType = groupItemJSON[kAlfrescoJSONItemType];
        if ([itemType isEqualToString:kAlfrescoJSONFieldId])
        {
            NSString *reference = groupItemJSON[kAlfrescoJSONFieldId];
            if (reference != nil)
            {
                // create and store a reference config data object
                AlfrescoConfigData *configData = [AlfrescoConfigData new];
                configData.reference = reference;
                configData.evaluator = groupItemJSON[kAlfrescoJSONEvaluator];
                [potentialItemsArray addObject:configData];
            }
        }
        else if ([itemType isEqualToString:kAlfrescoJSONField])
        {
            NSMutableDictionary *fieldProperties = [self fieldDataFromJSON:groupItemJSON[kAlfrescoJSONField] fieldId:nil];
            if (fieldProperties != nil)
            {
                // create and store field config data object
                AlfrescoConfigData *configData = [AlfrescoConfigData new];
                configData.properties = fieldProperties;
                configData.evaluator = groupItemJSON[kAlfrescoJSONEvaluator];
                [potentialItemsArray addObject:configData];
            }
        }
        else if ([itemType isEqualToString:kAlfrescoJSONFieldGroupId])
        {
            NSString *reference = groupItemJSON[kAlfrescoJSONFieldGroupId];
            if (reference != nil)
            {
                // create and store a reference group config data object
                AlfrescoGroupConfigData *configData = [AlfrescoGroupConfigData new];
                configData.reference = reference;
                configData.evaluator = groupItemJSON[kAlfrescoJSONEvaluator];
                [potentialItemsArray addObject:configData];
            }
        }
        else if ([itemType isEqualToString:kAlfrescoJSONFieldGroup])
        {
            // recursively parse the inline field group
            NSDictionary *childFieldGroupJSON = groupItemJSON[kAlfrescoJSONFieldGroup];
            if (childFieldGroupJSON != nil)
            {
                [potentialItemsArray addObject:[self fieldGroupDataFromJSON:childFieldGroupJSON groupId:nil]];
            }
        }
    }
    
    return potentialItemsArray;
}

#pragma mark - Resolving methods

- (AlfrescoGroupConfigData *)formDataForIdentifier:(NSString *)identifier scope:(AlfrescoConfigScope *)scope
{
    AlfrescoGroupConfigData *requestedFormData = nil;
    
    NSArray *potentialFormWithId = self.formConfigData[identifier];
    
    for (AlfrescoGroupConfigData *configData in potentialFormWithId)
    {
        if ([self processEvaluator:configData.evaluator withScope:scope])
        {
            requestedFormData = configData;
            break;
        }
    }
    
    return requestedFormData;
}

- (AlfrescoFormConfig *)resolveFormConfigFromData:(AlfrescoGroupConfigData *)groupConfigData scope:(AlfrescoConfigScope *)scope
{
    // recursively resolve all potential items
    NSArray *items = [self resolveFormItemsFromData:groupConfigData scope:scope];
    
    // create and return the final form config object
    NSMutableDictionary *formProperties = [NSMutableDictionary dictionaryWithDictionary:groupConfigData.properties];
    formProperties[kAlfrescoGroupConfigPropertyItems] = items;
    
    return [[AlfrescoFormConfig alloc] initWithDictionary:formProperties];
}

- (AlfrescoFieldGroupConfig *)resolveFieldGroupConfigFromData:(AlfrescoGroupConfigData *)groupConfigData scope:(AlfrescoConfigScope *)scope
{
    // recursively resolve all potential items
    NSArray *items = [self resolveFormItemsFromData:groupConfigData scope:scope];
    
    // create and return the final field group config object
    NSMutableDictionary *fieldGroupProperties = [NSMutableDictionary dictionaryWithDictionary:groupConfigData.properties];
    fieldGroupProperties[kAlfrescoGroupConfigPropertyItems] = items;
    
    return [[AlfrescoFieldGroupConfig alloc] initWithDictionary:fieldGroupProperties];
}

- (NSArray *)resolveFormItemsFromData:(AlfrescoGroupConfigData *)groupConfigData scope:(AlfrescoConfigScope *)scope
{
    NSMutableArray *items = [NSMutableArray array];
    
    for (AlfrescoConfigData *configData in groupConfigData.potentialItems)
    {
        // only process items that match the evaluator
        if ([self processEvaluator:configData.evaluator withScope:scope])
        {
            if ([configData isKindOfClass:[AlfrescoGroupConfigData class]])
            {
                if (configData.reference != nil)
                {
                    // it's a reference to a field group, see if it's one of the 'special' ones
                    if ([configData.reference isEqualToString:kAlfrescoConfigFormTypeProperties])
                    {
                        // find the type of the node and lookup the field group
                        AlfrescoNode *node = [scope valueForKey:kAlfrescoConfigScopeContextNode];
                        if (node != nil)
                        {
                            NSString *typeLookup = [NSString stringWithFormat:@"%@%@", kAlfrescoConfigFormTypePrefix, node.type];
                            
                            AlfrescoGroupConfigData *fieldGroupData = self.fieldGroupConfigData[typeLookup];
                            if (fieldGroupData != nil)
                            {
                                [items addObject:[self resolveFieldGroupConfigFromData:fieldGroupData scope:scope]];
                            }
                            else
                            {
                                // if the specific type was not found try config for the base type
                                NSString *typeLookup = nil;
                                if (node.isDocument)
                                {
                                    typeLookup = [NSString stringWithFormat:@"%@%@", kAlfrescoConfigFormTypePrefix, kAlfrescoModelTypeContent];
                                }
                                else
                                {
                                    typeLookup = [NSString stringWithFormat:@"%@%@", kAlfrescoConfigFormTypePrefix, kAlfrescoModelTypeFolder];
                                }
                                
                                // find the config data for the base type
                                fieldGroupData = self.fieldGroupConfigData[typeLookup];
                                
                                if (fieldGroupData != nil)
                                {
                                    [items addObject:[self resolveFieldGroupConfigFromData:fieldGroupData scope:scope]];
                                }
                            }
                        }
                        else
                        {
                            AlfrescoLogWarning(@"Ignoring %@ directive as a node was not found in the config scope object",
                                               kAlfrescoConfigFormTypeProperties);
                        }
                    }
                    else if ([configData.reference isEqualToString:kAlfrescoConfigFormAspectProperties])
                    {
                        // find the aspects the node has and add the config for each one
                        AlfrescoNode *node = [scope valueForKey:kAlfrescoConfigScopeContextNode];
                        if (node != nil)
                        {
                            for (NSString *aspectName in node.aspects)
                            {
                                NSString *aspectLookup = [NSString stringWithFormat:@"%@%@", kAlfrescoConfigFormAspectPrefix, aspectName];
                                AlfrescoGroupConfigData *fieldGroupData = self.fieldGroupConfigData[aspectLookup];
                                if (fieldGroupData != nil)
                                {
                                    [items addObject:[self resolveFieldGroupConfigFromData:fieldGroupData scope:scope]];
                                }
                            }
                        }
                        else
                        {
                            AlfrescoLogWarning(@"Ignoring %@ directive as a node was not found in the config scope object",
                                               kAlfrescoConfigFormAspectProperties);
                        }
                    }
                    else
                    {
                        AlfrescoGroupConfigData *fieldGroupData = self.fieldGroupConfigData[configData.reference];
                        if (fieldGroupData != nil)
                        {
                            AlfrescoFieldGroupConfig *fieldGroupConfig = [self resolveFieldGroupConfigFromData:fieldGroupData scope:scope];
                            [items addObject:fieldGroupConfig];
                        }
                        else
                        {
                            AlfrescoLogWarning(@"Ignoring reference to an invalid field group id reference: %@", configData.reference);
                        }
                    }
                }
                else
                {
                    // it's an inline field group, recursively resolve
                    AlfrescoFieldGroupConfig *fieldGroupConfig = [self resolveFieldGroupConfigFromData:(AlfrescoGroupConfigData*)configData scope:scope];
                    [items addObject:fieldGroupConfig];
                }
            }
            else
            {
                if (configData.reference != nil)
                {
                    // it's a reference to a field, retrieve field config
                    AlfrescoFieldConfig *fieldConfig = self.fields[configData.reference];
                    if (fieldConfig != nil)
                    {
                        [items addObject:fieldConfig];
                    }
                    else
                    {
                        AlfrescoLogWarning(@"Ignoring reference to an invalid field id reference: %@", configData.reference);
                    }
                }
                else
                {
                    // it's an inline field, create field config
                    AlfrescoFieldConfig *fieldConfig = [[AlfrescoFieldConfig alloc] initWithDictionary:configData.properties];
                    [items addObject:fieldConfig];
                }
            }
        }
    }
    
    return items;
}

@end

/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

#import "FormUtils.h"
#import "AlfrescoFormField.h"
#import "AlfrescoFormFieldGroup.h"
#import "AlfrescoFormMandatoryConstraint.h"
#import "AlfrescoConfigService.h"
#import "AlfrescoModelDefinitionService.h"
#import "AlfrescoConfigScope.h"
#import "AlfrescoFieldGroupConfig.h"
#import "AlfrescoFieldConfig.h"

@implementation FormUtils

+ (AlfrescoRequest *)formForNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session completionBlock:(FormCompletionBlock)completionBlock
{
    // create config service
    // TODO: create a configuration manager so we can take advantage of caching in the config service.
    [session setObject:@"com.alfresco.mobile.ios" forParameter:kAlfrescoConfigServiceParameterApplicationId];
    AlfrescoConfigService *configService = [[AlfrescoConfigService alloc] initWithSession:session];
    
    // create config scope object with
    AlfrescoConfigScope *configScope = configService.defaultConfigScope;
    [configScope setObject:node forKey:kAlfrescoConfigScopeContextNode];
    
    // retrieve the "edit-properties" form
    AlfrescoRequest *request = nil;
    request = [configService retrieveFormConfigWithIdentifier:@"edit-properties" scope:configScope
                                              completionBlock:^(AlfrescoFormConfig *config, NSError *configError) {
        if (config != nil)
        {
            // retrieve the type definition for the node
            AlfrescoModelDefinitionService *definitionService = [[AlfrescoModelDefinitionService alloc] initWithSession:session];
            [definitionService retrieveDefinitionForDocumentType:node.type
                                                 completionBlock:^(AlfrescoDocumentTypeDefinition *typeDefinition, NSError *definitionError) {
                if (typeDefinition != nil)
                {
                    NSMutableArray *groups = [NSMutableArray array];
                    NSArray *fieldGroupsConfig = config.items;
                    for (AlfrescoFieldGroupConfig *fieldGroupConfig in fieldGroupsConfig)
                    {
                        // create the field objects
                        NSMutableArray *fields = [NSMutableArray array];
                        for (AlfrescoFieldConfig *fieldConfig in fieldGroupConfig.items)
                        {
                            NSString *modelId = fieldConfig.modelIdentifier;
                            
                            // map CMIS property names
                            if ([modelId isEqualToString:@"cm:name"])
                            {
                                modelId = @"cmis:name";
                            }
                            else if ([modelId isEqualToString:@"cm:created"])
                            {
                                modelId = @"cmis:creationDate";
                            }
                            else if ([modelId isEqualToString:@"cm:creator"])
                            {
                                modelId = @"cmis:createdBy";
                            }
                            else if ([modelId isEqualToString:@"cm:modified"])
                            {
                                modelId = @"cmis:lastModificationDate";
                            }
                            else if ([modelId isEqualToString:@"cm:modifier"])
                            {
                                modelId = @"cmis:modifiedBy";
                            }
                            
                            // control parameters
                            NSMutableDictionary *controlParameters = [NSMutableDictionary dictionary];
                            
                            // retrieve the property definition for the field
                            AlfrescoFormFieldType fieldType = AlfrescoFormFieldTypeString   ;
                            AlfrescoPropertyDefinition *propertyDefinition = [typeDefinition propertyDefinitionForPropertyWithName:modelId];
                            if (propertyDefinition != nil)
                            {
                                if (propertyDefinition.type == AlfrescoPropertyTypeString)
                                {
                                    fieldType = AlfrescoFormFieldTypeString;
                                }
                                else if (propertyDefinition.type == AlfrescoPropertyTypeInteger)
                                {
                                    fieldType = AlfrescoFormFieldTypeNumber;
                                }
                                else if (propertyDefinition.type == AlfrescoPropertyTypeDecimal)
                                {
                                    fieldType = AlfrescoFormFieldTypeNumber;
                                    controlParameters[kAlfrescoFormControlParameterAllowDecimals] = @(YES);
                                }
                                else if (propertyDefinition.type == AlfrescoPropertyTypeDate)
                                {
                                    fieldType = AlfrescoFormFieldTypeDate;
                                }
                                else if (propertyDefinition.type == AlfrescoPropertyTypeDateTime)
                                {
                                    fieldType = AlfrescoFormFieldTypeDateTime;
                                }
                                else if (propertyDefinition.type == AlfrescoPropertyTypeBoolean)
                                {
                                    fieldType = AlfrescoFormFieldTypeBoolean;
                                }
                                else if (propertyDefinition.type == AlfrescoPropertyTypeId)
                                {
                                    // TOOD: use a node picker control
                                }
                            }
                            else
                            {
                                AlfrescoLogWarning(@"Property definition for configured field '%@' could not be found", modelId);
                            }
                            
                            // get the value of the property from the node
                            id value = nil;
                            AlfrescoProperty *property = node.properties[modelId];
                            if (property != nil)
                            {
                                value = property.value;
                            }
                            
                            AlfrescoFormField *field = [[AlfrescoFormField alloc] initWithIdentifier:modelId
                                                                                                type:fieldType
                                                                                               value:value
                                                                                               label:fieldConfig.label];
                            
                            // add any control parameters that have been defined
                            field.controlParameters = controlParameters;
                            
                            // add mandatory constraint to field
                            if (propertyDefinition != nil && propertyDefinition.isRequired)
                            {
                                [field addConstraint:[AlfrescoFormMandatoryConstraint new]];
                            }
                            
                            [fields addObject:field];
                        }
                        
                        // create a field group
                        AlfrescoFormFieldGroup *group = [[AlfrescoFormFieldGroup alloc] initWithIdentifier:fieldGroupConfig.identifier fields:fields label:fieldGroupConfig.label];
                        [groups addObject:group];
                    }
                    
                    // create the overall form
                    AlfrescoForm *form = [[AlfrescoForm alloc] initWithGroups:groups title:config.label];
                    completionBlock(form, nil);
                }
                else
                {
                    completionBlock(nil, definitionError);
                }
            }];
        }
        else
        {
            completionBlock(nil, configError);
        }
    }];
    
    return request;
}

@end

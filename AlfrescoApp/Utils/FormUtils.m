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

@implementation FormUtils

+ (AlfrescoRequest *)formForNode:(AlfrescoNode *)node completionBlock:(FormCompletionBlock)completionBlock
{
    // TODO: retrieve the form config for the current node
    
    // TODO: retrieve the model definition for the type/aspects of the node
    
    // TODO: build a form to represent a combination of the node, config and model
    
    AlfrescoFormField *nameField = [[AlfrescoFormField alloc] initWithIdentifier:@"cm:name" type:AlfrescoFormFieldTypeString value:node.name label:@"Name"];
    AlfrescoFormField *titleField = [[AlfrescoFormField alloc] initWithIdentifier:@"cm:title" type:AlfrescoFormFieldTypeString value:node.title label:@"Title"];
    AlfrescoFormField *descriptionField = [[AlfrescoFormField alloc] initWithIdentifier:@"cm:description" type:AlfrescoFormFieldTypeString value:node.summary label:@"Description"];
    AlfrescoFormFieldGroup *generalGroup = [[AlfrescoFormFieldGroup alloc] initWithIdentifier:@"general" fields:@[nameField,titleField,descriptionField]];
    AlfrescoForm *form = [[AlfrescoForm alloc] initWithGroups:@[generalGroup] title:nil];
    
    // call the completion block
    completionBlock(form, nil);
    return nil;
}

@end

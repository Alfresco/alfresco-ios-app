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

#import "AlfrescoViewConfigHelper.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoPropertyConstants.h"
#import "AlfrescoLog.h"

@interface AlfrescoViewConfigHelper ()
@property (nonatomic, strong) NSDictionary *views;
@property (nonatomic, strong) NSMutableDictionary *viewGroupConfigData;
@end

@implementation AlfrescoViewConfigHelper

#pragma mark - Public methods

-(void)parse
{
    [self parseViews:self.json[kAlfrescoJSONViews]];
    [self parseViewGroups:self.json[kAlfrescoJSONViewGroups]];
}

- (AlfrescoViewConfig *)viewConfigForIdentifier:(NSString *)identifier
{
    AlfrescoViewConfig *viewConfig = self.views[identifier];
    
    AlfrescoLogDebug(@"Returning view config for identifier '%@': %@", identifier, viewConfig);
    
    return viewConfig;
}

- (AlfrescoViewGroupConfig *)viewGroupConfigForIdentifier:(NSString *)identifier scope:(AlfrescoConfigScope *)scope
{
    AlfrescoViewGroupConfig *viewGroupConfig = nil;
    
    // find the best matching view group data for the given identifier.
    AlfrescoGroupConfigData *requestedViewGroupData = [self viewGroupDataForIdentifier:identifier scope:scope];
     
    if (requestedViewGroupData != nil)
    {
        // resolve the data objects into real config objects
        viewGroupConfig = [self resolveViewGroupConfigFromData:requestedViewGroupData scope:scope];
    }
    
    AlfrescoLogDebug(@"Returning view group config for identifier '%@': %@", identifier, viewGroupConfig);
    
    return viewGroupConfig;
}

#pragma mark - Parsing methods

- (void)parseViews:(NSDictionary *)viewsJSON
{
    NSMutableDictionary *viewsDictionary = [NSMutableDictionary dictionary];
    for (NSString *viewId in [viewsJSON allKeys])
    {
        NSDictionary *viewJSON = viewsJSON[viewId];
        
        NSMutableDictionary *viewProperties = [self viewDataFromJSON:viewJSON viewId:viewId];
        if (viewProperties != nil)
        {
            AlfrescoViewConfig *viewConfig = [[AlfrescoViewConfig alloc] initWithDictionary:viewProperties];
            viewsDictionary[viewId] = viewConfig;
            
            AlfrescoLogDebug(@"Stored config for view with id: %@", viewId);
        }
    }
    
    self.views = viewsDictionary;
}

- (void)parseViewGroups:(NSArray *)viewGroupsJSON
{
    self.viewGroupConfigData = [NSMutableDictionary dictionary];
    
    for (NSDictionary *viewGroupJSON in viewGroupsJSON)
    {
        // recursively parse the view groups
        AlfrescoGroupConfigData *viewGroupConfigData = [self viewGroupDataFromJSON:viewGroupJSON];
        
        // store the view group config data object, if an identifier is present
        if (viewGroupConfigData.properties[kAlfrescoBaseConfigPropertyIdentifier] != nil)
        {
            NSString *identifier = viewGroupConfigData.properties[kAlfrescoBaseConfigPropertyIdentifier];
            NSMutableArray *storedArray = self.viewGroupConfigData[identifier];
            if (storedArray != nil)
            {
                [storedArray addObject:viewGroupConfigData];
            }
            else
            {
                self.viewGroupConfigData[identifier] = [NSMutableArray arrayWithObject:viewGroupConfigData];
            }
            
            AlfrescoLogDebug(@"Stored config data for view group with id: %@", identifier);
        }
    }
}

- (NSMutableDictionary *)viewDataFromJSON:(NSDictionary *)viewJSON viewId:(NSString *)viewId
{
    NSString *type = viewJSON[kAlfrescoJSONType];
    
    if (type == nil)
    {
        AlfrescoLogWarning(@"Ignoring view config with id '%@' as a type has not been provided", viewId);
        return nil;
    }
    
    // extract common properties
    NSMutableDictionary *viewProperties = [self configPropertiesFromJSON:viewJSON];
    
    // set the id of the view, if provided
    if (viewId != nil)
    {
        viewProperties[kAlfrescoBaseConfigPropertyIdentifier] = viewId;
    }
    
    // process formId
    NSString *formId = viewJSON[kAlfrescoJSONFormId];
    if (formId != nil)
    {
        viewProperties[kAlfrescoViewConfigPropertyFormIdentifier] = formId;
    }
    
    return viewProperties;
}

- (AlfrescoGroupConfigData *)viewGroupDataFromJSON:(NSDictionary *)viewGroupJSON
{
    // extract common properties
    NSMutableDictionary *viewGroupProperties = [self configPropertiesFromJSON:viewGroupJSON];
    
    // create config data object
    AlfrescoGroupConfigData *viewGroupConfigData = [AlfrescoGroupConfigData new];
    viewGroupConfigData.properties = viewGroupProperties;
    viewGroupConfigData.evaluator = viewGroupJSON[kAlfrescoJSONEvaluator];
    
    // process potential items, recursively
    NSArray *itemsJSON = viewGroupJSON[kAlfrescoJSONItems];
    NSMutableArray *potentialItemsArray = [NSMutableArray array];
    for (NSDictionary *groupItemJSON in itemsJSON)
    {
        NSString *itemType = groupItemJSON[kAlfrescoJSONItemType];
        if ([itemType isEqualToString:kAlfrescoJSONViewId])
        {
            NSString *reference = groupItemJSON[kAlfrescoJSONViewId];
            if (reference != nil)
            {
                // create and store a reference config data object
                AlfrescoConfigData *configData = [AlfrescoConfigData new];
                configData.reference = reference;
                configData.evaluator = groupItemJSON[kAlfrescoJSONEvaluator];
                [potentialItemsArray addObject:configData];
            }
        }
        else if ([itemType isEqualToString:kAlfrescoJSONView])
        {
            NSMutableDictionary *viewProperties = [self viewDataFromJSON:groupItemJSON[kAlfrescoJSONView] viewId:nil];
            if (viewProperties != nil)
            {
                // create and store view config data object
                AlfrescoConfigData *configData = [AlfrescoConfigData new];
                configData.properties = viewProperties;
                configData.evaluator = groupItemJSON[kAlfrescoJSONEvaluator];
                [potentialItemsArray addObject:configData];
            }
        }
        else if ([itemType isEqualToString:kAlfrescoJSONViewGroupId])
        {
            NSString *reference = groupItemJSON[kAlfrescoJSONViewGroupId];
            if (reference != nil)
            {
                // create and store a reference group config data object
                AlfrescoGroupConfigData *configData = [AlfrescoGroupConfigData new];
                configData.reference = reference;
                configData.evaluator = groupItemJSON[kAlfrescoJSONEvaluator];
                [potentialItemsArray addObject:configData];
            }
        }
        else if ([itemType isEqualToString:kAlfrescoJSONViewGroup])
        {
            // recursively parse the inline view group
            NSDictionary *childViewGroupJSON = groupItemJSON[kAlfrescoJSONViewGroup];
            if (childViewGroupJSON != nil)
            {
                [potentialItemsArray addObject:[self viewGroupDataFromJSON:childViewGroupJSON]];
            }
        }
    }
    
    // add potential items to config data object
    viewGroupConfigData.potentialItems = potentialItemsArray;
    
    return viewGroupConfigData;
}

#pragma mark - Resolving methods

- (AlfrescoGroupConfigData *)viewGroupDataForIdentifier:(NSString *)identifier scope:(AlfrescoConfigScope *)scope
{
    AlfrescoGroupConfigData *requestedViewGroupData = nil;
    
    NSArray *potentialViewGroupWithId = self.viewGroupConfigData[identifier];

    for (AlfrescoGroupConfigData *configData in potentialViewGroupWithId)
    {
        if ([self processEvaluator:configData.evaluator withScope:scope])
        {
            requestedViewGroupData = configData;
            break;
        }
    }
    
    return requestedViewGroupData;
}

- (AlfrescoViewGroupConfig *)resolveViewGroupConfigFromData:(AlfrescoGroupConfigData *)groupConfigData scope:(AlfrescoConfigScope *)scope
{
    if (groupConfigData != nil)
    {
        // firstly recursively resolve all potential items
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
                        // it's a reference to another view group so find first match and then recursively resolve
                        AlfrescoGroupConfigData *groupConfigData = [self viewGroupDataForIdentifier:configData.reference scope:scope];
                        if (groupConfigData != nil)
                        {
                            AlfrescoViewGroupConfig *viewGroupConfig = [self resolveViewGroupConfigFromData:groupConfigData scope:scope];
                            [items addObject:viewGroupConfig];
                        }
                        else
                        {
                            AlfrescoLogWarning(@"Ignoring reference to an invalid view group id reference: %@", configData.reference);
                        }
                    }
                    else
                    {
                        // it's another view group, recursively resolve
                        AlfrescoViewGroupConfig *viewGroupConfig = [self resolveViewGroupConfigFromData:(AlfrescoGroupConfigData*)configData scope:scope];
                        [items addObject:viewGroupConfig];
                    }
                }
                else
                {
                    if (configData.reference != nil)
                    {
                        // it's a reference to a view, retrieve view config
                        AlfrescoViewConfig *viewConfig = self.views[configData.reference];
                        if (viewConfig != nil)
                        {
                            [items addObject:viewConfig];
                        }
                        else
                        {
                            AlfrescoLogWarning(@"Ignoring reference to an invalid view id reference: %@", configData.reference);
                        }
                    }
                    else
                    {
                        // it's an inline view, create view config
                        AlfrescoViewConfig *viewConfig = [[AlfrescoViewConfig alloc] initWithDictionary:configData.properties];
                        [items addObject:viewConfig];
                    }
                }
            }
        }
        
        // create and return the final view group config object
        NSMutableDictionary *viewGroupProperties = [NSMutableDictionary dictionaryWithDictionary:groupConfigData.properties];
        viewGroupProperties[kAlfrescoGroupConfigPropertyItems] = items;
        
        return [[AlfrescoViewGroupConfig alloc] initWithDictionary:viewGroupProperties];
    }
    else
    {
        return nil;
    }
}

@end

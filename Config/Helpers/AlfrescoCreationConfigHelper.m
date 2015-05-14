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

#import "AlfrescoCreationConfigHelper.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoPropertyConstants.h"
#import "AlfrescoLog.h"
#import "AlfrescoItemConfig.h"

@interface AlfrescoCreationConfigHelper ()
@property (nonatomic, strong) NSMutableDictionary *mimeTypeCreationConfigData;
@property (nonatomic, strong) NSMutableDictionary *documentTypeCreationConfigData;
@property (nonatomic, strong) NSMutableDictionary *folderTypeCreationConfigData;
@end

@implementation AlfrescoCreationConfigHelper

#pragma mark - Public methods

-(void)parse
{
    NSDictionary *creationJSON = self.json[kAlfrescoJSONCreation];
    
    self.mimeTypeCreationConfigData = [self typeCreationDataFromJSON:creationJSON[kAlfrescoJSONMimeTypes]];
    self.documentTypeCreationConfigData = [self typeCreationDataFromJSON:creationJSON[kAlfrescoJSONDocumentTypes]];
    self.folderTypeCreationConfigData = [self typeCreationDataFromJSON:creationJSON[kAlfrescoJSONFolderTypes]];
}

- (AlfrescoCreationConfig *)creationConfigWithScope:(AlfrescoConfigScope *)scope
{
    NSMutableDictionary *creationConfigProperties = [NSMutableDictionary dictionary];
    
    NSArray *mimeTypeOptions = [self resolveOptionsConfigFromData:self.mimeTypeCreationConfigData scope:scope];
    if (mimeTypeOptions.count > 0)
    {
        creationConfigProperties[kAlfrescoCreationConfigPropertyCreatableMimeTypes] = mimeTypeOptions;
    }
    
    NSArray *documentOptions = [self resolveOptionsConfigFromData:self.documentTypeCreationConfigData scope:scope];
    if (documentOptions.count > 0)
    {
        creationConfigProperties[kAlfrescoCreationConfigPropertyCreatableDocumentTypes] = documentOptions;
    }
    
    NSArray *folderOptions = [self resolveOptionsConfigFromData:self.folderTypeCreationConfigData scope:scope];
    if (folderOptions.count > 0)
    {
        creationConfigProperties[kAlfrescoCreationConfigPropertyCreatableFolderTypes] = folderOptions;
    }
    
    // create and return the creation config object
    AlfrescoCreationConfig *creationConfig = [[AlfrescoCreationConfig alloc] initWithDictionary:creationConfigProperties];
    
    AlfrescoLogDebug(@"Returning creation config: %@", creationConfig);
    
    return creationConfig;
}

#pragma mark - Parsing methods

- (NSMutableDictionary *)typeCreationDataFromJSON:(NSArray *)typeCreationJSON
{
    NSMutableDictionary *typeCreationConfigData = [NSMutableDictionary dictionary];
    
    if (typeCreationJSON != nil)
    {
        for (NSDictionary *creationOptionJSON in typeCreationJSON)
        {
            NSString *identifier = creationOptionJSON[kAlfrescoJSONIdentifier];
            
            if (identifier == nil)
            {
                AlfrescoLogWarning(@"Ignoring creation config without identifier: %@", creationOptionJSON);
                break;
            }
            
            // extract common properties
            NSMutableDictionary *creationProperties = [self configPropertiesFromJSON:creationOptionJSON];
            
            // create config data object
            AlfrescoConfigData *creationConfigData = [AlfrescoConfigData new];
            creationConfigData.properties = creationProperties;
            creationConfigData.evaluator = creationOptionJSON[kAlfrescoJSONEvaluator];
            
            // store creationConfigData object
            NSMutableArray *storedArray = typeCreationConfigData[identifier];
            if (storedArray != nil)
            {
                [storedArray addObject:creationConfigData];
            }
            else
            {
                typeCreationConfigData[identifier] = [NSMutableArray arrayWithObject:creationConfigData];
            }
            
            AlfrescoLogDebug(@"Stored config data for type creation with id: %@", identifier);
        }
    }
    
    return typeCreationConfigData;
}

#pragma mark - Resolving methods

- (NSArray *)resolveOptionsConfigFromData:(NSDictionary *)configData scope:(AlfrescoConfigScope *)scope
{
    NSMutableArray *options = [NSMutableArray array];
    for (NSArray *potentialOptionWithId in [configData allValues])
    {
        for (AlfrescoConfigData *configData in potentialOptionWithId)
        {
            if ([self processEvaluator:configData.evaluator withScope:scope])
            {
                AlfrescoItemConfig *optionConfig = [[AlfrescoItemConfig alloc] initWithDictionary:configData.properties];
                [options addObject:optionConfig];
                
                AlfrescoLogDebug(@"Found matching creation config: %@", optionConfig);
                
                break;
            }
        }
    }
    
    return options;
}

@end

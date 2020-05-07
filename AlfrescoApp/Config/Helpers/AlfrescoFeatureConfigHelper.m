/*
 ******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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

#import "AlfrescoFeatureConfigHelper.h"
#import "AlfrescoConfigInternalConstants.h"
#import "AlfrescoConfigPropertyConstants.h"

@interface AlfrescoFeatureConfigHelper ()
@property (nonatomic, strong) NSMutableDictionary *featuresConfigData;
@end

@implementation AlfrescoFeatureConfigHelper

#pragma mark - Public methods

-(void)parse
{
    NSArray *featuresJSON = self.json[kAlfrescoJSONFeatures];

    self.featuresConfigData = [NSMutableDictionary dictionary];
    for (NSDictionary *featureJSON in featuresJSON)
    {
        NSString *identifier = featureJSON[kAlfrescoJSONIdentifier];
        
        if (identifier == nil)
        {
            AlfrescoLogWarning(@"Ignoring feature config without identifier: %@", featureJSON);
            break;
        }
        
        if (self.featuresConfigData[identifier] != nil)
        {
            AlfrescoLogWarning(@"Ignoring duplicate config identifier: %@", featureJSON);
            break;
        }
        
        // extract common properties
        NSMutableDictionary *featureProperties = [self configPropertiesFromJSON:featureJSON];
        
        // create config data object
        AlfrescoConfigData *featureConfigData = [AlfrescoConfigData new];
        featureConfigData.properties = featureProperties;
        featureConfigData.evaluator = featureJSON[kAlfrescoJSONEvaluator];
        
        // store featureConfigData object
        self.featuresConfigData[identifier] = featureConfigData;
        
        AlfrescoLogDebug(@"Stored config data for feature with id: %@", identifier);
    }
}

- (NSArray *)featureConfigWithScope:(AlfrescoConfigScope *)scope
{
    NSMutableArray *features = [NSMutableArray array];
    for (AlfrescoConfigData *configData in [self.featuresConfigData allValues])
    {
        if ([self processEvaluator:configData.evaluator withScope:scope])
        {
            AlfrescoFeatureConfig *featureConfig = [[AlfrescoFeatureConfig alloc] initWithDictionary:configData.properties];
            [features addObject:featureConfig];
            break;
        }
    }
    
    AlfrescoLogDebug(@"Returning feature config: %@", features);
    
    return features;
}

- (AlfrescoFeatureConfig *)featureConfigForIdentifier:(NSString *)identifier scope:(AlfrescoConfigScope *)scope
{
    AlfrescoFeatureConfig *requestedFeatureConfig = nil;
    AlfrescoConfigData *configData = self.featuresConfigData[identifier];

    if ([self processEvaluator:configData.evaluator withScope:scope])
    {
        requestedFeatureConfig = [[AlfrescoFeatureConfig alloc] initWithDictionary:configData.properties];
    }
    
    AlfrescoLogDebug(@"Returning feature config for identifier '%@': %@", identifier, requestedFeatureConfig);
    
    return requestedFeatureConfig;
}

- (AlfrescoFeatureConfig *)featureConfigForType:(NSString *)type scope:(AlfrescoConfigScope *)scope
{
    AlfrescoFeatureConfig *requestedFeatureConfig = nil;
    
    // for each id add the first one whose evaluator matches
    for (AlfrescoConfigData *configData in [self.featuresConfigData allValues])
    {
        if ([configData.properties[kAlfrescoJSONType] isEqualToString:type] && [self processEvaluator:configData.evaluator withScope:scope])
        {
            requestedFeatureConfig = [[AlfrescoFeatureConfig alloc] initWithDictionary:configData.properties];
            break;
        }
    }
    
    AlfrescoLogDebug(@"Returning feature config for type '%@': %@", type, requestedFeatureConfig);
    
    return requestedFeatureConfig;
}

- (NSMutableDictionary *)configPropertiesFromJSON:(NSDictionary *)json
{
    NSMutableDictionary *properties = [super configPropertiesFromJSON:json];
    NSNumber *enable = json[kAlfrescoJSONEnable];
    
    if (enable != nil)
    {
        properties[kAlfrescoJSONEnable] = enable;
    }
    
    return properties;
}

@end

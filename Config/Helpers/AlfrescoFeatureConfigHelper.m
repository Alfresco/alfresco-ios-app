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

#import "AlfrescoFeatureConfigHelper.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoPropertyConstants.h"
#import "AlfrescoLog.h"

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
        
        // extract common properties
        NSMutableDictionary *featureProperties = [self configPropertiesFromJSON:featureJSON];
        
        // create config data object
        AlfrescoConfigData *featureConfigData = [AlfrescoConfigData new];
        featureConfigData.properties = featureProperties;
        featureConfigData.evaluator = featureJSON[kAlfrescoJSONEvaluator];
        
        // store featureConfigData object
        NSMutableArray *storedArray = self.featuresConfigData[identifier];
        if (storedArray != nil)
        {
            [storedArray addObject:featureConfigData];
        }
        else
        {
            self.featuresConfigData[identifier] = [NSMutableArray arrayWithObject:featureConfigData];
        }
        
        AlfrescoLogDebug(@"Stored config data for feature with id: %@", identifier);
    }
}

- (NSArray *)featureConfigWithScope:(AlfrescoConfigScope *)scope
{
    NSMutableArray *features = [NSMutableArray array];
    for (NSArray *potentialFeatureWithId in [self.featuresConfigData allValues])
    {
        for (AlfrescoConfigData *configData in potentialFeatureWithId)
        {
            if ([self processEvaluator:configData.evaluator withScope:scope])
            {
                AlfrescoFeatureConfig *featureConfig = [[AlfrescoFeatureConfig alloc] initWithDictionary:configData.properties];
                [features addObject:featureConfig];
                break;
            }
        }
    }
    
    AlfrescoLogDebug(@"Returning feature config: %@", features);
    
    return features;
}

- (AlfrescoFeatureConfig *)featureConfigForIdentifier:(NSString *)identifier scope:(AlfrescoConfigScope *)scope
{
    AlfrescoFeatureConfig *requestedFeatureConfig = nil;
    
    NSArray *potentialFeatureWithId = self.featuresConfigData[identifier];
    // for each id add the first one whose evaluator matches
    for (AlfrescoConfigData *configData in potentialFeatureWithId)
    {
        if ([self processEvaluator:configData.evaluator withScope:scope])
        {
            requestedFeatureConfig = [[AlfrescoFeatureConfig alloc] initWithDictionary:configData.properties];
            break;
        }
    }
    
    AlfrescoLogDebug(@"Returning feature config for identifier '%@': %@", identifier, requestedFeatureConfig);
    
    return requestedFeatureConfig;
}

@end

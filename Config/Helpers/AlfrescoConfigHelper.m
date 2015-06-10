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

#import "AlfrescoConfigHelper.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoPropertyConstants.h"
#import "AlfrescoConfigEvaluator.h"
#import "AlfrescoLog.h"

@implementation AlfrescoConfigData
@end

@implementation AlfrescoGroupConfigData
@end


@interface AlfrescoConfigHelper ()
@property (nonatomic, strong, readwrite) NSDictionary *json;
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong, readwrite) NSDictionary *evaluators;
@end


@implementation AlfrescoConfigHelper

- (instancetype)initWithJSON:(NSDictionary *)json bundle:(NSBundle *)bundle evaluators:(NSDictionary *)evaluators
{
    self = [super init];
    if (nil != self)
    {
        self.json = json;
        self.bundle = bundle;
        self.evaluators = evaluators;
    }
    
    return self;
}

- (void)parse
{
    // This method should never be called, it MUST be overridden by a subclass
    NSException *exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Subclass should override this method."
                                                   userInfo:nil];
    @throw exception;
}

- (NSMutableDictionary *)configPropertiesFromJSON:(NSDictionary *)json
{
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    // process identifier
    NSString *identifier = json[kAlfrescoJSONIdentifier];
    if (identifier != nil)
    {
        properties[kAlfrescoBaseConfigPropertyIdentifier] = identifier;
    }
    
    // process label
    NSString *labelId = json[kAlfrescoJSONLabelId];
    if (labelId != nil)
    {
        // lookup label id from bundle
        NSString *label = labelId;
        if (self.bundle != nil)
        {
            label = NSLocalizedStringWithDefaultValue(labelId, nil, self.bundle, labelId, nil);
        }
        properties[kAlfrescoBaseConfigPropertyLabel] = label;
    }
    
    // process description
    NSString *descriptionId = json[kAlfrescoJSONDescriptionId];
    if (descriptionId != nil)
    {
        // lookup label id from bundle
        NSString *description = descriptionId;
        if (self.bundle != nil)
        {
            description = NSLocalizedStringWithDefaultValue(descriptionId, nil, self.bundle, descriptionId, nil);
        }
        properties[kAlfrescoBaseConfigPropertySummary] = description;
    }
    
    // process icon
    NSString *iconId = json[kAlfrescoJSONIconId];
    if (iconId != nil)
    {
        properties[kAlfrescoItemConfigPropertyIconIdentifier] = iconId;
    }
    
    // process type
    NSString *type = json[kAlfrescoJSONType];
    if (type != nil)
    {
        properties[kAlfrescoItemConfigPropertyType] = type;
    }
    
    // process parameters
    NSString *params = json[kAlfrescoJSONParams];
    if (params != nil)
    {
        properties[kAlfrescoItemConfigPropertyParameters] = params;
    }
    
    return properties;
}

- (BOOL)processEvaluator:(NSString *)evaluatorId withScope:(AlfrescoConfigScope *)scope
{
    BOOL result = NO;
    
    if (evaluatorId == nil)
    {
        result = YES;
    }
    else
    {
        // lookup the evaluator
        id<AlfrescoConfigEvaluator> evaluator = self.evaluators[evaluatorId];
        if (evaluator != nil)
        {
            AlfrescoLogDebug(@"Processing evaluator with id: %@", evaluatorId);
            
            // set the evaluators property for the match evaluator
            if ([evaluator isKindOfClass:[AlfrescoMatchEvaluator class]])
            {
                ((AlfrescoMatchEvaluator *)evaluator).evaluators = self.evaluators;
            }
            
            // process the evaluator
            result = [evaluator evaluate:scope];
            
            AlfrescoLogDebug(@"Evaluator '%@' result: %@", evaluatorId, result ? @"YES" : @"NO");
        }
        else
        {
            AlfrescoLogWarning(@"Unrecognised evaluator id: %@", evaluatorId);
        }
    }
    
    return result;
}

@end

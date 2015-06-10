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

#import <Foundation/Foundation.h>
#import "AlfrescoConfigScope.h"

// Helper class used to parse and resolve config.
@interface AlfrescoConfigHelper : NSObject

@property (nonatomic, strong, readonly) NSDictionary *json;
@property (nonatomic, strong, readonly) NSBundle *bundle;
@property (nonatomic, strong, readonly) NSDictionary *evaluators;

// Initialises the helper with the JSON, strings and evaluators
- (instancetype)initWithJSON:(NSDictionary *)json bundle:(NSBundle *)bundle evaluators:(NSDictionary *)evaluators;

// Parses the config JSON, a subclasses have to override this method.
- (void)parse;

// Extracts the properties required to construct AlfrescoItemConfig objects from the given JSON data.
- (NSMutableDictionary *)configPropertiesFromJSON:(NSDictionary *)json;

// Determines whether the given scope object passes the evaluator with the give identifier.
- (BOOL)processEvaluator:(NSString *)evaluatorId withScope:(AlfrescoConfigScope *)scope;

@end

// AlfrescoConfigData is an in-memory representation of an idividual item of config.
@interface AlfrescoConfigData : NSObject
@property (nonatomic, strong) NSDictionary *properties;
@property (nonatomic, strong) NSString *reference;
@property (nonatomic, strong) NSString *evaluator;
@end

// AlfrescoGroupConfigData is an in-memory representation of a group of config items.
@interface AlfrescoGroupConfigData : AlfrescoConfigData
@property (nonatomic, strong) NSArray *potentialItems;
@end


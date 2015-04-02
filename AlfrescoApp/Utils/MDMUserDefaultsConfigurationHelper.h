/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

#import <Foundation/Foundation.h>

@interface MDMUserDefaultsConfigurationHelper : NSObject

@property (nonatomic, strong, readonly) NSDictionary *rootManagedDictionary;

- (BOOL)isManaged;
- (id)valueForKey:(NSString *)key;
- (id)valueForKeyPath:(NSString *)keyPath;

// ONLY FOR TESTING PURPOSES, SHOULD BE REMOVED ONCE AIRWATCH IS SETUP
- (void)setManagedDictionary:(NSDictionary *)dictionary;

@end

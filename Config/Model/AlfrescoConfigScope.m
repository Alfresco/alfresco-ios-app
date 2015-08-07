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

#import "AlfrescoConfigScope.h"

@interface AlfrescoConfigScope ()
@property (nonatomic, strong, readwrite) NSString *profile;

@property (nonatomic, strong) NSMutableDictionary *internalContext;
@end

@implementation AlfrescoConfigScope

- (instancetype)initWithProfile:(NSString *)profile
{
    return [self initWithProfile:profile context:nil];
}

- (instancetype)initWithProfile:(NSString *)profile context:(NSDictionary *)context
{
    self = [super init];
    if (nil != self)
    {
        self.profile = profile;
        self.internalContext = [NSMutableDictionary dictionaryWithDictionary:context];
    }
    return self;
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    self.internalContext[key] = object;
}

- (void)addObjectsFromDictionary:(NSDictionary *)dictionary
{
    [self.internalContext addEntriesFromDictionary:dictionary];
}

- (id)valueForKey:(NSString *)key
{
    return self.internalContext[key];
}

- (NSDictionary *)context
{
    return [NSDictionary dictionaryWithDictionary:self.internalContext];
}

@end

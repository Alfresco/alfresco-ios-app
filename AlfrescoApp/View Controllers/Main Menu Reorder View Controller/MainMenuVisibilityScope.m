/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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

#import "MainMenuVisibilityScope.h"

static NSString * const kVisibleIdentifiersKey = @"visibleIdentifiers";
static NSString * const kHiddenIdentifiersKey = @"hiddenIdentifiers";

@implementation MainMenuVisibilityScope

+ (instancetype)visibilityScopeWithVisibleIdentifiers:(NSArray *)visibleIdentifiers hiddenIdentifiers:(NSArray *)hiddenIdentifiers
{
    MainMenuVisibilityScope *scope = [[MainMenuVisibilityScope alloc] initWithVisibilityIdentifiers:visibleIdentifiers hiddenIdentifiers:hiddenIdentifiers];
    return scope;
}

- (instancetype)initWithVisibilityIdentifiers:(NSArray *)visibleIdentifiers hiddenIdentifiers:(NSArray *)hiddenIdentifiers
{
    self = [self init];
    if (self)
    {
        self.visibleIdentifiers = visibleIdentifiers;
        self.hiddenIdentifiers = hiddenIdentifiers;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [self init];
    if (self)
    {
        self.visibleIdentifiers = [coder decodeObjectForKey:kVisibleIdentifiersKey];
        self.hiddenIdentifiers = [coder decodeObjectForKey:kHiddenIdentifiersKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.visibleIdentifiers forKey:kVisibleIdentifiersKey];
    [coder encodeObject:self.hiddenIdentifiers forKey:kHiddenIdentifiersKey];
}

@end

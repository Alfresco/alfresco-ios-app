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

#import "MainMenuSection.h"

@interface MainMenuSection ()
@property (nonatomic, assign, readwrite) BOOL sectionIsEditable;
@end

@implementation MainMenuSection

+ (instancetype)sectionItemWithTitle:(NSString *)title sectionItems:(NSArray *)sectionItems
{
    return [[MainMenuSection alloc] initWithTitle:title sectionItems:sectionItems editable:NO];
}

- (instancetype)initWithTitle:(NSString *)title sectionItems:(NSArray *)sectionItems
{
    return [self initWithTitle:title sectionItems:sectionItems editable:NO];
}

- (instancetype)initWithTitle:(NSString *)title sectionItems:(NSArray *)sectionItems editable:(BOOL)editable
{
    self = [self init];
    if (self)
    {
        self.sectionTitle = title;
        self.allSectionItems = (sectionItems) ? sectionItems.mutableCopy : [NSMutableArray array];
        self.sectionIsEditable = editable;
    }
    return self;
}

- (void)addMainMenuItem:(MainMenuItem *)mainMenuItem
{
    [self.allSectionItems addObject:mainMenuItem];
}

#pragma mark - Custom Getters and Setters

- (NSMutableArray *)visibleSectionItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hidden == %@", @(NO)];
    return [self.allSectionItems filteredArrayUsingPredicate:predicate].mutableCopy;
}

- (NSMutableArray *)hiddenSectionItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hidden == %@", @(YES)];
    return [self.allSectionItems filteredArrayUsingPredicate:predicate].mutableCopy;
}

@end

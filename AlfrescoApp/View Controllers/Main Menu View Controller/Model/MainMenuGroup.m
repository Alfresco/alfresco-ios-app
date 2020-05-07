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

#import "MainMenuGroup.h"

@interface MainMenuGroup ()
@property (nonatomic, strong, readwrite) NSMutableArray *sectionItems;
@end

@implementation MainMenuGroup

- (instancetype)initWithDelegate:(id<MainMenuGroupDelegate>)delegate
{
    self = [self init];
    if (self)
    {
        self.delegate = delegate;
        self.sectionItems = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Custom Getters and Setters

- (NSArray *)sections
{
    return [NSArray arrayWithArray:self.sectionItems];
}

#pragma mark - Public Methods

- (void)addSection:(MainMenuSection *)section
{
    [self.sectionItems addObject:section];
    [self.delegate mainMenuGroupDidChange:self];
}

- (void)addSectionsFromArray:(NSArray *)sections
{
    [self.sectionItems addObjectsFromArray:sections];
    [self.delegate mainMenuGroupDidChange:self];
}

- (void)removeSectionAtIndex:(NSUInteger)index
{
    index = (index > self.sections.count) ? self.sections.count : index;
    
    [self.sectionItems removeObjectAtIndex:index];
    [self.delegate mainMenuGroupDidChange:self];
}

- (void)clearGroup
{
    [self.sectionItems removeAllObjects];
    [self.delegate mainMenuGroupDidChange:self];
}

@end

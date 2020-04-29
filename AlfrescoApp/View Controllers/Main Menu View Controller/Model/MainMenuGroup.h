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

#import <Foundation/Foundation.h>
#import "MainMenuSection.h"

@class MainMenuGroup;

@protocol MainMenuGroupDelegate <NSObject>

- (void)mainMenuGroupDidChange:(MainMenuGroup *)group;

@end

@interface MainMenuGroup : NSObject

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, assign) id<MainMenuGroupDelegate> delegate;

- (instancetype)initWithDelegate:(id<MainMenuGroupDelegate>)delegate;

- (void)addSection:(MainMenuSection *)section;
- (void)addSectionsFromArray:(NSArray *)sections;
- (void)removeSectionAtIndex:(NSUInteger)index;
- (void)clearGroup;

@end

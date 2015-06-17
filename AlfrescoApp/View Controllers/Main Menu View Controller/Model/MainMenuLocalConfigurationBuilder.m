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

#import "MainMenuLocalConfigurationBuilder.h"
#import "AppConfigurationManager.h"

@interface MainMenuLocalConfigurationBuilder ()
@end

@implementation MainMenuLocalConfigurationBuilder

#pragma mark - Public Methods

- (void)sectionsForContentGroupWithCompletionBlock:(void (^)(NSArray *sections))completionBlock
{
    [super sectionsForContentGroupWithCompletionBlock:^(NSArray *sections) {
        AppConfigurationManager *configManager = [AppConfigurationManager sharedManager];
        
        // For each section, we ask the app configuration manager to set the visibility flags on each item and
        // reorder the visible section in the correct order
        // (The order for hidden items is not important)
        [sections enumerateObjectsUsingBlock:^(MainMenuSection *section, NSUInteger idx, BOOL *stop) {
            [configManager setVisibilityForMenuItems:section.allSectionItems forAccount:self.account];
            NSArray *sortedVisibleItems = [configManager orderedArrayFromUnorderedMainMenuItems:section.allSectionItems
                                                                        usingOrderedIdentifiers:[configManager visibleItemIdentifiersForAccount:self.account]
                                                                          appendNotFoundObjects:YES];
            section.allSectionItems = sortedVisibleItems.mutableCopy;
        }];
        
        completionBlock(sections);
    }];
}

@end

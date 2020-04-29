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
#import "AlfrescoProfileConfig.h"

@interface MainMenuItemsVisibilityUtils : NSObject

// Convience method to retrieve item identifiers for visible items
+ (NSArray *)visibleItemIdentifiersForAccount:(UserAccount *)account;

// Convience method to retrieve item identifiers for hidden items
+ (NSArray *)hiddenItemIdentifiersForAccount:(UserAccount *)account;

// Determines the visibility of each MainMenuItem passed in through the array and sets the 'hidden' flag when required
+ (void)setVisibilityForMenuItems:(NSArray *)menuItems forAccount:(UserAccount *)account;

// Persists the visible and hidden menu items. Takes arrays of MainMenuItems
+ (void)saveVisibleMenuItems:(NSArray *)visibleMenuItems hiddenMenuItems:(NSArray *)hiddenMenuItems forAccount:(UserAccount *)account;

// Takes an array of unordered main menu items and attempts to order then according to the ordered list of identifiers passed in.
// The append bool can be set to append the 'not found' objects to the result or not
+ (NSArray *)orderedArrayFromUnorderedMainMenuItems:(NSArray *)unorderedMenuItems usingOrderedIdentifiers:(NSArray *)orderListIdentifiers appendNotFoundObjects:(BOOL)append;

+ (void)isViewOfType:(NSString *)viewType presentInProfile:(AlfrescoProfileConfig *)profile forAccount:(UserAccount *)account completionBlock:(void (^)(BOOL isViewPresent, NSError *error))completionBlock;

@end

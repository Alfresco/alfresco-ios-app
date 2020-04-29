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

#import "MainMenuItemsVisibilityUtils.h"
#import "MainMenuVisibilityScope.h"
#import "UserAccount.h"
#import "MainMenuItem.h"
#import "AppConfigurationManager.h"

static NSString * const kMainMenuConfigurationDefaultsKey = @"Configuration";

@implementation MainMenuItemsVisibilityUtils

+ (NSArray *)visibleItemIdentifiersForAccount:(UserAccount *)account
{
    MainMenuVisibilityScope *visibilityScope = [MainMenuItemsVisibilityUtils mainMenuVisibilityScopeForAccount:account];
    
    return visibilityScope.visibleIdentifiers;
}

+ (NSArray *)hiddenItemIdentifiersForAccount:(UserAccount *)account
{
    MainMenuVisibilityScope *visibilityScope = [MainMenuItemsVisibilityUtils mainMenuVisibilityScopeForAccount:account];
    
    return visibilityScope.hiddenIdentifiers;
}

+ (MainMenuVisibilityScope *)mainMenuVisibilityScopeForAccount:(UserAccount *)account
{
    NSMutableDictionary *savedDictionary = ((NSDictionary *)[[NSUserDefaults standardUserDefaults] valueForKey:kMainMenuConfigurationDefaultsKey]).mutableCopy;
    NSString *accountIdentifier = account.accountIdentifier;
    MainMenuVisibilityScope *visibilityScope = [NSKeyedUnarchiver unarchiveObjectWithData:savedDictionary[accountIdentifier]];
    
    return visibilityScope;
}

+ (void)saveVisibleMenuItems:(NSArray *)visibleMenuItems hiddenMenuItems:(NSArray *)hiddenMenuItems forAccount:(UserAccount *)account
{
    NSArray *orderedVisibleIdentifiers = [visibleMenuItems valueForKey:@"itemIdentifier"];
    NSArray *orderedHiddenIdentifiers = [hiddenMenuItems valueForKey:@"itemIdentifier"];
    
    NSString *accountIdentifier = account.accountIdentifier;
    MainMenuVisibilityScope *visibility = [MainMenuVisibilityScope visibilityScopeWithVisibleIdentifiers:orderedVisibleIdentifiers hiddenIdentifiers:orderedHiddenIdentifiers];
    
    NSDictionary *accountDictionaryToPersist = @{accountIdentifier : [NSKeyedArchiver archivedDataWithRootObject:visibility]};
    
    NSMutableDictionary *savedDictionary = ((NSDictionary *)[[NSUserDefaults standardUserDefaults] valueForKey:kMainMenuConfigurationDefaultsKey]).mutableCopy;
    
    if (!savedDictionary)
    {
        savedDictionary = [NSMutableDictionary dictionary];
    }
    
    [savedDictionary addEntriesFromDictionary:accountDictionaryToPersist];
    
    [[NSUserDefaults standardUserDefaults] setObject:savedDictionary forKey:kMainMenuConfigurationDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray *)orderedArrayFromUnorderedMainMenuItems:(NSArray *)unorderedMenuItems usingOrderedIdentifiers:(NSArray *)orderListIdentifiers appendNotFoundObjects:(BOOL)append
{
    NSMutableArray *sortedItems = [NSMutableArray array];
    // Array holding all objects that have not been found in the ordered list of identifiers
    NSMutableArray *notFoundObjects = [NSMutableArray arrayWithArray:unorderedMenuItems];
    
    if (orderListIdentifiers)
    {
        [orderListIdentifiers enumerateObjectsUsingBlock:^(NSString *objectIdentifier, NSUInteger idx, BOOL *stop) {
            NSPredicate *search = [NSPredicate predicateWithFormat:@"itemIdentifier like %@", objectIdentifier];
            MainMenuItem *object = [unorderedMenuItems filteredArrayUsingPredicate:search].firstObject;
            if (object)
            {
                [sortedItems addObject:object];
                [notFoundObjects removeObject:object]; // remove the object if it has been found
            }
        }];
        
        // if we want the not found objects to be appended to the result array
        if (append)
        {
            [sortedItems addObjectsFromArray:notFoundObjects];
        }
    }
    else
    {
        sortedItems = unorderedMenuItems.mutableCopy;
    }
    
    return sortedItems;
}

+ (void)setVisibilityForMenuItems:(NSArray *)menuItems forAccount:(UserAccount *)account
{
    NSArray *hiddenIdentifiers = [MainMenuItemsVisibilityUtils hiddenItemIdentifiersForAccount:account];
    
    [hiddenIdentifiers enumerateObjectsUsingBlock:^(NSString *objectIdentifier, NSUInteger idx, BOOL *stop) {
        NSPredicate *search = [NSPredicate predicateWithFormat:@"itemIdentifier like %@", objectIdentifier];
        MainMenuItem *object = [menuItems filteredArrayUsingPredicate:search].firstObject;
        if (object)
        {
            object.hidden = YES;
        }
    }];
}

+ (void)isViewOfType:(NSString *)viewType presentInProfile:(AlfrescoProfileConfig *)profile forAccount:(UserAccount *)account completionBlock:(void (^)(BOOL isViewPresent, NSError *error))completionBlock
{
    AlfrescoConfigService *configService = [[AppConfigurationManager sharedManager] configurationServiceForAccount:account];
    [configService isViewWithType:viewType presentInProfile:profile completionBlock:completionBlock];
}

@end

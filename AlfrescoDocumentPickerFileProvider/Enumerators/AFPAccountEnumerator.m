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

#import "AFPAccountEnumerator.h"
#import "AFPItem.h"
#import "AFPDataManager.h"
#import "AFPItemIdentifier.h"
#import "AFPErrorBuilder.h"

@interface AFPAccountEnumerator()

@property (nonatomic, strong) NSFileProviderItemIdentifier itemIdentifier;

@end

@implementation AFPAccountEnumerator

- (instancetype)initWithItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
{
    self = [super init];
    if(self)
    {
        self.itemIdentifier = itemIdentifier;
    }
    
    return self;
}

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    NSError *authenticationError = [AFPErrorBuilder authenticationErrorForPIN];
    if (authenticationError)
    {
        [observer finishEnumeratingWithError:authenticationError];
    }
    else
    {
        NSMutableArray *enumeratedFolders = [NSMutableArray new];
        NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.itemIdentifier];
        RLMResults<AFPItemMetadata *> *menuItems = [[AFPDataManager sharedManager] menuItemsForAccount:accountIdentifier];
        for(AFPItemMetadata *menuItem in menuItems)
        {
            AFPItem *item = [[AFPItem alloc] initWithItemMetadata:menuItem];
            [enumeratedFolders addObject:item];
        }
        
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
        if (enumeratedFolders.count == 0)
        {
            [defaults setObject:accountIdentifier forKey:kFileProviderAccountNotActivatedKey];
            [defaults synchronize];
            
            [observer finishEnumeratingWithError:[AFPErrorBuilder authenticationError]];
        }
        else
        {
            [defaults removeObjectForKey:kFileProviderAccountNotActivatedKey];
            [defaults synchronize];
            [observer didEnumerateItems:enumeratedFolders];
            [observer finishEnumeratingUpToPage:nil];
        }
    }
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

@end

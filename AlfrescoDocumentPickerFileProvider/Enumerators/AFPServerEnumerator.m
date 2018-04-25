/*******************************************************************************
 * Copyright (C) 2005-2018 Alfresco Software Limited.
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

#import "AFPServerEnumerator+Internals.h"

@implementation AFPServerEnumerator

- (instancetype)initWithItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
{
    self = [super init];
    if(self)
    {
        self.itemIdentifier = itemIdentifier;
    }
    
    return self;
}

- (AlfrescoSiteService *)siteService
{
    if(_siteService)
    {
        [_siteService clear];
    }
    
    return _siteService;
}

#pragma mark - Internal methods
- (void)setupSessionWithCompletionBlock:(void (^)(id<AlfrescoSession> session))completionBlock
{
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.itemIdentifier];
    __weak typeof(self) weakSelf = self;
    self.accountManager = [AFPAccountManager sharedManager];
    [self.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
        if(loginError)
        {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf.observer finishEnumeratingWithError:loginError];
        }
        else
        {
            completionBlock(session);
        }
    }];
}

@end

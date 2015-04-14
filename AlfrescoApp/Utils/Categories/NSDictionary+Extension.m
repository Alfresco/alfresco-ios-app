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

#import "NSDictionary+Extension.h"

@implementation NSDictionary (Extension)

- (NSArray *)findMissingKeysFromArray:(NSArray *)searchKeys
{
    __block NSMutableArray *missingKeys = [NSMutableArray array];
    NSArray *myKeys = self.allKeys;
    
    [searchKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        if (![myKeys containsObject:key])
        {
            [missingKeys addObject:key];
        }
    }];
    
    return missingKeys;
}

@end

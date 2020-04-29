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

#import "NSMutableAttributedString+URLSupport.h"

@implementation NSMutableAttributedString(URLSupport)

- (BOOL)setAsLink:(NSString*)textToFind linkURL:(NSString*)linkURL
{
    NSRange foundRange = [self.mutableString rangeOfString:textToFind];
    if (foundRange.location != NSNotFound)
    {
        [self addAttribute:NSLinkAttributeName value:linkURL range:foundRange];
        return YES;
    }
    return NO;
}

@end

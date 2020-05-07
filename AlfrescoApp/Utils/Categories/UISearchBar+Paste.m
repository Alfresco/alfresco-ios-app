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

#import "UISearchBar+Paste.h"

@implementation UISearchBar (Paste)

// https://openradar.appspot.com/22774460
// http://stackoverflow.com/questions/38191290/enable-return-key-when-pasting-into-a-uisearchcontrollers-uisearchbar
// This is to fix the search key not appear when a text in pasted in an empty search field.
// The method should be called from - (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text in all controllers that support search.
// In order to not lose keyboard context (eg. style, caps) after the first typed character, the fix is limited to pasted strings of at least 2 characters length
- (void)enableReturnKeyForPastedText: (NSString *)text range:(NSRange)range
{
    if (text.length > 1 && range.length == 0 && range.location == 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resignFirstResponder];
            [self becomeFirstResponder];
        });
    }
}

@end

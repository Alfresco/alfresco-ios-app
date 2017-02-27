//
//  UISearchBar+Paste.m
//  AlfrescoApp
//
//  Created by Alexandru Posmangiu on 24/02/2017.
//  Copyright © 2017 Alfresco. All rights reserved.
//

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

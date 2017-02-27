//
//  UISearchBar+Paste.h
//  AlfrescoApp
//
//  Created by Alexandru Posmangiu on 24/02/2017.
//  Copyright © 2017 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UISearchBar (Paste)

- (void)enableReturnKeyForPastedText: (NSString *)text range:(NSRange)range;

@end

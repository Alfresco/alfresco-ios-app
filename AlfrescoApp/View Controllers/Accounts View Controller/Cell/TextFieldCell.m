//
//  AddAccountCell.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 01/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "TextFieldCell.h"

@implementation TextFieldCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.shouldBecomeFirstResponder && self.valueTextField.text.length == 0 && !self.valueTextField.isFirstResponder)
    {
        self.shouldBecomeFirstResponder = NO;
        [self.valueTextField becomeFirstResponder];
    }
}

@end

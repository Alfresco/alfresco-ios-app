//
//  AlfrescoFormFieldCellTableViewCell.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 14/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormCell.h"

NSString * const kAlfrescoFormFieldChangedNotification = @"AlfrescoFormFieldChangedNotification";

@implementation AlfrescoFormCell

- (void)setField:(AlfrescoFormField *)field
{
    _field = field;
    
    [self configureCell];
}

- (void)configureCell
{
    // TODO: investigate making this an internal protected method, category?
    
    if (self.field.required)
    {
        self.label.text = [NSString stringWithFormat:@"%@ *", self.field.label];
    }
    else
    {
        self.label.text = self.field.label;
    }
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.selectable = NO;
}

- (void)didSelectCellWithNavigationController:(UINavigationController *)navigationController
{
    // selectable cell subclasses will override this
}

@end

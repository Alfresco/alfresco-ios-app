//
//  BooleanFormField.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 09/04/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormBooleanCell.h"

@implementation AlfrescoFormBooleanCell

- (void)configureCell
{
    [super configureCell];
    
    NSLog(@"Configuring boolean cell for field %@", self.field.identifier);
    
    BOOL on = [self.field.value boolValue];
    self.switchControl.on = on;
    [self.switchControl addTarget:self action:@selector(fieldEdited:) forControlEvents:UIControlEventValueChanged];
}

- (void)fieldEdited:(id)sender
{
    self.field.value = [NSNumber numberWithBool:self.switchControl.on];
    
    NSLog(@"Boolean field %@ was edited, value changed to %@", self.field.identifier, self.switchControl.on ? @"YES" :@"NO");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoFormFieldChangedNotification object:self.field];
}

@end

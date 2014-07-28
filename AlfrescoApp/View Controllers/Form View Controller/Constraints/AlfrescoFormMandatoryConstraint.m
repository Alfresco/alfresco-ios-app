//
//  AlfrescoFormMandatoryConstraint.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 22/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormMandatoryConstraint.h"

NSString * const kAlfrescoFormConstraintMandatory = @"mandatory";

@implementation AlfrescoFormMandatoryConstraint

- (instancetype)init
{
    self = [super initWithIdentifier:kAlfrescoFormConstraintMandatory];
    if (self)
    {
        self.summary = @"This field is mandatory.";
    }
    return self;
}

- (BOOL)evaluate:(id)value
{
    // return immediately if value is nil
    if (value == nil) return NO;
    
    BOOL valid = YES;
    
    if ([value isKindOfClass:[NSString class]])
    {
        valid = (((NSString *)value).length > 0);
    }
    
    return valid;
}

@end

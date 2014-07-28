//
//  AlfrescoFormNumberRangeConstraint.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 22/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormNumberRangeConstraint.h"

NSString * const kAlfrescoFormConstraintNumberRange = @"numberRange";

@interface AlfrescoFormNumberRangeConstraint ()
@property (nonatomic, strong, readwrite) NSNumber *minimum;
@property (nonatomic, strong, readwrite) NSNumber *maximum;
@end

@implementation AlfrescoFormNumberRangeConstraint

- (instancetype)initWithMinimum:(NSNumber *)min maximum:(NSNumber *)max;
{
    self = [super initWithIdentifier:kAlfrescoFormConstraintNumberRange];
    if (self)
    {
        self.minimum = min;
        self.maximum = max;

        self.summary = [NSString stringWithFormat:@"The value of this field must be between %@ and %@", min, max];
    }
    return self;
}

- (BOOL)evaluate:(id)value
{
    // return immediately if value is nil
    if (value == nil) return NO;
    
    BOOL valid = NO;
    
    // if the provided value is the same as the min or max value it's valid
    // if the provided value is greater than the min and less than the max it's valid
    if([value compare:self.minimum] == NSOrderedSame ||
       [value compare:self.maximum] == NSOrderedSame ||
       ([value compare:self.minimum] == NSOrderedDescending && [value compare:self.maximum] == NSOrderedAscending))
    {
        valid = YES;
    }
    
    return valid;
}

@end
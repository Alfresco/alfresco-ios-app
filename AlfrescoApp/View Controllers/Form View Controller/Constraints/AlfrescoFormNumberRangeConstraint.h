//
//  AlfrescoFormNumberRangeConstraint.h
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 22/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormConstraint.h"

extern NSString * const kAlfrescoFormConstraintNumberRange;

@interface AlfrescoFormNumberRangeConstraint : AlfrescoFormConstraint

@property (nonatomic, strong, readonly) NSNumber *minimum;
@property (nonatomic, strong, readonly) NSNumber *maximum;

- (instancetype)initWithMinimum:(NSNumber *)min maximum:(NSNumber *)max;

@end

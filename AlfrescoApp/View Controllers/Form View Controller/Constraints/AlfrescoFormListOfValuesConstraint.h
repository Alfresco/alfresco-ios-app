//
//  AlfrescoFormListOfValuesConstraint.h
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 22/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormConstraint.h"

extern NSString * const kAlfrescoFormConstraintListOfValues;

@interface AlfrescoFormListOfValuesConstraint : AlfrescoFormConstraint

@property (nonatomic, strong, readonly) NSArray *values;
@property (nonatomic, strong, readonly) NSArray *labels;

- (instancetype)initWithValues:(NSArray *)values labels:(NSArray *)labels;

@end

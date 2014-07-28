//
//  AlfrescoFormConstraint.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 22/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormConstraint.h"

@interface AlfrescoFormConstraint ()
@property (nonatomic, strong, readwrite) NSString *identifier;
@end

@implementation AlfrescoFormConstraint

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self)
    {
        NSAssert(identifier, @"identifier parameter must be provided.");
        
        self.identifier = identifier;
    }
    return self;
}

- (BOOL)evaluate:(id)value
{
    NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"Subclasses must override this method"
                                                   userInfo:nil];
    @throw exception;
}

@end

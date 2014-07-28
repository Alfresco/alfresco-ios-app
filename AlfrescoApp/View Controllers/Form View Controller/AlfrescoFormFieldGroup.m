//
//  AlfrescoFormFieldGroup.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 14/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormFieldGroup.h"

@interface AlfrescoFormFieldGroup ()
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSArray *fields;
@end

@implementation AlfrescoFormFieldGroup

- (instancetype)initWithIdentifier:(NSString *)identifier fields:(NSArray *)fields
{
    return [self initWithIdentifier:identifier fields:fields label:nil summary:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier fields:(NSArray *)fields label:(NSString *)label
{
    return [self initWithIdentifier:identifier fields:fields label:label summary:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier fields:(NSArray *)fields label:(NSString *)label summary:(NSString *)summary
{
    self = [super init];
    if (self)
    {
        // TODO: Assert the required parameters are not nil
        
        self.identifier = identifier;
        self.fields = fields;
        self.label = label;
        self.summary = summary;
    }
    
    return self;
}

@end

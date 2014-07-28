//
//  AlfrescoForm.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 14/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoForm.h"

@interface AlfrescoForm ()
@property (nonatomic, strong, readwrite) NSArray *groups;
@end

@implementation AlfrescoForm

- (instancetype)initWithGroups:(NSArray *)groups title:(NSString *)title
{
    self = [super init];
    if (self)
    {
        // TODO: Assert the required parameters are not nil
        
        self.groups = groups;
        self.title = title;
    }
    
    return self;
}

- (NSArray *)fields
{
    NSMutableArray *fields = [NSMutableArray array];
    
    for (AlfrescoFormFieldGroup *group in self.groups)
    {
        [fields addObjectsFromArray:group.fields];
    }
    
    return fields;
}

- (BOOL)isValid
{
    // iterate round all fields and check their constraints, if they all pass the form is valid.
    for (AlfrescoFormField *field in self.fields)
    {
        // evaluate all constraints for the field
        for (AlfrescoFormConstraint *constraint in field.constraints)
        {
            NSLog(@"Evaluating %@ constraint for field %@", constraint.identifier, field.identifier);
            
            if (![constraint evaluate:field.value])
            {
                return NO;
            }
        }
    }
    
    return YES;
}

- (AlfrescoFormField *)fieldWithIdentifier:(NSString *)identifier
{
    // TODO: store fields in a dictionary to avoid loop below.
    
    for (AlfrescoFormField *field in self.fields)
    {
        if ([field.identifier isEqualToString:identifier])
        {
            return field;
        }
    }
    
    return nil;
}

@end

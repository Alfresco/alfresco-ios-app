//
//  AlfrescoFormField.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 14/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormField.h"
#import "AlfrescoFormMandatoryConstraint.h"

NSString * const kAlfrescoFormControlParameterCustomClassName = @"org.alfresco.mobile.form.control.customclassname";
NSString * const kAlfrescoFormControlParameterAllowReset = @"org.alfresco.mobile.form.control.allowreset";
NSString * const kAlfrescoFormControlParameterAllowDecimals = @"org.alfresco.mobile.form.control.allowdecimals";
NSString * const kAlfrescoFormControlParameterShowBorder = @"org.alfresco.mobile.form.control.showborder";

@interface AlfrescoFormField ()
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, assign, readwrite) AlfrescoFormFieldType type;
@property (nonatomic, strong, readwrite) id originalValue;
@property (nonatomic, strong, readwrite) NSArray *constraints;
@end

@implementation AlfrescoFormField

- (instancetype)initWithIdentifier:(NSString *)identifier type:(AlfrescoFormFieldType)type value:(id)value label:(NSString *)label
{
    self = [super init];
    if (self)
    {
        NSAssert(identifier, @"identifier parameter must be provided.");
        
        self.identifier = identifier;
        self.type = type;
        self.value = value;
        self.originalValue = self.value;
        self.label = label;
        
        // check for NSNull
        if ([self.value isKindOfClass:[NSNull class]])
        {
            self.value = nil;
            self.originalValue = nil;
        }
        if ([self.label isKindOfClass:[NSNull class]])
        {
            self.label = nil;
        }
    }
    return self;
}

- (BOOL)isRequired
{
    AlfrescoFormConstraint *mandatory = [self constraintWithIdentifier:kAlfrescoFormConstraintMandatory];
    return (mandatory != nil);
}

- (void)addConstraint:(AlfrescoFormConstraint *)constraint;
{
    if (constraint != nil)
    {
        if (self.constraints == nil)
        {
            self.constraints = [NSArray arrayWithObject:constraint];
        }
        else
        {
            self.constraints = [self.constraints arrayByAddingObject:constraint];
        }
    }
}

- (AlfrescoFormConstraint *)constraintWithIdentifier:(NSString *)identifier
{
    for (AlfrescoFormConstraint *constraint in self.constraints)
    {
        if ([constraint.identifier isEqualToString:identifier])
        {
            return constraint;
        }
    }
    
    return nil;
}

+ (NSString *)stringForFieldType:(AlfrescoFormFieldType)type
{
    NSString *typeString = nil;
    
    switch (type)
    {
        case AlfrescoFormFieldTypeString:
            typeString = @"string";
            break;
        case  AlfrescoFormFieldTypeBoolean:
            typeString = @"boolean";
            break;
        case  AlfrescoFormFieldTypeNumber:
            typeString = @"number";
            break;
        case  AlfrescoFormFieldTypeDate:
            typeString = @"date";
            break;
        case  AlfrescoFormFieldTypeDateTime:
            typeString = @"datetime";
            break;
        case  AlfrescoFormFieldTypeEmail:
            typeString = @"email";
            break;
        case  AlfrescoFormFieldTypeURL:
            typeString = @"url";
            break;
        case  AlfrescoFormFieldTypeCustom:
            typeString = @"custom";
            break;
        default:
            NSLog(@"ERROR: Inavlid field type %d", (int)type);
            break;
    }
    
    return typeString;
}

+ (AlfrescoFormFieldType)enumForTypeString:(NSString *)typeString
{
    AlfrescoFormFieldType type = AlfrescoFormFieldTypeUnknown;
    
    if ([typeString caseInsensitiveCompare:@"string"] == NSOrderedSame)
    {
        type = AlfrescoFormFieldTypeString;
    }
    else if ([typeString caseInsensitiveCompare:@"boolean"] == NSOrderedSame ||
             [typeString caseInsensitiveCompare:@"bool"] == NSOrderedSame)
    {
        type = AlfrescoFormFieldTypeBoolean;
    }
    else if ([typeString caseInsensitiveCompare:@"integer"] == NSOrderedSame ||
             [typeString caseInsensitiveCompare:@"int"] == NSOrderedSame ||
             [typeString caseInsensitiveCompare:@"double"] == NSOrderedSame ||
             [typeString caseInsensitiveCompare:@"float"] == NSOrderedSame ||
             [typeString caseInsensitiveCompare:@"long"] == NSOrderedSame)
    {
        type = AlfrescoFormFieldTypeNumber;
    }
    else if ([typeString caseInsensitiveCompare:@"date"] == NSOrderedSame)
    {
        type = AlfrescoFormFieldTypeDate;
    }
    else if ([typeString caseInsensitiveCompare:@"datetime"] == NSOrderedSame)
    {
        type = AlfrescoFormFieldTypeDateTime;
    }
    else if ([typeString caseInsensitiveCompare:@"email"] == NSOrderedSame)
    {
        type = AlfrescoFormFieldTypeEmail;
    }
    else if ([typeString caseInsensitiveCompare:@"url"] == NSOrderedSame)
    {
        type = AlfrescoFormFieldTypeURL;
    }
    else if ([typeString caseInsensitiveCompare:@"custom"] == NSOrderedSame)
    {
        type = AlfrescoFormFieldTypeCustom;
    }
    
    return type;
}

@end

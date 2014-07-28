//
//  AlfrescoFormFieldGroup.h
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 14/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlfrescoFormFieldGroup : NSObject

/**
 The unique identifer of the group.
 */
@property (nonatomic, strong, readonly) NSString *identifier;

/**
 List of AlfrescoFormField objects that are part of this group.
 */
@property (nonatomic, strong, readonly) NSArray *fields;

@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *summary;

- (instancetype)initWithIdentifier:(NSString *)identifier fields:(NSArray *)fields;

- (instancetype)initWithIdentifier:(NSString *)identifier fields:(NSArray *)fields label:(NSString *)label;

- (instancetype)initWithIdentifier:(NSString *)identifier fields:(NSArray *)fields label:(NSString *)label summary:(NSString *)summary;

@end

//
//  AlfrescoFormConstraint.h
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 22/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlfrescoFormConstraint : NSObject

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong) NSString *summary;

- (instancetype)initWithIdentifier:(NSString *)identifier;

- (BOOL)evaluate:(id)value;

@end

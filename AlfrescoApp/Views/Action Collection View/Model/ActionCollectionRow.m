//
//  ActionCollectionRow.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActionCollectionRow.h"

@interface ActionCollectionRow ()

@property (nonatomic, strong, readwrite) NSArray *rowItems;

@end

@implementation ActionCollectionRow

- (instancetype)initWithItems:(NSArray *)rowItems
{
    self = [super init];
    if (self)
    {
        self.rowItems = rowItems;
    }
    return self;
}

@end

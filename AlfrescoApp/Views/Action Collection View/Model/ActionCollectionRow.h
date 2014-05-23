//
//  ActionCollectionRow.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@interface ActionCollectionRow : NSObject

@property (nonatomic, strong, readonly) NSArray *rowItems;

- (instancetype)initWithItems:(NSArray *)rowItems;

@end

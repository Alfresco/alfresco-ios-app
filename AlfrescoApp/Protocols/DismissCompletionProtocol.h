//
//  DismissCompletionProtocol.h
//  AlfrescoApp
//
//  Created by Mike Hatfield on 17/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

typedef void (^DismissCompletionBlock)();

@protocol DismissCompletionProtocol <NSObject>

@property (nonatomic, copy) DismissCompletionBlock dismissCompletionBlock;

@end

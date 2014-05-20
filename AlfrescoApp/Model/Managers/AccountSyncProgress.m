//
//  AccountSyncProgress.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "AccountSyncProgress.h"

NSString * const kSyncProgressSizeKey = @"syncProgressSize";

@implementation AccountSyncProgress

- (id)initWithObserver:(id)observer
{
    self = [super init];
    if (self)
    {
        [self addObserver:observer forKeyPath:kSyncProgressSizeKey options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}
@end

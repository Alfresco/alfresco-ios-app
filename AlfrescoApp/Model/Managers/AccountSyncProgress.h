//
//  AccountSyncProgress.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kSyncProgressSizeKey;

@interface AccountSyncProgress : NSObject

@property (nonatomic, assign) unsigned long long totalSyncSize;
@property (nonatomic, assign) unsigned long long syncProgressSize;

- (id)initWithObserver:(id)observer;

@end

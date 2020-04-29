/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
 
#import "SystemNoticeManager.h"

@interface SystemNoticeManager ()
@property (nonatomic, strong) NSMutableArray *queuedNotices;
@property (nonatomic, strong) SystemNotice *displayingNotice;
@end

@implementation SystemNoticeManager

#pragma mark - Shared Instance

+ (SystemNoticeManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

#pragma mark - Lifecycle

- (id)init
{
    if (self = [super init])
    {
        self.queuedNotices = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Instance methods (Public)

- (void)queueSystemNotice:(SystemNotice *)systemNotice
{
    if ([self findSimilarQueuedNotice:systemNotice] == nil)
    {
        [self.queuedNotices addObject:systemNotice];
        [self processNoticeQueue];
    }
}

- (void)systemNoticeDidDisappear:(SystemNotice *)systemNotice
{
    self.displayingNotice = nil;
    [self.queuedNotices removeObject:systemNotice];
    [self processNoticeQueue];
}

#pragma mark - Instance methods (Private)

/**
 * Filter out duplicate error messages. Allow information and warning duplicates.
 */
- (SystemNotice *)findSimilarQueuedNotice:(SystemNotice *)systemNotice
{
    NSArray *queuedNotices = [NSArray arrayWithArray:self.queuedNotices];
    SystemNotice *similarQueuedNotice = nil;
    for (SystemNotice *queued in queuedNotices)
    {
        if ((systemNotice.noticeStyle == SystemNoticeStyleError) && [systemNotice isEqual:queued])
        {
            similarQueuedNotice = queued;
            break;
        }
    }
    return similarQueuedNotice;
}

- (void)processNoticeQueue
{
    if (self.displayingNotice)
    {
        return;
    }
    
    if ([self.queuedNotices count] > 0)
    {
        self.displayingNotice = [self.queuedNotices objectAtIndex:0];
//        [self.queuedNotices removeObjectAtIndex:0];
        [self.displayingNotice performSelector:@selector(canDisplay)];
    }
}

@end

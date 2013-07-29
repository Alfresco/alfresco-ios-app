//
//  SystemNoticeManager.m
//

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

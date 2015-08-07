//
//  SyncTest.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncTest.h"
#import "SyncManager.h"

@implementation SyncTest

- (void)testSync
{
    if (self.setUpSuccess)
    {
        SyncManager *syncManager = [SyncManager sharedManager];
        
        [syncManager syncDocumentsAndFoldersForSession:self.currentSession withCompletionBlock:^(NSArray *syncedNodes) {
            
            if (syncedNodes)
            {
                AlfrescoLogDebug(@"Favorite Nodes: %@", [[syncedNodes valueForKey:@"identifier"] valueForKey:@"lastPathComponent"]);
                self.lastTestSuccessful = YES;
            }
            self.callbackCompleted = YES;
        }];
        
        [self waitUntilCompleteWithFixedTimeInterval];
        XCTAssertTrue(self.lastTestSuccessful, @"%@", self.lastTestFailureMessage);
    }
    else
    {
        XCTFail(@"Could not run test case: %@", NSStringFromSelector(_cmd));
    }
}

@end

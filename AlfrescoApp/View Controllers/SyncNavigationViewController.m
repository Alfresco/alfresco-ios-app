//
//  SyncNavigationViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 13/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "SyncNavigationViewController.h"
#import "ProgressView.h"
#import "Utility.h"
#import "UIAlertView+ALF.h"

static CGFloat const kProgressViewAnimationDuration = 0.2f;

@interface SyncNavigationViewController ()

@property (nonatomic, assign) NSInteger numberOfSyncOperations;
@property (nonatomic, assign) unsigned long long totalSyncSize;
@property (nonatomic, assign) unsigned long long syncedSize;
@property (nonatomic, strong) ProgressView *progressView;
@property (nonatomic, assign) BOOL isProgressViewShowing;

@end

@implementation SyncNavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup navigation view frame
    CGRect navigationFrame = self.view.frame;
    navigationFrame.size.width = kRevealControllerMasterViewWidth;
    self.view.frame = navigationFrame;
    
    SyncManager *syncManager = [SyncManager sharedManager];
    syncManager.progressDelegate = self;
    
    self.progressView = [[ProgressView alloc] init];
    
    // setup progress view's frame to appear at the bottom of the navigation view
    CGRect progressViewFrame = self.progressView.frame;
    progressViewFrame.origin.y = navigationFrame.size.height;
    self.progressView.frame = progressViewFrame;
    [self.progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    
    [self.progressView.cancelButton addTarget:self action:@selector(cancelSyncOperations:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.progressView];
}

#pragma mark - Sync Manager Progress Delegate Methods

- (void)numberOfSyncOperationsInProgress:(NSInteger)numberOfOperations
{
    self.numberOfSyncOperations = numberOfOperations;
    [self updateProgressDetails];
    
    if (numberOfOperations > 0)
    {
        [self showSyncProgressDetails];
    }
    else
    {
        [self hideSyncProgressDetails];
    }
}

- (void)totalSizeToSync:(unsigned long long)totalSize syncedSize:(unsigned long long)syncedSize
{
    self.totalSyncSize = totalSize;
    self.syncedSize = syncedSize;
    [self updateProgressDetails];
}

#pragma mark - private Methods

- (void)cancelSyncOperations:(id)sender
{
    SyncManager *syncManager = [SyncManager sharedManager];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"sync.cancelAll.alert.title", @"Sync")
                                                    message:NSLocalizedString(@"sync.cancelAll.alert.message", @"Would you like to...")
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"sync.cancelAll.alert.button.continue", @"Continue")
                                          otherButtonTitles:NSLocalizedString(@"sync.cancelAll.alert.button.stop", @"Stop Sync"), nil];
    
    [alert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
        
        if (!isCancelButton)
        {
            [syncManager cancelAllSyncOperations];
            self.syncedSize = 0;
            self.totalSyncSize = 0;
            self.progressView.progressBar.progress = 0.0f;
        }
    }];
}

- (void)showSyncProgressDetails
{
    if (!self.isProgressViewShowing)
    {
        CGRect navFrame = self.view.bounds;
        CGRect progressViewFrame = self.progressView.frame;
        progressViewFrame.origin.y = navFrame.size.height - progressViewFrame.size.height;
        
        [UIView animateWithDuration:kProgressViewAnimationDuration animations:^{
            
            self.progressView.frame = progressViewFrame;
        }];
        
        self.isProgressViewShowing = YES;
    }
}

- (void)hideSyncProgressDetails
{
    self.totalSyncSize = 0;
    self.syncedSize = 0;
    self.progressView.progressBar.progress = 0.0f;
    
    if (self.isProgressViewShowing)
    {
        CGRect navFrame = self.view.bounds;
        CGRect progressViewFrame = self.progressView.frame;
        progressViewFrame.origin.y = navFrame.size.height;
        
        [UIView animateWithDuration:kProgressViewAnimationDuration animations:^{
            
            self.progressView.frame = progressViewFrame;
        }];
        
        self.isProgressViewShowing = NO;
    }
}

- (void)updateProgressDetails
{
    NSString *progressText = self.numberOfSyncOperations == 1 ? NSLocalizedString(@"sync.items.singular", @"item") : NSLocalizedString(@"sync.items.plural", @"items");
    NSString *leftToUpload = stringForLongFileSize(self.totalSyncSize - self.syncedSize);
    float percentTransfered = (float)self.syncedSize / (float)self.totalSyncSize;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progressInfoLabel.text =[NSString stringWithFormat:NSLocalizedString(@"sync.progress.label", @"Syncing %d %@, %@ left"), self.numberOfSyncOperations, progressText, leftToUpload];
        self.progressView.progressBar.progress = percentTransfered;
    });
}

@end

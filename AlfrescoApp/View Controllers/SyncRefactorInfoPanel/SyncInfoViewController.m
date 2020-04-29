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

#import "SyncInfoViewController.h"
#import "PagedScrollView.h"

#import "SyncFirstPanel.h"
#import "SyncSecondPanel.h"
#import "SyncThirdPanel.h"

#import "RootRevealViewController.h"
#import "UniversalDevice.h"

@interface SyncInfoViewController () <PagedScrollViewDelegate>

@property (weak, nonatomic) IBOutlet PagedScrollView *pagedScrollView;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@end

@implementation SyncInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.nextButton setTitle:NSLocalizedString(@"Next", @"Next") forState:UIControlStateNormal];
    [self.skipButton setTitle:NSLocalizedString(@"sync.info.skip", @"Skip") forState:UIControlStateNormal];
    self.pageControl.numberOfPages = 3;
    self.pageControl.currentPage = 0;
    
    self.pagedScrollView.pagingDelegate = self;
    
    SyncFirstPanel *firstPanel = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SyncFirstPanel class]) owner:self options:nil] firstObject];
    SyncSecondPanel *secondPanel = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SyncSecondPanel class]) owner:self options:nil] firstObject];
    SyncThirdPanel *thirdPanel = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SyncThirdPanel class]) owner:self options:nil] firstObject];
    
    [self.pagedScrollView addSubview:firstPanel];
    [self.pagedScrollView addSubview:secondPanel];
    [self.pagedScrollView addSubview:thirdPanel];
}

- (IBAction)skipButtonClicked:(id)sender
{
    [self notifyToDismissViewController];
}

- (IBAction)nextButtonClicked:(id)sender
{
    switch (self.pageControl.currentPage)
    {
        case 0:
        {
            self.pageControl.currentPage += 1;
            [self.pagedScrollView scrollToDisplayViewAtIndex:self.pageControl.currentPage animated:YES];
            break;
        }
        case 1:
        {
            self.pageControl.currentPage += 1;
            [self.pagedScrollView scrollToDisplayViewAtIndex:self.pageControl.currentPage animated:YES];
            [self pagedScrollViewDidScrollToFocusViewAtIndex:self.pageControl.currentPage whilstDragging:NO];
            break;
        }
        case 2:
        {
            [self notifyToDismissViewController];
            break;
        }
    }
}

- (void)notifyToDismissViewController
{
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kWasSyncInfoPanelShown];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if(self.parentViewController)
    {
        RootRevealViewController *rootRevealController = (RootRevealViewController *)[UniversalDevice revealViewController];
        
        if (rootRevealController.hasOverlayController)
        {
            [rootRevealController removeOverlayedViewControllerWithAnimation:YES];
        }
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - PagedScrollViewDelegate methods
- (void)pagedScrollViewDidScrollToFocusViewAtIndex:(NSInteger)viewIndex whilstDragging:(BOOL)dragging
{
    switch (viewIndex)
    {
        case 0:
        {
            [self.nextButton setTitle:NSLocalizedString(@"Next", @"Next") forState:UIControlStateNormal];
            self.skipButton.hidden = NO;
            break;
        }
        case 1:
        {
            [self.nextButton setTitle:NSLocalizedString(@"Next", @"Next") forState:UIControlStateNormal];
            self.skipButton.hidden = NO;
            break;
        }
        case 2:
        {
            [self.nextButton setTitle:NSLocalizedString(@"sync.info.next.laststep", @"Ok, I've got it.") forState:UIControlStateNormal];
            self.skipButton.hidden = YES;
            break;
        }
    }
    if(dragging)
    {
        self.pageControl.currentPage = viewIndex;
    }
}

@end

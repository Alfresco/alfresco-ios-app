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
 
#import "PagedScrollView.h"

@interface PagedScrollView () <UIScrollViewDelegate>

@property (nonatomic, assign, readwrite) NSUInteger selectedPageIndex;
@property (nonatomic, assign, readwrite) BOOL isScrollingToPosition;

@end

@implementation PagedScrollView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.selectedPageIndex = 0;
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.clipsToBounds = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNeedsLayout) name:kAlfrescoPagedScrollViewLayoutSubviewsNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self sortOutDelegates];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentSize = CGSizeMake((self.frame.size.width * self.subviews.count), self.frame.size.height);
    
    for (int i = 0; i < self.subviews.count; i++)
    {
        UIView *subView = self.subviews[i];
        
        CGRect scrollViewFrame = self.frame;
        CGRect subViewFrame = subView.frame;
        subViewFrame.origin.x = (scrollViewFrame.size.width * i);
        subViewFrame.size.width = scrollViewFrame.size.width;
        subViewFrame.size.height = scrollViewFrame.size.height;
        subView.frame = subViewFrame;
    }
    
    // triggered when resizing the view
    if (!self.isDragging && !self.isScrollingToPosition)
    {
        [self scrollToDisplayViewAtIndex:self.selectedPageIndex animated:NO];
    }
}

- (void)scrollToDisplayViewAtIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index >= 0 && index <= self.subviews.count)
    {
        CGPoint updatedOffset = CGPointMake(self.frame.size.width * index, self.bounds.origin.y);
        if (animated)
        {
            self.isScrollingToPosition = YES;
            [UIView animateWithDuration:0.3 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.contentOffset = updatedOffset;
            } completion:^(BOOL finished) {
                self.isScrollingToPosition = NO;
            }];
        }
        else
        {
            self.contentOffset = updatedOffset;
        }
        
        self.selectedPageIndex = index;
    }
}

#pragma mark - Private Functions

- (void)didRotate:(NSNotification *)notification
{
    [self layoutSubviews];
    [self scrollToDisplayViewAtIndex:self.selectedPageIndex animated:NO];
}

- (void)sortOutDelegates
{
    if ([self.delegate conformsToProtocol:@protocol(PagedScrollViewDelegate)])
    {
        self.pagingDelegate = (id<PagedScrollViewDelegate>)self.delegate;
    }
    else
    {
        AlfrescoLogError(@"The class %@ does not conform to the PagedScrollViewDelegate", [self.delegate class]);
    }
    self.delegate = self;
}

#pragma mark - UIScrollViewDelegate Functions

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    CGFloat pageWidth = self.frame.size.width;
    int page = floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    if (self.selectedPageIndex != page)
    {
        [self.pagingDelegate pagedScrollViewDidScrollToFocusViewAtIndex:page whilstDragging:self.isDragging];
        self.selectedPageIndex = page;
    }
}

@end

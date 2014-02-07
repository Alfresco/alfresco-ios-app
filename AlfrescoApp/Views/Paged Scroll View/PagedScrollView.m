//
//  PagedScrollView.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

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
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [self sortOutDelegates];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
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
    
    self.contentSize = CGSizeMake((self.frame.size.width * self.subviews.count), self.frame.size.height);
    
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
        NSLog(@"The class %@ does not conform to the PagedScrollViewDelegate", [self.delegate class]);
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

//
//  PagedScrollView.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@protocol PagedScrollViewDelegate <NSObject>

- (void)pagedScrollViewDidScrollToFocusViewAtIndex:(NSInteger)viewIndex whilstDragging:(BOOL)dragging;

@end

@interface PagedScrollView : UIScrollView

@property (nonatomic, weak, readwrite) id<PagedScrollViewDelegate> pagingDelegate;
@property (nonatomic, assign, readonly) NSUInteger selectedPageIndex;

- (void)scrollToDisplayViewAtIndex:(NSInteger)index animated:(BOOL)animated;

@end

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
  
@protocol PagedScrollViewDelegate <NSObject>

- (void)pagedScrollViewDidScrollToFocusViewAtIndex:(NSInteger)viewIndex whilstDragging:(BOOL)dragging;

@end

@interface PagedScrollView : UIScrollView

@property (nonatomic, weak, readwrite) id<PagedScrollViewDelegate> pagingDelegate;
@property (nonatomic, assign, readonly) NSUInteger selectedPageIndex;

- (void)scrollToDisplayViewAtIndex:(NSInteger)index animated:(BOOL)animated;

@end

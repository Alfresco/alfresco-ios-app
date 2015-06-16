/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

#import "ALFCollectionView.h"
#import "FileFolderCollectionViewCell.h"

@interface ALFCollectionView()

@property (nonatomic, strong) NSIndexPath *indexPathForCurrentSwipeToDelete;
@property (nonatomic) CGPoint initialPanPoint;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapToDismissDeleteAction;

@end

@implementation ALFCollectionView

- (void)awakeFromNib
{
    self.swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToDeleteGesture:)];
    self.swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:self.swipeGestureRecognizer];
    
    self.tapToDismissDeleteAction = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToDismissDeleteGesture:)];
    self.tapToDismissDeleteAction.numberOfTapsRequired = 1;
    self.tapToDismissDeleteAction.delegate = self;
    [self addGestureRecognizer:self.tapToDismissDeleteAction];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    self.editing = editing;
    NSArray *visibleIndexPaths = [self indexPathsForVisibleItems];
    for(NSIndexPath *indexPath in visibleIndexPaths)
    {
        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self cellForItemAtIndexPath:indexPath];
        [cell showEditMode:editing animated:animated];
    }
}

#pragma mark - Gesture reconizer handlers
- (void) swipeToDeleteGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if ((gestureRecognizer.state == UIGestureRecognizerStateEnded) && (!self.editing))
    {
        CGPoint touchPoint = [gestureRecognizer locationInView:self];
        if (CGRectContainsPoint(self.bounds, touchPoint))
        {
            NSIndexPath *indexPath = [self indexPathForItemAtPoint:touchPoint];
            if(self.isInDeleteMode)
            {
                [self showDeleteAction:NO forCellAtIndexPath:indexPath animated:YES];
            }
            else
            {
                [self showDeleteAction:YES forCellAtIndexPath:indexPath animated:YES];
            }
        }
    }
}

- (void) tapToDismissDeleteGesture:(UIGestureRecognizer *)gestureReconizer
{
    if((gestureReconizer.state == UIGestureRecognizerStateEnded) && self.isInDeleteMode)
    {
        CGPoint touchPoint = [gestureReconizer locationInView:self];
        UICollectionViewCell *cell = [self cellForItemAtIndexPath:self.indexPathForCurrentSwipeToDelete];
        if([cell isKindOfClass:[FileFolderCollectionViewCell class]])
        {
            FileFolderCollectionViewCell *properCell = (FileFolderCollectionViewCell *)cell;
            CGPoint touchPointInButton = [gestureReconizer locationInView:properCell.deleteButton];
            
            if((CGRectContainsPoint(self.bounds, touchPoint)) && (!CGRectContainsPoint(properCell.deleteButton.bounds, touchPointInButton)))
            {
                [self showDeleteAction:NO forCellAtIndexPath:self.indexPathForCurrentSwipeToDelete animated:YES];
            }
            else if(CGRectContainsPoint(properCell.deleteButton.bounds, touchPointInButton))
            {
                [self.swipeToDeleteDelegate collectionView:self didSwipeToDeleteItemAtIndex:self.indexPathForCurrentSwipeToDelete];
            }
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if(gestureRecognizer == self.tapToDismissDeleteAction)
    {
        if((self.isInDeleteMode) && (!self.editing))
        {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Private methods
- (void) showDeleteAction:(BOOL) showDelete forCellAtIndexPath:(NSIndexPath *) indexPath animated:(BOOL) animated
{
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
    if([cell isKindOfClass:[FileFolderCollectionViewCell class]])
    {
        FileFolderCollectionViewCell *properCell = (FileFolderCollectionViewCell *)cell;
        self.isInDeleteMode = showDelete;
        [properCell showDeleteAction:showDelete animated:animated];
        self.indexPathForCurrentSwipeToDelete = showDelete? indexPath : nil;
    }
}

@end

//
//  ALFCollectionView.m
//  AlfrescoApp
//
//  Created by Silviu Odobescu on 28/05/15.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import "ALFCollectionView.h"
#import "FileFolderCollectionViewCell.h"

@interface ALFCollectionView()

@property (nonatomic, strong) NSIndexPath *indexPathForCurrentSwipeToDelete;

@end

@implementation ALFCollectionView

- (void)awakeFromNib
{
    UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToDeleteGesture:)];
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:swipeGestureRecognizer];
    
    UITapGestureRecognizer *tapToDismissDeleteAction = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToDismissDeleteGesture:)];
    tapToDismissDeleteAction.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapToDismissDeleteAction];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    
}

#pragma mark - Gesture reconizer handlers
- (void) swipeToDeleteGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
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
            if((CGRectContainsPoint(self.bounds, touchPoint)) && (!CGRectContainsPoint(properCell.deleteButton.bounds, touchPoint)))
            {
                [self showDeleteAction:NO forCellAtIndexPath:self.indexPathForCurrentSwipeToDelete animated:YES];
            }
            else if(CGRectContainsPoint(properCell.deleteButton.bounds, touchPoint))
            {
                [self deleteItemsAtIndexPaths:[NSArray arrayWithObject:self.indexPathForCurrentSwipeToDelete]];
            }
        }
    }
}

#pragma mark - Private methods
- (void) showDeleteAction:(BOOL) showDelete forCellAtIndexPath:(NSIndexPath *) indexPath animated:(BOOL) animated
{
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
    if([cell isKindOfClass:[FileFolderCollectionViewCell class]])
    {
        FileFolderCollectionViewCell *properCell = (FileFolderCollectionViewCell *)cell;
        self.deleteMode = showDelete;
        [properCell showDeleteAction:showDelete animated:animated];
        self.indexPathForCurrentSwipeToDelete = showDelete? indexPath : nil;
    }
}

@end

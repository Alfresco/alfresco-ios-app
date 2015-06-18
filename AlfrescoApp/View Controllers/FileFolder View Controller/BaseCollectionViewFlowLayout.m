/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

#import "BaseCollectionViewFlowLayout.h"
#import "BaseLayoutAttributes.h"

@interface BaseCollectionViewFlowLayout ()

@property (nonatomic) CGFloat width;

@end

@implementation BaseCollectionViewFlowLayout

- (instancetype)init
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.numberOfColumns = 1;
    self.itemHeight = -1;
    
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.selectedIndexPathForSwipeToDelete = nil;
    
    self.headerReferenceSize = CGSizeMake(self.width, 40);
    
    return self;
}

#pragma mark - Custom Getters and Setters
- (CGFloat)width
{
    UIEdgeInsets insets = self.collectionView.contentInset;
    return CGRectGetWidth(self.collectionView.bounds) - (insets.left + insets.right);
}

- (void)setSelectedIndexPathForSwipeToDelete:(NSIndexPath *)selectedIndexPathForSwipeToDelete
{
    NSIndexPath *previousIndex = _selectedIndexPathForSwipeToDelete;
    _selectedIndexPathForSwipeToDelete = selectedIndexPathForSwipeToDelete;
    //hide the delete button from the previous selected index path
    UICollectionViewCell *previousCell = [self.collectionView cellForItemAtIndexPath:previousIndex];
    [previousCell applyLayoutAttributes:[self layoutAttributesForItemAtIndexPath:previousIndex]];
    //show the new delete button
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:_selectedIndexPathForSwipeToDelete];
    [cell applyLayoutAttributes:[self layoutAttributesForItemAtIndexPath:_selectedIndexPathForSwipeToDelete]];
}

- (void)selectedIndexPathForSwipeWasDeleted
{
    _selectedIndexPathForSwipeToDelete = nil;
}

- (void)setIsEditing:(BOOL)editing
{
    _editing = editing;
    _selectedIndexPathForSwipeToDelete = nil;
    NSArray *visibleItems = [self.collectionView indexPathsForVisibleItems];
    for(NSIndexPath *index in visibleItems)
    {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:index];
        [cell applyLayoutAttributes:[self layoutAttributesForItemAtIndexPath:index]];
    }
}

#pragma mark - Overriden methods
+ (Class)layoutAttributesClass
{
    return [BaseLayoutAttributes class];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return false;
}

- (void)prepareLayout
{
    CGFloat height = 0;
    if (self.itemHeight == -1)
    {
        height = self.width / self.numberOfColumns;
    }
    else
    {
        height = self.itemHeight;
    }
    
    self.itemSize = CGSizeMake(self.width / self.numberOfColumns, height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *layoutAttributes = [super layoutAttributesForElementsInRect:rect];
    for(BaseLayoutAttributes *attributes in layoutAttributes)
    {
        if(!self.isEditing)
        {
            if(self.selectedIndexPathForSwipeToDelete)
            {
                attributes.showDeleteButton = attributes.indexPath.item == self.selectedIndexPathForSwipeToDelete.item ? YES : NO;
            }
        }
        else
        {
            attributes.showDeleteButton = NO;
        }
        attributes.isEditing = self.isEditing;
    }
    
    return layoutAttributes;
}

- (BaseLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BaseLayoutAttributes *attributes = (BaseLayoutAttributes *)[super layoutAttributesForItemAtIndexPath:indexPath];
    if(!self.isEditing)
    {
        if(self.selectedIndexPathForSwipeToDelete)
        {
            attributes.showDeleteButton = indexPath.item == self.selectedIndexPathForSwipeToDelete.item ? YES : NO;
        }
    }
    else
    {
        attributes.showDeleteButton = NO;
    }
    attributes.isEditing = self.isEditing;
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
    
    return attributes;
}

@end

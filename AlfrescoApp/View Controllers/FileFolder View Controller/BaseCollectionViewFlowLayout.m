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

static CGFloat const itemSpacing = 10.0f;
static CGFloat const thumbnailWidthInListLayout = 40.0f;
static CGFloat const thumbnailSideSpaceInGridLayout = 10.0f;
static CGFloat const editImageTopSpaceInListLayout = 17.0f;
static CGFloat const editImageTopSpaceInGridLayout = 0.0f;

@interface BaseCollectionViewFlowLayout ()

@property (nonatomic) CGFloat collectionViewWidth;
@property (nonatomic) CGFloat thumbnailWidth;

@end

@implementation BaseCollectionViewFlowLayout

- (instancetype)initWithNumberOfColumns:(NSInteger)numberOfColumns itemHeight:(CGFloat)itemHeight shouldSwipeToDelete:(BOOL)shouldSwipeToDelete
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.numberOfColumns = numberOfColumns;
    self.itemHeight = itemHeight;
    self.shouldSwipeToDelete = shouldSwipeToDelete;
    
    self.minimumInteritemSpacing = self.minimumLineSpacing = (self.numberOfColumns == 1)? 0 : itemSpacing;
    
    self.selectedIndexPathForSwipeToDelete = nil;
    self.headerReferenceSize = CGSizeMake(self.collectionViewWidth, 40);
    
    return self;
}

#pragma mark - Custom Getters and Setters
- (CGFloat)collectionViewWidth
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
    BaseLayoutAttributes *previousAttributes = (BaseLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:previousIndex];
    previousAttributes.animated = YES;
    [previousCell applyLayoutAttributes:previousAttributes];
    //show the new delete button
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:_selectedIndexPathForSwipeToDelete];
    BaseLayoutAttributes *attributes = (BaseLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:_selectedIndexPathForSwipeToDelete];
    attributes.animated = YES;
    [cell applyLayoutAttributes:attributes];
}

- (void)selectedIndexPathForSwipeWasDeleted
{
    _selectedIndexPathForSwipeToDelete = nil;
}

- (void)setEditing:(BOOL)editing
{
    _editing = editing;
    _selectedIndexPathForSwipeToDelete = nil;
    NSArray *visibleItems = [self.collectionView indexPathsForVisibleItems];
    for(NSIndexPath *index in visibleItems)
    {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:index];
        BaseLayoutAttributes *attributes = (BaseLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:index];
        attributes.animated = YES;
        [cell applyLayoutAttributes:attributes];
    }
}

#pragma mark - Overriden methods
+ (Class)layoutAttributesClass
{
    return [BaseLayoutAttributes class];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return NO;
}

- (void)prepareLayout
{
    CGFloat height = 0;
    if (self.itemHeight == -1)
    {
        height = (self.collectionViewWidth - ((self.numberOfColumns + 1) * self.minimumInteritemSpacing)) / self.numberOfColumns  * 1.3f;
    }
    else
    {
        height = self.itemHeight;
    }
    
    self.itemSize = CGSizeMake((self.collectionViewWidth - ((self.numberOfColumns + 1) * self.minimumInteritemSpacing)) / self.numberOfColumns, height);
    
    self.thumbnailWidth = (self.numberOfColumns == 1)? thumbnailWidthInListLayout : self.itemSize.width - 2 * thumbnailSideSpaceInGridLayout;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *layoutAttributes = [super layoutAttributesForElementsInRect:rect];
    for(BaseLayoutAttributes *attributes in layoutAttributes)
    {
        if (attributes.representedElementCategory == UICollectionElementCategoryCell)
        {
            if(!self.isEditing)
            {
                if(self.selectedIndexPathForSwipeToDelete)
                {
                    attributes.showDeleteButton = attributes.indexPath.item == self.selectedIndexPathForSwipeToDelete.item;
                }
            }
            else
            {
                attributes.showDeleteButton = NO;
            }
            attributes.editing = self.isEditing;
            attributes.isSelectedInEditMode = [self.dataSourceInfoDelegate isItemSelected:attributes.indexPath];
            attributes.thumbnailWidth = self.thumbnailWidth;
            attributes.shouldShowSeparatorView = (self.numberOfColumns == 1);
            attributes.shouldShowAccessoryView = (self.numberOfColumns == 1);
            attributes.shouldShowNodeDetails = (self.numberOfColumns == 1);
            attributes.shouldShowEditBelowContent = (self.numberOfColumns == 1);
            attributes.shouldShowSmallThumbnailImage = (self.numberOfColumns == 1);
            attributes.nodeNameHorizontalDisplacement = (self.numberOfColumns == 1)? 58 : 10;
            attributes.nodeNameVerticalDisplacement = (self.numberOfColumns == 1)? 10 : self.thumbnailWidth + 2 * thumbnailSideSpaceInGridLayout;
            attributes.nodeNameFont = (self.numberOfColumns == 1)? [UIFont systemFontOfSize:17] : [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
            attributes.editImageTopSpace = (self.numberOfColumns == 1) ? editImageTopSpaceInListLayout : editImageTopSpaceInGridLayout;
        }
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BaseLayoutAttributes *attributes = (BaseLayoutAttributes *)[super layoutAttributesForItemAtIndexPath:indexPath];
    if(!self.isEditing)
    {
        if(self.shouldSwipeToDelete)
        {
            if(self.selectedIndexPathForSwipeToDelete)
            {
                attributes.showDeleteButton = indexPath.item == self.selectedIndexPathForSwipeToDelete.item;
            }
        }
        else
        {
            attributes.showDeleteButton = NO;
        }
    }
    else
    {
        attributes.showDeleteButton = NO;
    }
    attributes.animated = NO;
    attributes.editing = self.isEditing;
    attributes.isSelectedInEditMode = [self.dataSourceInfoDelegate isItemSelected:indexPath];
    attributes.thumbnailWidth = self.thumbnailWidth;
    attributes.shouldShowSeparatorView = (self.numberOfColumns == 1);
    attributes.shouldShowAccessoryView = (self.numberOfColumns == 1);
    attributes.shouldShowNodeDetails = (self.numberOfColumns == 1);
    attributes.shouldShowEditBelowContent = (self.numberOfColumns == 1);
    attributes.shouldShowSmallThumbnailImage = (self.numberOfColumns == 1);
    attributes.nodeNameHorizontalDisplacement = (self.numberOfColumns == 1)? 58 : 10;
    attributes.nodeNameVerticalDisplacement = (self.numberOfColumns == 1)? 10 : self.thumbnailWidth + 2 * thumbnailSideSpaceInGridLayout;
    attributes.nodeNameFont = (self.numberOfColumns == 1)? [UIFont systemFontOfSize:17] : [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
    attributes.editImageTopSpace = (self.numberOfColumns == 1) ? editImageTopSpaceInListLayout : editImageTopSpaceInGridLayout;
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    BaseLayoutAttributes *attributes = (BaseLayoutAttributes *)[super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    attributes.animated = NO;
    attributes.showDeleteButton = NO;
    attributes.editing = self.isEditing;
    attributes.isSelectedInEditMode = NO;
    attributes.thumbnailWidth = self.thumbnailWidth;
    attributes.shouldShowSeparatorView = (self.numberOfColumns == 1);
    attributes.shouldShowAccessoryView = (self.numberOfColumns == 1);
    attributes.shouldShowNodeDetails = (self.numberOfColumns == 1);
    attributes.shouldShowEditBelowContent = (self.numberOfColumns == 1);
    attributes.shouldShowSmallThumbnailImage = (self.numberOfColumns == 1);
    attributes.nodeNameHorizontalDisplacement = (self.numberOfColumns == 1)? 58 : 10;
    attributes.nodeNameVerticalDisplacement = (self.numberOfColumns == 1)? 10 : self.thumbnailWidth + 2 * thumbnailSideSpaceInGridLayout;
    attributes.nodeNameFont = (self.numberOfColumns == 1)? [UIFont systemFontOfSize:17] : [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
    attributes.editImageTopSpace = (self.numberOfColumns == 1) ? editImageTopSpaceInListLayout : editImageTopSpaceInGridLayout;
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
    return attributes;
}

@end

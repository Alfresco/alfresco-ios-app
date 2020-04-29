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

#import "BaseCollectionViewFlowLayout.h"
#import "BaseLayoutAttributes.h"
#import "FileFolderCollectionViewCell.h"

static CGFloat const kItemSpacing = 0.0f;
static CGFloat const kThumbnailWidthInListLayout = 40.0f;
static CGFloat const kThumbnailSideSpace = 10.0f;
static CGFloat const kEditImageTopSpaceInListLayout = 17.0f;
static CGFloat const kEditImageTopSpaceInGridLayout = 0.0f;
static CGFloat const kFolderNameTopSpace = 18.0f;
static CGFloat const kNodeTitleHeight = 40.0f;
static CGFloat const kDefaultPaddingSpacing = 30.0f;

@interface BaseCollectionViewFlowLayout ()

@property (nonatomic) CGFloat collectionViewWidth;
@property (nonatomic) CGFloat thumbnailWidth;

@property (nonatomic, strong) NSIndexPath *tempSwipeToDeleteIndexPath;

@end

@implementation BaseCollectionViewFlowLayout

- (instancetype)initWithNumberOfColumns:(NSInteger)numberOfColumns itemHeight:(CGFloat)itemHeight shouldSwipeToDelete:(BOOL)shouldSwipeToDelete hasHeader:(BOOL)hasHeader
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.numberOfColumns = numberOfColumns;
    self.itemHeight = itemHeight;
    self.shouldSwipeToDelete = shouldSwipeToDelete;
    
    self.minimumInteritemSpacing = self.minimumLineSpacing = (self.numberOfColumns == 1)? 0 : kItemSpacing;
    
    self.selectedIndexPathForSwipeToDelete = nil;
    self.headerReferenceSize = hasHeader ? CGSizeMake(self.collectionViewWidth, kCollectionViewHeaderHight) : CGSizeZero;
    self.shouldShowSmallThumbnail = (self.numberOfColumns == 1);
    
    return self;
}

#pragma mark - Custom Getters and Setters
- (CGFloat)collectionViewWidth
{
    UIEdgeInsets insets = self.collectionView.contentInset;
    return CGRectGetWidth(self.collectionView.bounds) - (insets.left + insets.right);
}

- (CGSize)collectionViewContentSize
{
    CGSize contentSizeToReturn = [super collectionViewContentSize];
    CGSize computedContentSize = [super collectionViewContentSize];
    UIEdgeInsets insets = self.collectionView.contentInset;
    
    if(computedContentSize.height < (self.collectionView.bounds.size.height - insets.top - insets.bottom))
    {
        contentSizeToReturn = CGSizeMake(computedContentSize.width, (self.collectionView.bounds.size.height - insets.top - insets.bottom + self.headerReferenceSize.height));
    }
    
    return contentSizeToReturn;
}

- (void)setSelectedIndexPathForSwipeToDelete:(NSIndexPath *)selectedIndexPathForSwipeToDelete
{
    NSIndexPath *previousIndex = _selectedIndexPathForSwipeToDelete;
    _selectedIndexPathForSwipeToDelete = selectedIndexPathForSwipeToDelete;
    
    if (previousIndex)
    {
        //hide the delete button from the previous selected index path
        UICollectionViewCell *previousCell = [self.collectionView cellForItemAtIndexPath:previousIndex];
        BaseLayoutAttributes *previousAttributes = (BaseLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:previousIndex];
        previousAttributes.animated = YES;
        [previousCell applyLayoutAttributes:previousAttributes];
    }
    
    if (selectedIndexPathForSwipeToDelete)
    {
        //show the new delete button
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:_selectedIndexPathForSwipeToDelete];
        BaseLayoutAttributes *attributes = (BaseLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:_selectedIndexPathForSwipeToDelete];
        attributes.animated = YES;
        [cell applyLayoutAttributes:attributes];
    }
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
        height = (self.collectionViewWidth - ((self.numberOfColumns + 1) * self.minimumInteritemSpacing)) / self.numberOfColumns + kNodeTitleHeight + kDefaultPaddingSpacing;
    }
    else
    {
        height = self.itemHeight;
    }
    
    self.itemSize = CGSizeMake((self.collectionViewWidth - ((self.numberOfColumns + 1) * self.minimumInteritemSpacing)) / self.numberOfColumns, height);
    
    self.thumbnailWidth = (self.numberOfColumns == 1)? kThumbnailWidthInListLayout : self.itemSize.width - 2 * kThumbnailSideSpace;
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    BOOL shouldRecomputeSwipeToDeleteIndexPath = NO;
    for(UICollectionViewUpdateItem *item in updateItems)
    {
        if((item.updateAction == UICollectionUpdateActionInsert) || (item.updateAction == UICollectionUpdateActionDelete))
        {
            shouldRecomputeSwipeToDeleteIndexPath = YES;
        }
    }
    
    if(shouldRecomputeSwipeToDeleteIndexPath)
    {
        [self recomputeSelectedIndexPathForSwipeToDelete];
    }
}

- (void)finalizeCollectionViewUpdates
{
    self.selectedIndexPathForSwipeToDelete = [self.tempSwipeToDeleteIndexPath copy];
    self.tempSwipeToDeleteIndexPath = nil;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *layoutAttributes = [super layoutAttributesForElementsInRect:rect];
    for(BaseLayoutAttributes *attributes in layoutAttributes)
    {
        if (attributes.representedElementCategory == UICollectionElementCategoryCell)
        {
            [self setupLayoutAttributes:attributes forIndexPath:attributes.indexPath];
        }
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BaseLayoutAttributes *attributes = (BaseLayoutAttributes *)[super layoutAttributesForItemAtIndexPath:indexPath];
    [self setupLayoutAttributes:attributes forIndexPath:indexPath];
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
    return attributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    BaseLayoutAttributes *attributes = (BaseLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:itemIndexPath];
    return attributes;
}

#pragma mark - Private methods
- (void)setupLayoutAttributes:(BaseLayoutAttributes *)attributes forIndexPath:(NSIndexPath *)indexPath
{
    if(!self.isEditing)
    {
        if(self.shouldSwipeToDelete)
        {
            if(self.selectedIndexPathForSwipeToDelete)
            {
                attributes.showDeleteButton = indexPath.item == self.selectedIndexPathForSwipeToDelete.item;
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
    }
    else
    {
        attributes.showDeleteButton = NO;
    }
    attributes.animated = NO;
    attributes.editing = self.isEditing;
    attributes.isSelectedInEditMode = [self.collectionViewMultiSelectDelegate isItemSelected:indexPath];
    attributes.thumbnailContentTrailingSpace = (self.numberOfColumns == 1) ? self.itemSize.width - kThumbnailWidthInListLayout - kThumbnailSideSpace : kThumbnailSideSpace;
    attributes.shouldShowSeparatorView = (self.numberOfColumns == 1);
    attributes.shouldShowAccessoryView = (self.numberOfColumns == 1);
    attributes.shouldShowNodeDetails = (self.numberOfColumns == 1);
    attributes.shouldShowEditBelowContent = (self.numberOfColumns == 1);
    attributes.shouldShowSmallThumbnailImage = self.shouldShowSmallThumbnail;
    attributes.nodeNameHorizontalDisplacement = (self.numberOfColumns == 1)? kThumbnailWidthInListLayout + 2 * kThumbnailSideSpace : kThumbnailSideSpace;
    attributes.nodeNameVerticalDisplacement = (self.numberOfColumns == 1)? ([self.dataSourceInfoDelegate isNodeAFolderAtIndex:indexPath])? kFolderNameTopSpace : kThumbnailSideSpace : self.thumbnailWidth + 2 * kThumbnailSideSpace;
    attributes.folderNameNoStatusVerticalDisplacement = kFolderNameTopSpace;
    attributes.folderNameWithStatusVerticalDisplacement = kFolderNameTopSpace;
    // On list layout - just one column - font size is 17
    // On grid layout - 2+ columns - font and font size the same as the one used in UISegmentedControl
    attributes.nodeNameFont = (self.numberOfColumns == 1)? [UIFont systemFontOfSize:17] : [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
    attributes.editImageTopSpace = (self.numberOfColumns == 1) ? kEditImageTopSpaceInListLayout : kEditImageTopSpaceInGridLayout;
    attributes.shouldShowStatusViewOverImage = (self.numberOfColumns != 1);
    attributes.filenameAligment = (self.numberOfColumns == 1) ? NSTextAlignmentLeft : NSTextAlignmentCenter;
}

- (void) recomputeSelectedIndexPathForSwipeToDelete
{
    FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:self.selectedIndexPathForSwipeToDelete];
    AlfrescoNode *node = cell.node;
    NSInteger newIndex = [self.dataSourceInfoDelegate indexOfNode:node];
    if(newIndex != NSNotFound)
    {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:newIndex inSection:0];
        self.tempSwipeToDeleteIndexPath = newIndexPath;
        self.selectedIndexPathForSwipeToDelete = nil;
    }
    else
    {
        self.tempSwipeToDeleteIndexPath = nil;
    }
}

@end

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
    
    self.minimumLineSpacing = 1;
    
    return self;
}

#pragma mark - Custom Getters and Setters
- (CGFloat)width
{
    UIEdgeInsets insets = self.collectionView.contentInset;
    return CGRectGetWidth(self.collectionView.bounds) - (insets.left + insets.right);
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
        NSLog(@"%@", attributes);
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BaseLayoutAttributes *attributes = (BaseLayoutAttributes *)[super layoutAttributesForItemAtIndexPath:indexPath];
    
    return attributes;
}

@end

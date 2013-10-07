//
//  ActionCollectionViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 03/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActionCollectionView.h"
#import "ActionCollectionViewCell.h"

static CGFloat const kCollectionCellWidth = 100.0f;
static CGFloat const kCollectionViewHeight = 100.0f;

@interface ActionCollectionView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSArray *rows;
@property (nonatomic, strong) NSMutableArray *collectionViews;

@property (nonatomic, weak) id<ActionCollectionViewDelegate> delegate;

@end

@implementation ActionCollectionView

- (instancetype)initWithRows:(NSArray *)rows delegate:(id<ActionCollectionViewDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        self.rows = rows;
        self.delegate = delegate;
        self.collectionViews = [NSMutableArray array];
        [self setup];
    }
    return self;
}

- (void)setup
{
    CGFloat currentYPosition = 0;
    for (ActionCollectionRow *row in self.rows)
    {
        UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
        flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, currentYPosition, self.frame.size.width, kCollectionViewHeight)
                                                              collectionViewLayout:flow];
        collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        collectionView.autoresizesSubviews = YES;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.backgroundColor = [UIColor lightTextColor];
        [self addSubview:collectionView];
        
        UINib *nib = [UINib nibWithNibName:NSStringFromClass([ActionCollectionViewCell class]) bundle:[NSBundle mainBundle]];
        [collectionView registerNib:nib forCellWithReuseIdentifier:@"ActionCell"];
        
        currentYPosition += kCollectionViewHeight;
        [self.collectionViews addObject:collectionView];
    }
    
    CGRect viewFrame = self.frame;
    viewFrame.size.height = currentYPosition;
    self.frame = viewFrame;
    
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    self.frame = newSuperview.bounds;
}

#pragma mark - UICollectionViewDataSource Functions

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    ActionCollectionRow *rowLocation = [self.rows objectAtIndex:section];
    return rowLocation.rowItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ActionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ActionCell" forIndexPath:indexPath];
    
    NSUInteger collectionViewIndexPath = [self.collectionViews indexOfObject:collectionView];
    ActionCollectionRow *actionRow = [self.rows objectAtIndex:collectionViewIndexPath];
    ActionCollectionItem *itemSelected = [actionRow.rowItems objectAtIndex:indexPath.row];
    cell.imageView.image = itemSelected.itemImage;
    cell.titleLabel.text = itemSelected.itemTitle;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate Functions

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger collectionViewIndexPath = [self.collectionViews indexOfObject:collectionView];
    ActionCollectionRow *actionRow = [self.rows objectAtIndex:collectionViewIndexPath];
    ActionCollectionItem *itemSelected = [actionRow.rowItems objectAtIndex:indexPath.row];
    
    [self.delegate didPressActionItem:itemSelected];
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kCollectionCellWidth, kCollectionViewHeight);
}

@end

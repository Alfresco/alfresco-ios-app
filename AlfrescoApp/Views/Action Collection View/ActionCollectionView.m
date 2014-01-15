//
//  ActionCollectionViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 03/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActionCollectionView.h"
#import "ActionCollectionViewCell.h"
#import "UICollectionView+AutoLayout.h"
#import "Utility.h"

static CGFloat const kActualSizePrority = 1000.0f;
static CGFloat const kDefaultMinRowHeight = 40.0f;
static CGFloat const kMinRowHeightPriority = 900.0f;
static CGFloat const kDefaultMaxRowHeight = 200.0f;
static CGFloat const kMaxRowHeightPriority = 750.0f;

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
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.collectionViews = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:kActionCollectionItemUpdateNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup
{
    for (ActionCollectionRow *row in self.rows)
    {
        UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
        flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initAutoLayoutWithCollectionViewLayout:flow];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.backgroundColor = [UIColor lightTextColor];
        [self addSubview:collectionView];
        
        UINib *nib = [UINib nibWithNibName:NSStringFromClass([ActionCollectionViewCell class]) bundle:[NSBundle mainBundle]];
        [collectionView registerNib:nib forCellWithReuseIdentifier:@"ActionCell"];

        [self.collectionViews addObject:collectionView];
        
        NSDictionary *dictionary = NSDictionaryOfVariableBindings(collectionView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:dictionary]];
    }
    
    NSDictionary *viewBindings = dictionaryOfVariableBindingsWithArray(self.collectionViews);
    NSString *verticalVisualFormatLanguage = [self buildVerticalConstraintsStringForBindingsOfCollectionViews:viewBindings];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalVisualFormatLanguage options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewBindings]];
}

- (void)didMoveToSuperview
{
    [self.collectionViews removeAllObjects];
    [self removeConstraints:self.constraints];
    [self removeAllSubviews];
    [self setup];
}

#pragma mark - Private Functions

- (void)handleUpdateNotification:(NSNotification *)notification
{
    for (UICollectionView *collectionView in self.collectionViews)
    {
        [collectionView reloadData];
    }
}

- (NSString *)buildVerticalConstraintsStringForBindingsOfCollectionViews:(NSDictionary *)bindings
{
    NSArray *allViewKeys = [bindings allKeys];
    NSMutableString *verticalConstraintsString = [[NSMutableString alloc] initWithString:@"V:"];
    for (int i = 0; i  < allViewKeys.count; i++)
    {
        if (i == 0)
        {
            [verticalConstraintsString appendString:@"|"];
        }
        
        NSString *currentViewKey = allViewKeys[i];
        [verticalConstraintsString appendString:[NSString stringWithFormat:@"[%@(<=%f@%f,>=%f@%f,==%f@%f)]",
                                          currentViewKey, kDefaultMaxRowHeight, kMaxRowHeightPriority, kDefaultMinRowHeight, kMinRowHeightPriority,
                                          self.superview.bounds.size.height/self.collectionViews.count, kActualSizePrority]];
        
        if (i == (allViewKeys.count - 1))
        {
            [verticalConstraintsString appendString:@"|"];
        }
    }
    return verticalConstraintsString;
}

- (void)removeAllSubviews
{
    for (UIView *subview in self.subviews)
    {
        [subview removeFromSuperview];
    }
}

#pragma mark - UICollectionViewDataSource Functions

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSUInteger collectionViewIndexPath = [self.collectionViews indexOfObject:collectionView];
    ActionCollectionRow *rowLocation = [self.rows objectAtIndex:collectionViewIndexPath];
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
    
    UICollectionViewCell *selectedCell = [collectionView cellForItemAtIndexPath:indexPath];
    
    [self.delegate didPressActionItem:itemSelected cell:selectedCell inView:collectionView];
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.frame.size.height, collectionView.frame.size.height);
}

@end

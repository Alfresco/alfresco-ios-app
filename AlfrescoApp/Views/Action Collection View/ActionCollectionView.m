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
#import "UIView+DrawingUtils.h"

static CGFloat const kSpacingBetweenSections = 8.0f;
static CGFloat const kiPadSpacingBetweenCells = 15.0f;
static CGFloat const kiPhoneSpacingBetweenCells = 10.0f;
static CGFloat const kiPadCellWidth = 76.0f;
static CGFloat const kiPhoneCellWidth = 60.0f;
static CGFloat const kLineButtonPadding = 10.0f;
static CGFloat const kLineSeparatorThickness = 1.0f;

@interface ActionCollectionView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) UICollectionView *collectionView;

@end

@implementation ActionCollectionView

- (instancetype)initWithItems:(NSArray *)items delegate:(id<ActionCollectionViewDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        self.items = items;
        self.delegate = delegate;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)drawRect:(CGRect)rect
{
    CGPoint startPoint = CGPointMake(0, 0);
    CGPoint endPoint = CGPointMake(self.frame.size.width, 0);
    UIColor *blackColour = [UIColor darkGrayColor];
    
    [self drawLineFromPoint:startPoint toPoint:endPoint lineThickness:kLineSeparatorThickness colour:blackColour];
}

- (void)setup
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
    self.collectionView = collectionView;
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([ActionCollectionViewCell class]) bundle:[NSBundle mainBundle]];
    [collectionView registerNib:nib forCellWithReuseIdentifier:@"ActionCell"];
    
    
    NSDictionary *viewBindings = NSDictionaryOfVariableBindings(collectionView);
    NSDictionary *metrics = @{@"kLineButtonPadding" : [NSNumber numberWithFloat:kLineButtonPadding]};

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|" options:0 metrics:nil views:viewBindings]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-kLineButtonPadding@750-[collectionView]|" options:0 metrics:metrics views:viewBindings]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:kActionCollectionItemUpdateNotification object:nil];
}

#pragma mark - Custom Setters

- (void)setItems:(NSArray *)items
{
    _items = items;
    [self.collectionView reloadData];
}

#pragma mark - Private Functions

- (void)handleUpdateNotification:(NSNotification *)notification
{
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource Functions

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ActionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ActionCell" forIndexPath:indexPath];
    ActionCollectionItem *itemSelected = [self.items objectAtIndex:indexPath.row];
    
    cell.imageView.image = itemSelected.itemImage;
    cell.imageView.highlightedImage = itemSelected.itemImageHighlightedImage;
    cell.imageView.tintColor = [UIColor documentActionsTintColor];
    cell.titleLabel.text = itemSelected.itemTitle;
    cell.titleLabel.highlightedTextColor = itemSelected.itemTitleHighlightedColor;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate Functions

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ActionCollectionItem *itemSelected = [self.items objectAtIndex:indexPath.row];
    UICollectionViewCell *selectedCell = [collectionView cellForItemAtIndexPath:indexPath];
    
    [self.delegate didPressActionItem:itemSelected cell:selectedCell inView:collectionView];
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize cellSize = CGSizeMake(kiPhoneCellWidth, collectionView.frame.size.height);
    
    if (IS_IPAD)
    {
        cellSize.width = kiPadCellWidth;
    }
    
    return cellSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, kSpacingBetweenSections, 0, kSpacingBetweenSections);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return IS_IPAD ? kiPadSpacingBetweenCells : kiPhoneSpacingBetweenCells;
}

@end

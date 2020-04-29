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
 
#import "ActionCollectionView.h"
#import "ActionCollectionViewCell.h"
#import "UICollectionView+AutoLayout.h"
#import "UIView+DrawingUtils.h"

static CGFloat const kSpacingBetweenSections = 4.0f;
static CGFloat const kSpacingBetweenCells = 0.0f;
static CGFloat const kiPadCellWidth = 90.0f;
static CGFloat const kiPhoneCellWidth = 68.0f;
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
    [super awakeFromNib];
    
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
    /*
     ActionCollectionViewCell used by self.collectionView is set up with an ActionCollectionItem, which is observer for this notification, too.
     We have to make sure that the ActionCollectionItem is up to date before reloading the collection view.
     */
    __weak typeof(self) weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.collectionView reloadData];
    });
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
    cell.accessibilityIdentifier = itemSelected.accessibilityIdentifier;
    
    // Workaround what seems to be a bug in iOS that doesn't scale down the font size when required
    cell.titleLabel.numberOfLines = ([itemSelected.itemTitle rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location == NSNotFound) ? 1 : 2;
    
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
    return CGSizeMake(IS_IPAD ? kiPadCellWidth : kiPhoneCellWidth, collectionView.frame.size.height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, kSpacingBetweenSections, 0, kSpacingBetweenSections);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return kSpacingBetweenCells;
}

@end

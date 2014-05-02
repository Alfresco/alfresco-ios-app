//
//  ALFTableView.m
//  AlfrescoApp
//
//  Created by Mike Hatfield on 01/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ALFTableView.h"
#import "AttributedLabelCell.h"


@interface ALFTableView ()
@property (nonatomic, strong) UILabel *alfEmptyLabel;
@property (nonatomic, assign) NSNumber *alfPreviousSeparatorStyle;
@end

@implementation ALFTableView

#pragma mark - UITableView overrides

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [super deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self updateEmptyView];
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [super insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self updateEmptyView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateEmptyView];
}

- (void)reloadData
{
    [super reloadData];
    [self updateEmptyView];
}


#pragma mark - Internal Implementation

- (void)updateEmptyView
{
    if (!self.alfEmptyLabel)
    {
        UILabel *emptyLabel = [[UILabel alloc] init];
        emptyLabel.font = [UIFont systemFontOfSize:24.0];
        emptyLabel.numberOfLines = 0;
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        emptyLabel.textColor = [UIColor noItemsTextColor];
        emptyLabel.hidden = YES;
        
        [self addSubview:emptyLabel];
        self.alfEmptyLabel = emptyLabel;
    }

    CGRect frame = self.bounds;
    frame.origin = CGPointMake(0, 0);
    frame = UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(CGRectGetHeight(self.tableHeaderView.frame), 0, 0, 0));
    frame.size.height -= self.contentInset.top;

    self.alfEmptyLabel.frame = frame;
    self.alfEmptyLabel.text = self.emptyMessage ?: NSLocalizedString(@"No Items", @"No Items");
    self.alfEmptyLabel.insetTop = -(frame.size.height / 3.0);
    self.alfEmptyLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);

    BOOL shouldShowEmptyLabel = [self isDataSetEmpty];
    BOOL isShowingEmptyLabel = !self.alfEmptyLabel.hidden;
    
    if (shouldShowEmptyLabel == isShowingEmptyLabel)
    {
        // Nothing to do
        return;
    }

    // Need to remove the separator lines in empty mode and restore afterwards
    if (shouldShowEmptyLabel)
    {
        self.previousSeparatorStyle = self.separatorStyle;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    else
    {
        self.separatorStyle = self.previousSeparatorStyle;
    }
    self.alfEmptyLabel.hidden = !shouldShowEmptyLabel;
}

- (BOOL)isDataSetEmpty
{
    NSInteger numberOfRows = 0;
    for (NSInteger sectionIndex = 0; sectionIndex < self.numberOfSections; sectionIndex++)
    {
        numberOfRows += [self numberOfRowsInSection:sectionIndex];
    }
    return (numberOfRows == 0);
}

- (UITableViewCellSeparatorStyle)previousSeparatorStyle
{
    return self.alfPreviousSeparatorStyle ? [self.alfPreviousSeparatorStyle integerValue] : self.separatorStyle;
}

- (void)setPreviousSeparatorStyle:(UITableViewCellSeparatorStyle)value
{
    self.alfPreviousSeparatorStyle = [NSNumber numberWithInteger:value];
}

@end

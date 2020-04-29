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
 
#import "MultiSelectActionsToolbar.h"
#import "MultiSelectActionItem.h"

static CGFloat const kMultiSelectAnimationDurationLegacy = 0.2f;

static CGFloat const kToolBarMaxHeightConstraintValue = 44.0f;
static CGFloat const kToolBarMinHeightConstraintValue = 0.0f;

@interface MultiSelectActionsToolbar ()

@property (nonatomic, strong) NSMutableOrderedSet *actionItems;

@end

@implementation MultiSelectActionsToolbar

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _actionItems = [[NSMutableOrderedSet alloc] init];
        _selectedItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _actionItems = [[NSMutableOrderedSet alloc] init];
        _selectedItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)enterMultiSelectMode:(NSLayoutConstraint *)heightConstraint
{
    [self.selectedItems removeAllObjects];
    [self updateToolBarButtonTitles];
    self.items = [self.actionItems array];
    
    heightConstraint.constant = kToolBarMaxHeightConstraintValue;
    [UIView animateWithDuration:kMultiSelectAnimationDurationLegacy animations:^{
        self.alpha = 1.0f;
        [self layoutIfNeeded];
    }];
}

- (void)leaveMultiSelectMode:(NSLayoutConstraint *)heightConstraint
{
    self.items = nil;
    heightConstraint.constant = kToolBarMinHeightConstraintValue;
    [UIView animateWithDuration:kMultiSelectAnimationDurationLegacy animations:^{
        self.alpha = 0.0f;
        [self layoutIfNeeded];
    }];
}

- (void)enterMultiSelectMode
{
    [self.selectedItems removeAllObjects];
    [self updateToolBarButtonTitles];
    self.items = [self.actionItems array];
}

- (void)leaveMultiSelectMode
{
    self.items = nil;
}

#pragma mark - Private instance methods

- (void)notifyDelegateItemsDidChange
{
    if ([self.multiSelectDelegate respondsToSelector:@selector(multiSelectItemsDidChange:)])
    {
        [self.multiSelectDelegate multiSelectItemsDidChange:self.selectedItems];
    }
}

- (void)notifyDelegateUserDidPerformAction:(MultiSelectActionItem *)actionItem
{
    if ([self.multiSelectDelegate respondsToSelector:@selector(multiSelectUserDidPerformAction:selectedItems:)])
    {
        [self.multiSelectDelegate multiSelectUserDidPerformAction:actionItem.actionId selectedItems:self.selectedItems];
    }
}

- (UIBarButtonItem *)createToolBarButtonForTitleKey:(NSString *)titleLocalizationKey actionId:(NSString *)actionId isDestructive:(BOOL)isDestructive
{
    MultiSelectActionItem *toolBarButton = [[MultiSelectActionItem alloc] initWithTitle:titleLocalizationKey
                                                                                  style:UIBarButtonItemStylePlain
                                                                               actionId:actionId
                                                                          isDestructive:isDestructive
                                                                                 target:self
                                                                                 action:@selector(performToolBarButtonAction:)];
    [self.actionItems addObject:toolBarButton];
    return toolBarButton;
}

- (void)removeToolBarButtons
{
    [self.actionItems removeAllObjects];
}

- (void)refreshToolBarButtons
{
    self.items = [self.actionItems array];
    [self updateToolBarButtonTitles];
}

- (void)userDidSelectItem:(id)item
{
    [self.selectedItems addObject:item];
    [self updateToolBarButtonTitles];
    [self notifyDelegateItemsDidChange];
}

- (void)userDidDeselectItem:(id)item
{
    [self.selectedItems removeObject:item];
    [self updateToolBarButtonTitles];
    [self notifyDelegateItemsDidChange];
}

- (void)userDidDeselectAllItems
{
    [self.selectedItems removeAllObjects];
    [self updateToolBarButtonTitles];
    [self notifyDelegateItemsDidChange];
}

- (void)replaceSelectedItemsWithItems:(NSArray *)items
{
    [self.selectedItems removeAllObjects];
    [self.selectedItems addObjectsFromArray:items];
    [self updateToolBarButtonTitles];
    [self notifyDelegateItemsDidChange];
}

- (void)updateToolBarButtonTitles
{
    NSUInteger selectedItemsCount = [self.selectedItems count];
    
    for (MultiSelectActionItem *actionItem in self.actionItems)
    {
        actionItem.enabled = (selectedItemsCount > 0) ? YES : NO;
        [actionItem setButtonTitleWithCounterValue:selectedItemsCount];
    }
}

- (void)enableAction:(NSString *)actionId enable:(BOOL)enable
{
    for (MultiSelectActionItem *actionItem in self.actionItems)
    {
        if ((self.selectedItems.count > 0) && [actionItem.actionId isEqualToString:actionId])
        {
            actionItem.enabled = enable;
        }
    }
}

- (void)performToolBarButtonAction:(id)sender
{
    MultiSelectActionItem *actionItem = (MultiSelectActionItem *)sender;
    if (actionItem != nil)
    {
        [self notifyDelegateUserDidPerformAction:actionItem];
    }
}

@end

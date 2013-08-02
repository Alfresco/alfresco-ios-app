//
//  MultiSelectActionsToolbar.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MultiSelectActionsToolbar.h"
#import "MultiSelectActionItem.h"

static CGFloat const kMultiSelectAnimationDuration = 0.2f;

@interface MultiSelectActionsToolbar ()

@property (nonatomic, strong) NSMutableOrderedSet *actionItems;
@property (nonatomic, strong) UITabBarController *fromController;

@end

@implementation MultiSelectActionsToolbar

- (id)initWithParentViewController:(UITabBarController *)tabBarController
{
    self = [super init];
    if (self)
    {
        self.alpha = 0;
        self.barStyle = UIBarStyleDefault;
        self.fromController = tabBarController;
        self.actionItems = [[NSMutableOrderedSet alloc] init];
        self.selectedItems = [[NSMutableArray alloc] init];
        
        [self adjustFrame];
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    }
    return self;
}

- (void)adjustFrame
{
    CGFloat toolbarHeight = self.fromController.tabBar.frame.size.height;
    CGRect rootViewFrame = self.fromController.view.bounds;
    CGFloat rootViewHeight = CGRectGetHeight(rootViewFrame);
    CGFloat rootViewWidth = CGRectGetWidth(rootViewFrame);
    CGRect toolBarFrame = CGRectMake(0, rootViewHeight - toolbarHeight, rootViewWidth, toolbarHeight);
    self.frame = toolBarFrame;
}

- (void)enterMultiSelectMode
{
    [self.selectedItems removeAllObjects];
    [self updateToolBarButtonTitles];
    [self adjustFrame];
    [self.fromController.view addSubview:self];
    
    [UIView animateWithDuration:kMultiSelectAnimationDuration animations:^{
        self.fromController.tabBar.frame = CGRectOffset(self.fromController.tabBar.frame, 0, +self.fromController.tabBar.frame.size.height);
        self.fromController.tabBar.alpha = 0;
        self.alpha = 1;
    }];
}

- (void)leaveMultiSelectMode
{
    [UIView animateWithDuration:kMultiSelectAnimationDuration animations:^{
        self.fromController.tabBar.frame = CGRectOffset(self.fromController.tabBar.frame, 0, -self.fromController.tabBar.frame.size.height);
        self.fromController.tabBar.alpha = 1;
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
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
                                                                                        style:UIBarButtonItemStyleBordered
                                                                                     actionId:actionId
                                                                                isDestructive:isDestructive
                                                                                       target:self
                                                                                       action:@selector(performToolBarButtonAction:)];
    [self.actionItems addObject:toolBarButton];
    self.items = [self.actionItems array];
    return toolBarButton;
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

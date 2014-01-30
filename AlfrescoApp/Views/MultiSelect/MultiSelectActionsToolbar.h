//
//  MultiSelectActionsToolbar.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * MultiSelectActionsDelegate
 */
@protocol MultiSelectActionsDelegate <NSObject>
@optional
- (void)multiSelectItemsDidChange:(NSArray *)selectedItems;
- (void)multiSelectUserDidPerformAction:(NSString *)actionId selectedItems:(NSArray *)selectedItems;
@end

@interface MultiSelectActionsToolbar : UIToolbar

@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, weak) id <MultiSelectActionsDelegate> multiSelectDelegate;

- (void)enterMultiSelectMode:(NSLayoutConstraint *)heightConstraint;
- (void)leaveMultiSelectMode:(NSLayoutConstraint *)heightConstraint;

- (void)userDidSelectItem:(id)item;
- (void)userDidDeselectItem:(id)item;

- (UIBarButtonItem *)createToolBarButtonForTitleKey:(NSString *)titleLocalizationKey actionId:(NSString *)actionId isDestructive:(BOOL)isDestructive;
- (void)enableAction:(NSString *)actionId enable:(BOOL)enable;

@end

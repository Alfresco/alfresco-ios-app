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

- (void)enterMultiSelectMode;
- (void)leaveMultiSelectMode;

- (void)replaceSelectedItemsWithItems:(NSArray *)items;

- (void)userDidSelectItem:(id)item;
- (void)userDidDeselectItem:(id)item;
- (void)userDidDeselectAllItems;

- (UIBarButtonItem *)createToolBarButtonForTitleKey:(NSString *)titleLocalizationKey actionId:(NSString *)actionId isDestructive:(BOOL)isDestructive;
- (void)enableAction:(NSString *)actionId enable:(BOOL)enable;
- (void)removeToolBarButtons;
- (void)refreshToolBarButtons;

@end

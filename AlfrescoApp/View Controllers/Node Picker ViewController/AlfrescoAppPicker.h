//
//  AlfrescoAppPicker.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MultiSelectActionsToolbar.h"

extern CGFloat const kMultiSelectToolBarHeight;

typedef NS_ENUM(NSInteger, AlfrescoAppPickerType)
{
    PickerTypeNodesMultiSelection,
    PickerTypeNodesSingleSelection,
    PickerTypePeopleSelection
};

@protocol AlfrescoAppPickerDelegate <NSObject>

@optional
- (void)pickerUserDidSelectItems:(NSArray *)selectedItems pickerType:(AlfrescoAppPickerType)pickerType;
- (void)pickerUserRemovedItem:(id)item pickerType:(AlfrescoAppPickerType)pickerType;

@end

@interface AlfrescoAppPicker : NSObject <MultiSelectActionsDelegate>

@property (nonatomic, assign) AlfrescoAppPickerType pickerType;
@property (nonatomic, weak) id<AlfrescoAppPickerDelegate> delegate;

- (instancetype)initWithSession:(id<AlfrescoSession>)session pickerType:(AlfrescoAppPickerType)pickerType items:(NSMutableArray *)items navigationController:(UINavigationController *)navigationController;
- (void)startPicker;
- (void)cancelPicker;

- (BOOL)isItemSelected:(id)item;
- (BOOL)isSelectionEnabledForItem:(id)item;
- (void)deselectItem:(id)item;
- (void)deselectAllItems;
- (void)selectItem:(id)item;
- (void)replaceSelectedItemsWithItems:(NSArray *)items;
- (NSInteger)numberOfSelectedItems;

- (void)showMultiSelectToolBar;
- (void)hideMultiSelectToolBar;

@end

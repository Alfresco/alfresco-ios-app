//
//  AlfrescoAppPicker.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "AlfrescoAppPicker.h"
#import "NodePickerSitesViewController.h"
#import "AlfrescoAppPickerItemsListViewController.h"

CGFloat const kMultiSelectToolBarHeight = 44.0f;

@interface AlfrescoAppPicker()

@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) MultiSelectActionsToolbar *multiSelectToolbar;
@property (nonatomic, strong) NSMutableArray *itemsAlreadySelected;
@property (nonatomic, strong) UIViewController *nextController;
@property (nonatomic, assign) BOOL isMultiSelectToolBarVisible;

@end

@implementation AlfrescoAppPicker

- (instancetype)initWithSession:(id<AlfrescoSession>)session pickerType:(AlfrescoAppPickerType)pickerType items:(NSMutableArray *)items navigationController:(UINavigationController *)navigationController
{
    self = [super init];
    if (self)
    {
        _session = session;
        _pickerType = pickerType;
        _itemsAlreadySelected = items;
        _navigationController = navigationController;
    }
    return self;
}

- (void)startPicker
{
    if (self.pickerType == PickerTypeNodesMultiSelection || self.pickerType == PickerTypeNodesSingleSelection)
    {
        if (self.itemsAlreadySelected && self.itemsAlreadySelected.count > 0)
        {
            self.nextController = [[AlfrescoAppPickerItemsListViewController alloc] initWithSession:self.session
                                                                                     pickerListType:PickerItemsListTypeNodesMultiSelection
                                                                                              items:self.itemsAlreadySelected
                                                                               nodePickerController:self];
        }
        else
        {
            self.nextController = [[NodePickerSitesViewController alloc] initWithSession:self.session nodePickerController:self];
        }
    }
    else if (self.pickerType == PickerTypePeopleSelection)
    {
        // initiate people picker
    }
    
    if (self.nextController)
    {
        [self.navigationController pushViewController:self.nextController animated:YES];
    }
    
    CGRect navFrame = self.navigationController.view.frame;
    self.multiSelectToolbar = [[MultiSelectActionsToolbar alloc] initWithFrame:CGRectMake(0, navFrame.size.height - kMultiSelectToolBarHeight, navFrame.size.width, kMultiSelectToolBarHeight)];
    self.multiSelectToolbar.multiSelectDelegate = self;
    
    if (self.pickerType == PickerTypeNodesMultiSelection)
    {
        [self.multiSelectToolbar createToolBarButtonForTitleKey:@"multiselect.button.deselectAll" actionId:kMultiSelectDeSelectAll isDestructive:YES];
        [self.multiSelectToolbar createToolBarButtonForTitleKey:@"multiselect.button.attach" actionId:kMultiSelectAttach isDestructive:NO];
    }
    else if (self.pickerType == PickerTypeNodesSingleSelection)
    {
        [self.multiSelectToolbar createToolBarButtonForTitleKey:@"multiselect.button.select" actionId:kSingleSelection isDestructive:NO];
    }
    else if (self.pickerType == PickerTypePeopleSelection)
    {
        
    }
    [self.multiSelectToolbar enterMultiSelectMode:nil];
}

- (void)cancelPicker
{
    [self hideMultiSelectToolBar];
    
    if (self.pickerType == PickerTypeNodesMultiSelection)
    {
        if ([self.nextController isKindOfClass:[AlfrescoAppPickerItemsListViewController class]])
        {
            [self.navigationController popToViewController:self.nextController animated:YES];
        }
        else
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
    else if (self.pickerType == PickerTypeNodesSingleSelection)
    {
        if (self.navigationController.viewControllers.firstObject == self.nextController)
        {
            [self.nextController dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

- (void)showMultiSelectToolBar
{
    if (!self.isMultiSelectToolBarVisible)
    {
        [self.navigationController.view addSubview:self.multiSelectToolbar];
        self.isMultiSelectToolBarVisible = YES;
    }
}

- (void)hideMultiSelectToolBar
{
    if (self.isMultiSelectToolBarVisible)
    {
        [self.multiSelectToolbar removeFromSuperview];
        self.isMultiSelectToolBarVisible = NO;
    }
}

- (BOOL)isSelectionEnabledForItem:(id)item
{
    BOOL isSelectionEnabled = YES;
    
    if (self.pickerType == PickerTypeNodesMultiSelection || self.pickerType == PickerTypeNodesSingleSelection)
    {
        BOOL isFolder = [[item valueForKey:@"isFolder"] boolValue];
        
        if (self.pickerType == PickerTypeNodesSingleSelection)
        {
            isSelectionEnabled = isFolder;
        }
        else
        {
            isSelectionEnabled = !isFolder;
        }
    }
    return isSelectionEnabled;
}

- (BOOL)isItemSelected:(id)item
{
    __block BOOL isSelected = NO;
    [self.multiSelectToolbar.selectedItems enumerateObjectsUsingBlock:^(id selectedItem, NSUInteger index, BOOL *stop) {
        
        NSString *itemIdentifier = [item valueForKey:@"identifier"];
        NSString *selectedItemIdentifier = [selectedItem valueForKeyPath:@"identifier"];
        if ([itemIdentifier isEqualToString:selectedItemIdentifier])
        {
            isSelected = YES;
            *stop = YES;
        }
    }];
    return isSelected;
}

- (void)selectItem:(id)item
{
    __block BOOL itemExists = NO;
    [self.multiSelectToolbar.selectedItems enumerateObjectsUsingBlock:^(id selectedItem, NSUInteger index, BOOL *stop) {
        
        NSString *itemIdentifier = [item valueForKey:@"identifier"];
        NSString *selectedItemIdentifier = [selectedItem valueForKeyPath:@"identifier"];
        if ([itemIdentifier isEqualToString:selectedItemIdentifier])
        {
            itemExists = YES;
            *stop = YES;
        }
    }];
    
    if (!itemExists)
    {
        [self.multiSelectToolbar userDidSelectItem:item];
    }
}

- (void)replaceSelectedItemsWithItems:(NSArray *)items
{
    [self.multiSelectToolbar replaceSelectedItemsWithItems:items];
}

- (void)deselectItem:(id)item
{
    __block id existingItem = nil;
    [self.multiSelectToolbar.selectedItems enumerateObjectsUsingBlock:^(id selectedItem, NSUInteger index, BOOL *stop) {
        
        NSString *itemIdentifier = [item valueForKey:@"identifier"];
        NSString *selectedItemIdentifier = [selectedItem valueForKeyPath:@"identifier"];
        if ([itemIdentifier isEqualToString:selectedItemIdentifier])
        {
            existingItem = selectedItem;
            *stop = YES;
        }
    }];
    [self.multiSelectToolbar userDidDeselectItem:existingItem];
    
    if (self.pickerType == PickerTypeNodesMultiSelection && [self.delegate respondsToSelector:@selector(pickerUserRemovedItem:pickerType:)])
    {
        [self.delegate pickerUserRemovedItem:item pickerType:self.pickerType];
    }
}

- (void)deselectAllItems
{
    [self.multiSelectToolbar userDidDeselectAllItems];
}

- (NSInteger)numberOfSelectedItems
{
    return self.multiSelectToolbar.selectedItems.count;
}

#pragma mark - MultiSelectDelegate Functions

- (void)multiSelectUserDidPerformAction:(NSString *)actionId selectedItems:(NSArray *)selectedItems
{
    if ([actionId isEqualToString:kMultiSelectAttach])
    {
        if ([self.nextController isKindOfClass:[AlfrescoAppPickerItemsListViewController class]])
        {
            [(AlfrescoAppPickerItemsListViewController *)self.nextController refreshListWithItems:selectedItems];
            [self cancelPicker];
        }
        else
        {
            [self cancelPicker];
        }
        if ([self.delegate respondsToSelector:@selector(pickerUserDidSelectItems:pickerType:)])
        {
            [self.delegate pickerUserDidSelectItems:selectedItems pickerType:self.pickerType];
        }
    }
    else if ([actionId isEqualToString:kMultiSelectDeSelectAll])
    {
        [self deselectAllItems];
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoPickerDeselectAllNotification object:nil];
    }
    else if ([actionId isEqualToString:kSingleSelection])
    {
        [self cancelPicker];
        if ([self.delegate respondsToSelector:@selector(pickerUserDidSelectItems:pickerType:)])
        {
            [self.delegate pickerUserDidSelectItems:selectedItems pickerType:self.pickerType];
        }
    }
}

- (void)multiSelectItemsDidChange:(NSArray *)selectedItems
{
    
}

@end

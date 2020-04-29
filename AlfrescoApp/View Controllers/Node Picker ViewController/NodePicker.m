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
 
#import "NodePicker.h"
#import "NodePickerScopeViewController.h"
#import "NodePickerListViewController.h"

static NSString * const kNodePickerSelectDocuments = @"nodePickerSelectDocuments";
static NSString * const kNodePickerDeSelectAll = @"nodePickerDeSelectAll";
static NSString * const kNodePickerSelectFolder = @"nodePickerSelectFolder";
NSString * const kAlfrescoPickerDeselectAllNotification = @"AlfrescoPickerDeselectAllNotification";

@interface NodePicker()

@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) MultiSelectContainerView *multiSelectContainerView;
@property (nonatomic, strong) NSMutableArray *nodesAlreadySelected;
@property (nonatomic, strong) UIViewController *nextController;
@property (nonatomic, assign) BOOL isMultiSelectToolBarVisible;
@property (nonatomic, assign, readwrite) NodePickerMode mode;
@property (nonatomic, assign, readwrite) NodePickerType type;

@end

@implementation NodePicker

- (instancetype)initWithSession:(id<AlfrescoSession>)session navigationController:(UINavigationController *)navigationController
{
    self = [super init];
    if (self)
    {
        _session = session;
        _navigationController = navigationController;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startWithNodes:(NSMutableArray *)nodes type:(NodePickerType)type mode:(NodePickerMode)mode
{
    self.type = type;
    self.mode = mode;
    
    // search to get AlfrescoNodes if passed array holds nodes identifiers
    if ([nodes.firstObject isKindOfClass:[NSString class]])
    {
        AlfrescoSearchService *searchService = [[AlfrescoSearchService alloc] initWithSession:self.session];
        NSString *searchStatement = [self cmisSearchQueryWithNodes:nodes];
        
        [searchService searchWithStatement:searchStatement language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *resultsArray, NSError *error) {
            
            self.nodesAlreadySelected = [resultsArray mutableCopy];
            if ([self.nextController isKindOfClass:[NodePickerListViewController class]])
            {
                [(NodePickerListViewController *)self.nextController refreshListWithItems:self.nodesAlreadySelected];
            }
        }];
    }
    else
    {
        self.nodesAlreadySelected = nodes;
    }
    
    if (self.type == NodePickerTypeDocuments && self.mode == NodePickerModeMultiSelect && nodes.count > 0)
    {
        self.nextController = [[NodePickerListViewController alloc] initWithSession:self.session items:self.nodesAlreadySelected nodePickerController:self];
    }
    else
    {
        self.nextController = [[NodePickerScopeViewController alloc] initWithSession:self.session nodePickerController:self];
    }
    
    if (self.nextController)
    {
        [self.navigationController pushViewController:self.nextController animated:YES];
    }
    
    CGRect navFrame = self.navigationController.view.frame;
    CGFloat containerViewHeight = kPickerMultiSelectToolBarHeight;
    if (@available(iOS 11.0, *)) {
        containerViewHeight += self.navigationController.view.safeAreaInsets.bottom;
    }
    self.multiSelectContainerView = [[MultiSelectContainerView alloc] initWithFrame:CGRectMake(0, navFrame.size.height - containerViewHeight, navFrame.size.width, containerViewHeight)];
    self.multiSelectContainerView.toolbar.multiSelectDelegate = self;
    [self.multiSelectContainerView show];
    
    [self replaceSelectedNodesWithNodes:self.nodesAlreadySelected];
}

- (void)updateMultiSelectToolBarActionsForListView
{
    [self.multiSelectContainerView.toolbar removeToolBarButtons];
    [self.multiSelectContainerView.toolbar createToolBarButtonForTitleKey:@"nodes.picker.button.deselectAll" actionId:kNodePickerDeSelectAll isDestructive:YES];
    [self.multiSelectContainerView.toolbar refreshToolBarButtons];
    [self showMultiSelectToolBar];
}

- (void)updateMultiSelectToolBarActions
{
    [self.multiSelectContainerView.toolbar removeToolBarButtons];
    if (self.type == NodePickerTypeDocuments && self.mode == NodePickerModeMultiSelect)
    {
        [self.multiSelectContainerView.toolbar createToolBarButtonForTitleKey:@"nodes.picker.button.select.documents" actionId:kNodePickerSelectDocuments isDestructive:NO];
        [self showMultiSelectToolBar];
    }
    else if (self.type == NodePickerTypeFolders && self.mode == NodePickerModeSingleSelect)
    {
        [self.multiSelectContainerView.toolbar createToolBarButtonForTitleKey:@"nodes.picker.button.select.folder" actionId:kNodePickerSelectFolder isDestructive:NO];
        [self showMultiSelectToolBar];
    }
    else
    {
        [self hideMultiSelectToolBar];
    }
    [self.multiSelectContainerView.toolbar refreshToolBarButtons];
}

- (void)cancel
{
    [self hideMultiSelectToolBar];
    
    if (self.mode == NodePickerModeMultiSelect)
    {
        if ([self.nextController isKindOfClass:[NodePickerListViewController class]])
        {
            [self.navigationController popToViewController:self.nextController animated:YES];
        }
        else
        {
            // pop to view controller just before Picker contollers
            NSInteger nextViewControllerIndex = [self.navigationController.viewControllers indexOfObject:self.nextController];
            NSInteger previousControllerIndex = nextViewControllerIndex > 0 ? (nextViewControllerIndex - 1) : NSNotFound;
            
            if (previousControllerIndex != NSNotFound)
            {
                UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:previousControllerIndex];
                [self.navigationController popToViewController:previousViewController animated:YES];
            }
        }
    }
    else if (self.mode == NodePickerModeSingleSelect)
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
        [self.navigationController.view addSubview:self.multiSelectContainerView];
        self.isMultiSelectToolBarVisible = YES;
    }
}

- (void)hideMultiSelectToolBar
{
    if (self.isMultiSelectToolBarVisible)
    {
        [self.multiSelectContainerView removeFromSuperview];
        self.isMultiSelectToolBarVisible = NO;
    }
}

- (BOOL)isSelectionEnabledForNode:(AlfrescoNode *)node
{
    BOOL isSelectionEnabled = YES;
    
    if (self.type == NodePickerTypeDocuments)
    {
        isSelectionEnabled = node.isDocument;
    }
    else if (self.type == NodePickerTypeFolders)
    {
        isSelectionEnabled = node.isFolder;
    }
    
    return isSelectionEnabled;
}

- (BOOL)isNodeSelected:(AlfrescoNode *)node
{
    __block BOOL isSelected = NO;
    [self.multiSelectContainerView.toolbar.selectedItems enumerateObjectsUsingBlock:^(AlfrescoNode *selectedNode, NSUInteger index, BOOL *stop) {
        
        if ([node.identifier isEqualToString:selectedNode.identifier])
        {
            isSelected = YES;
            *stop = YES;
        }
    }];
    return isSelected;
}

- (void)selectNode:(AlfrescoNode *)node
{
    __block BOOL nodeExists = NO;
    [self.multiSelectContainerView.toolbar.selectedItems enumerateObjectsUsingBlock:^(AlfrescoNode *selectedNode, NSUInteger index, BOOL *stop) {
        
        if ([node.identifier isEqualToString:selectedNode.identifier])
        {
            nodeExists = YES;
            *stop = YES;
        }
    }];
    
    if (!nodeExists)
    {
        [self.multiSelectContainerView.toolbar userDidSelectItem:node];
    }
}

- (void)replaceSelectedNodesWithNodes:(NSArray *)nodes
{
    [self.multiSelectContainerView.toolbar replaceSelectedItemsWithItems:nodes];
}

- (void)deselectNode:(AlfrescoNode *)node
{
    __block id existingNode = nil;
    [self.multiSelectContainerView.toolbar.selectedItems enumerateObjectsUsingBlock:^(AlfrescoNode *selectedNode, NSUInteger index, BOOL *stop) {
        
        if ([node.identifier isEqualToString:selectedNode.identifier])
        {
            existingNode = selectedNode;
            *stop = YES;
        }
    }];
    [self.multiSelectContainerView.toolbar userDidDeselectItem:existingNode];
}

- (void)deselectAllNodes
{
    [self.multiSelectContainerView.toolbar userDidDeselectAllItems];
}

- (NSInteger)numberOfSelectedNodes
{
    return self.multiSelectContainerView.toolbar.selectedItems.count;
}

- (void)pickingNodesComplete
{
    [self cancel];
    if ([self.delegate respondsToSelector:@selector(nodePicker:didSelectNodes:)])
    {
        [self.delegate nodePicker:self didSelectNodes:self.multiSelectContainerView.toolbar.selectedItems];
    }
}

#pragma mark - MultiSelectDelegate Functions

- (void)multiSelectUserDidPerformAction:(NSString *)actionId selectedItems:(NSArray *)selectedItems
{
    if ([actionId isEqualToString:kNodePickerSelectDocuments])
    {
        if ([self.nextController isKindOfClass:[NodePickerListViewController class]])
        {
            [(NodePickerListViewController *)self.nextController refreshListWithItems:selectedItems];
            [self cancel];
        }
        else
        {
            [self cancel];
        }
        if ([self.delegate respondsToSelector:@selector(nodePicker:didSelectNodes:)])
        {
            [self.delegate nodePicker:self didSelectNodes:selectedItems];
        }
    }
    else if ([actionId isEqualToString:kNodePickerDeSelectAll])
    {
        [self deselectAllNodes];
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoPickerDeselectAllNotification object:nil];
        if ([self.delegate respondsToSelector:@selector(nodePicker:didSelectNodes:)])
        {
            [self.delegate nodePicker:self didSelectNodes:selectedItems];
        }
    }
    else if ([actionId isEqualToString:kNodePickerSelectFolder])
    {
        [self cancel];
        if ([self.delegate respondsToSelector:@selector(nodePicker:didSelectNodes:)])
        {
            [self.delegate nodePicker:self didSelectNodes:selectedItems];
        }
    }
}

#pragma mark - private Methods

- (NSString *)cmisSearchQueryWithNodes:(NSArray *)nodes
{
    NSString *pattern = [NSString stringWithFormat:@"(cmis:objectId='%@')", [nodes componentsJoinedByString:@"' OR cmis:objectId='"]];
    NSString *nodeType = (self.type == NodePickerTypeDocuments) ? @"document" : @"folder";
    
    return [NSString stringWithFormat:@"SELECT * FROM cmis:%@ WHERE %@", nodeType, pattern];
}

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
}

@end

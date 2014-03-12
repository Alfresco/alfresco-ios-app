//
//  AlfrescoNodePicker.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "NodePicker.h"
#import "NodePickerScopeViewController.h"
#import "NodePickerListViewController.h"

CGFloat const kMultiSelectToolBarHeight = 44.0f;

@interface NodePicker()

@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) MultiSelectActionsToolbar *multiSelectToolbar;
@property (nonatomic, strong) NSMutableArray *nodesAlreadySelected;
@property (nonatomic, strong) UIViewController *nextController;
@property (nonatomic, assign) BOOL isMultiSelectToolBarVisible;
@property (nonatomic, assign, readwrite) NodePickerMode nodePickerMode;
@property (nonatomic, assign, readwrite) NodePickerType nodePickerType;

@end

@implementation NodePicker

- (instancetype)initWithSession:(id<AlfrescoSession>)session navigationController:(UINavigationController *)navigationController
{
    self = [super init];
    if (self)
    {
        _session = session;
        _navigationController = navigationController;
    }
    return self;
}

- (void)startNodePickerWithNodes:(NSMutableArray *)nodes
                  nodePickerType:(NodePickerType)nodePickerType
                  nodePickerMode:(NodePickerMode)nodePickerMode
{
    self.nodePickerType = nodePickerType;
    self.nodePickerMode = nodePickerMode;
    
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
    
    if (self.nodePickerType == NodePickerTypeDocuments && self.nodePickerMode == NodePickerModeMultiSelect && nodes.count > 0)
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
    self.multiSelectToolbar = [[MultiSelectActionsToolbar alloc] initWithFrame:CGRectMake(0, navFrame.size.height - kMultiSelectToolBarHeight, navFrame.size.width, kMultiSelectToolBarHeight)];
    self.multiSelectToolbar.multiSelectDelegate = self;
    [self.multiSelectToolbar enterMultiSelectMode:nil];
    
    [self replaceSelectedNodesWithNodes:self.nodesAlreadySelected];
}

- (void)updateMultiSelectToolBarActionsForListView
{
    [self.multiSelectToolbar removeToolBarButtons];
    [self.multiSelectToolbar createToolBarButtonForTitleKey:@"nodes.picker.button.deselectAll" actionId:kNodePickerDeSelectAll isDestructive:YES];
    [self.multiSelectToolbar refreshToolBarButtons];
    [self showMultiSelectToolBar];
}

- (void)updateMultiSelectToolBarActions
{
    [self.multiSelectToolbar removeToolBarButtons];
    if (self.nodePickerType == NodePickerTypeDocuments && self.nodePickerMode == NodePickerModeMultiSelect)
    {
        [self.multiSelectToolbar createToolBarButtonForTitleKey:@"nodes.picker.button.select.documents" actionId:kNodePickerSelectDocuments isDestructive:NO];
        [self showMultiSelectToolBar];
    }
    else if (self.nodePickerType == NodePickerTypeFolders && self.nodePickerMode == NodePickerModeSingleSelect)
    {
        [self.multiSelectToolbar createToolBarButtonForTitleKey:@"nodes.picker.button.select.folder" actionId:kNodePickerSelectFolder isDestructive:NO];
        [self showMultiSelectToolBar];
    }
    else
    {
        [self hideMultiSelectToolBar];
    }
    [self.multiSelectToolbar refreshToolBarButtons];
}

- (void)cancelNodePicker
{
    [self hideMultiSelectToolBar];
    
    if (self.nodePickerMode == NodePickerModeMultiSelect)
    {
        if ([self.nextController isKindOfClass:[NodePickerListViewController class]])
        {
            [self.navigationController popToViewController:self.nextController animated:YES];
        }
        else
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
    else if (self.nodePickerMode == NodePickerModeSingleSelect)
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

- (BOOL)isSelectionEnabledForNode:(AlfrescoNode *)node
{
    BOOL isSelectionEnabled = YES;
    
    if (self.nodePickerType == NodePickerTypeDocuments)
    {
        isSelectionEnabled = node.isDocument;
    }
    else if (self.nodePickerType == NodePickerTypeFolders)
    {
        isSelectionEnabled = node.isFolder;
    }
    
    return isSelectionEnabled;
}

- (BOOL)isNodeSelected:(AlfrescoNode *)node
{
    __block BOOL isSelected = NO;
    [self.multiSelectToolbar.selectedItems enumerateObjectsUsingBlock:^(AlfrescoNode *selectedNode, NSUInteger index, BOOL *stop) {
        
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
    [self.multiSelectToolbar.selectedItems enumerateObjectsUsingBlock:^(AlfrescoNode *selectedNode, NSUInteger index, BOOL *stop) {
        
        if ([node.identifier isEqualToString:selectedNode.identifier])
        {
            nodeExists = YES;
            *stop = YES;
        }
    }];
    
    if (!nodeExists)
    {
        [self.multiSelectToolbar userDidSelectItem:node];
    }
}

- (void)replaceSelectedNodesWithNodes:(NSArray *)nodes
{
    [self.multiSelectToolbar replaceSelectedItemsWithItems:nodes];
}

- (void)deselectNode:(AlfrescoNode *)node
{
    __block id existingNode = nil;
    [self.multiSelectToolbar.selectedItems enumerateObjectsUsingBlock:^(AlfrescoNode *selectedNode, NSUInteger index, BOOL *stop) {
        
        if ([node.identifier isEqualToString:selectedNode.identifier])
        {
            existingNode = selectedNode;
            *stop = YES;
        }
    }];
    [self.multiSelectToolbar userDidDeselectItem:existingNode];
    
    if (self.nodePickerMode == NodePickerModeMultiSelect && [self.delegate respondsToSelector:@selector(nodePickerUserRemovedNode:nodePickerType:nodePickerMode:)])
    {
        [self.delegate nodePickerUserRemovedNode:existingNode nodePickerType:self.nodePickerType nodePickerMode:self.nodePickerMode];
    }
}

- (void)deselectAllNodes
{
    [self.multiSelectToolbar userDidDeselectAllItems];
}

- (NSInteger)numberOfSelectedNodes
{
    return self.multiSelectToolbar.selectedItems.count;
}

- (void)pickingNodesComplete
{
    [self cancelNodePicker];
    if ([self.delegate respondsToSelector:@selector(nodePickerUserDidSelectNodes:nodePickerType:nodePickerMode:)])
    {
        [self.delegate nodePickerUserDidSelectNodes:self.multiSelectToolbar.selectedItems nodePickerType:self.nodePickerType nodePickerMode:self.nodePickerMode];
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
            [self cancelNodePicker];
        }
        else
        {
            [self cancelNodePicker];
        }
        if ([self.delegate respondsToSelector:@selector(nodePickerUserDidSelectNodes:nodePickerType:nodePickerMode:)])
        {
            [self.delegate nodePickerUserDidSelectNodes:selectedItems nodePickerType:self.nodePickerType nodePickerMode:self.nodePickerMode];
        }
    }
    else if ([actionId isEqualToString:kNodePickerDeSelectAll])
    {
        [self deselectAllNodes];
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoPickerDeselectAllNotification object:nil];
        if ([self.delegate respondsToSelector:@selector(nodePickerUserDidSelectNodes:nodePickerType:nodePickerMode:)])
        {
            [self.delegate nodePickerUserDidSelectNodes:selectedItems nodePickerType:self.nodePickerType nodePickerMode:self.nodePickerMode];
        }
    }
    else if ([actionId isEqualToString:kNodePickerSelectFolder])
    {
        [self cancelNodePicker];
        if ([self.delegate respondsToSelector:@selector(nodePickerUserDidSelectNodes:nodePickerType:nodePickerMode:)])
        {
            [self.delegate nodePickerUserDidSelectNodes:selectedItems nodePickerType:self.nodePickerType nodePickerMode:self.nodePickerMode];
        }
    }
}

#pragma mark - private Methods

- (NSString *)cmisSearchQueryWithNodes:(NSArray *)nodes
{
    NSString *pattern = [NSString stringWithFormat:@"(cmis:objectId='%@')", [nodes componentsJoinedByString:@"' OR cmis:objectId='"]];
    NSString *nodeType = (self.nodePickerType == NodePickerTypeDocuments) ? @"document" : @"folder";
    
    return [NSString stringWithFormat:@"SELECT * FROM cmis:%@ WHERE %@", nodeType, pattern];
}

@end

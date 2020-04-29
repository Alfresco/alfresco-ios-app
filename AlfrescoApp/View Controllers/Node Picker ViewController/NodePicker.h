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
  
#import "MultiSelectContainerView.h"

@class NodePicker;

extern NSString * const kAlfrescoPickerDeselectAllNotification;

typedef NS_ENUM(NSInteger, NodePickerType)
{
    NodePickerTypeFolders,
    NodePickerTypeDocuments
};

typedef NS_ENUM(NSInteger, NodePickerMode)
{
    NodePickerModeMultiSelect,
    NodePickerModeSingleSelect
};

@protocol NodePickerDelegate <NSObject>

@optional
- (void)nodePicker:(NodePicker *)nodePicker didSelectNodes:(NSArray *)selectedNodes;

@end

@interface NodePicker : NSObject <MultiSelectActionsDelegate>

@property (nonatomic, assign, readonly) NodePickerMode mode;
@property (nonatomic, assign, readonly) NodePickerType type;
@property (nonatomic, weak) id<NodePickerDelegate> delegate;

/*
 * Initiate Node Picker giving it reference to nav controller so it can push viewcontrollers e.g sites, repository, favorites
 * @param session - Current AlfrescoSession
 * @param navigationController - UINavigationController instance
 */
- (instancetype)initWithSession:(id<AlfrescoSession>)session navigationController:(UINavigationController *)navigationController;

/*
 * Start node picker
 * @param nodes - Array of objectIds (NSString) or nodes (AlfrescoNode) objects
 * @param type -  Node Picker Type
 * @param mode - Node Picker Mode
 */
- (void)startWithNodes:(NSMutableArray *)nodes type:(NodePickerType)type mode:(NodePickerMode)mode;

/*
 * Cancel node picker
 */
- (void)cancel;

/*
 * Below methods are internal to NodePicker controllers (accessed from node picker sites, favorites, repository)
 */
- (BOOL)isNodeSelected:(AlfrescoNode *)node;
- (BOOL)isSelectionEnabledForNode:(AlfrescoNode *)node;
- (void)deselectNode:(AlfrescoNode *)node;
- (void)deselectAllNodes;
- (void)selectNode:(AlfrescoNode *)node;
- (void)replaceSelectedNodesWithNodes:(NSArray *)nodes;
- (NSInteger)numberOfSelectedNodes;

- (void)pickingNodesComplete;

- (void)showMultiSelectToolBar;
- (void)hideMultiSelectToolBar;
- (void)updateMultiSelectToolBarActionsForListView;
- (void)updateMultiSelectToolBarActions;

@end

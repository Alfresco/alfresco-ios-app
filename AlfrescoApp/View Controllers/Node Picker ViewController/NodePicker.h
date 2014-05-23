//
//  AlfrescoNodePicker.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "MultiSelectActionsToolbar.h"

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

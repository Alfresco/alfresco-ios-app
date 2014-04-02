//
//  AlfrescoNodePicker.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
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
 * initiate Node Picker giving it reference to nav controller so it can push viewcontrollers e.g sites, repository, favorites
 * @param NavigationController
 */
- (instancetype)initWithSession:(id<AlfrescoSession>)session navigationController:(UINavigationController *)navigationController;

/*
 * start nodes picker
 * @param Node Picker Type
 * @param Node Picker Mode
 */
- (void)startWithNodes:(NSMutableArray *)nodes type:(NodePickerType)type mode:(NodePickerMode)mode;

/*
 * cancel nodes picker
 */
- (void)cancel;

/*
 * Bellow methods are internal to NodePicker controllers (accessed from node picker sites, favorites, repository)
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

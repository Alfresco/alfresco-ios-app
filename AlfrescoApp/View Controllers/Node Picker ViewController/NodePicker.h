//
//  AlfrescoNodePicker.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MultiSelectActionsToolbar.h"

extern CGFloat const kMultiSelectToolBarHeight;

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
- (void)nodePickerUserDidSelectNodes:(NSArray *)selectedNodes nodePickerType:(NodePickerType)nodePickerType nodePickerMode:(NodePickerMode)nodePickerMode;
- (void)nodePickerUserRemovedNode:(AlfrescoNode *)node nodePickerType:(NodePickerType)nodePickerType nodePickerMode:(NodePickerMode)nodePickerMode;

@end

@interface NodePicker : NSObject <MultiSelectActionsDelegate>

@property (nonatomic, assign, readonly) NodePickerMode nodePickerMode;
@property (nonatomic, assign, readonly) NodePickerType nodePickerType;
@property (nonatomic, weak) id<NodePickerDelegate> delegate;

- (instancetype)initWithSession:(id<AlfrescoSession>)session navigationController:(UINavigationController *)navigationController;
- (void)startNodePickerWithNodes:(NSMutableArray *)nodes nodePickerType:(NodePickerType)nodePickerType nodePickerMode:(NodePickerMode)nodePickerMode;
- (void)cancelNodePicker;

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

//
//  CommentViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "NodeUpdatableProtocol.h"

@class CommentViewController;

@protocol CommentViewControllerDelegate <NSObject>

- (void)commentViewController:(CommentViewController *)controller didUpdateCommentCount:(NSUInteger)commentDisplayedCount hasMoreComments:(BOOL)hasMoreComments;

@end

@interface CommentViewController : ParentListViewController <NodeUpdatableProtocol>

@property (nonatomic, weak, readonly) id<CommentViewControllerDelegate> delegate;

- (id)initWithAlfrescoNode:(AlfrescoNode *)node permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session delegate:(id<CommentViewControllerDelegate>)delegate;
- (void)focusCommentEntry;

@end

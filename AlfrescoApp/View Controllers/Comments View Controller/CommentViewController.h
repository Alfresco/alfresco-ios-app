//
//  CommentViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "AddCommentViewController.h"

@class AlfrescoNode;
@class AlfrescoPermissions;

@interface CommentViewController : ParentListViewController <AddCommentViewControllerDelegate>

- (id)initWithAlfrescoNode:(AlfrescoNode *)node permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session;

@end

//
//  CommentViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"

@class AlfrescoNode;
@class AlfrescoPermissions;

@interface CommentViewController : ParentListViewController

- (id)initWithAlfrescoNode:(AlfrescoNode *)node permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session;
- (void)focusCommentEntry;

@end

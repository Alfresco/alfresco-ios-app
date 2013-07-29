//
//  AddCommentViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AlfrescoComment;
@class AlfrescoNode;
@protocol AlfrescoSession;

@protocol AddCommentViewControllerDelegate <NSObject>

- (void)didSuccessfullyAddComment:(AlfrescoComment *)comment;

@end

@interface AddCommentViewController : UIViewController <UITextViewDelegate>

- (id)initWithAlfrescoNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session delegate:(id<AddCommentViewControllerDelegate>)delegate;

@end

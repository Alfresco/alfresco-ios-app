//
//  UIAlertView+ALF.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

typedef void (^UIAlertViewDismissBlock)(NSUInteger buttonIndex, BOOL isCancelButton);

@interface UIAlertView (ALF) <UIAlertViewDelegate>

- (void)showWithCompletionBlock:(UIAlertViewDismissBlock)completionBlock;

@property (nonatomic, copy) UIAlertViewDismissBlock dismissBlock;
@end

//
//  UIAlertView+ALF.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "UIAlertView+ALF.h"
#import <objc/runtime.h>

static char DISMISS_IDENTIFIER;

@implementation UIAlertView (ALF)

@dynamic dismissBlock;

- (void)setDismissBlock:(UIAlertViewDismissBlock)completionBlock
{
    objc_setAssociatedObject(self, &DISMISS_IDENTIFIER, completionBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIAlertViewDismissBlock)dismissBlock
{
    return objc_getAssociatedObject(self, &DISMISS_IDENTIFIER);
}

- (void)showWithCompletionBlock:(UIAlertViewDismissBlock)completionBlock
{
    self.delegate = [self class];
    self.dismissBlock = completionBlock;
    [self show];
}

+ (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.dismissBlock)
    {
        alertView.dismissBlock(buttonIndex, (buttonIndex == alertView.cancelButtonIndex));
        alertView.dismissBlock = nil;
    }
}

@end

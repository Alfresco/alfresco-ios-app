/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

#import "UnderlayViewController.h"

static CGFloat const kiPadLandscapeContraint = 300.0f;
static CGFloat const kiPadPortraitContraint = 172.0f;
static CGFloat const kiPhoneContraint = 0.0f;

@interface UnderlayViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerTrailingContraint;

@end

@implementation UnderlayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(IS_IPAD)
    {
        UIInterfaceOrientation toOrientation   = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
        
        if (UIInterfaceOrientationIsLandscape(toOrientation))
        {
            self.containerLeadingConstraint.constant = kiPadLandscapeContraint;
            self.containerTrailingContraint.constant = -kiPadLandscapeContraint;
        }
        else
        {
            self.containerLeadingConstraint.constant = kiPadPortraitContraint;
            self.containerTrailingContraint.constant = -kiPadPortraitContraint;
        }
    }
    else
    {
        self.containerLeadingConstraint.constant = kiPhoneContraint;
        self.containerTrailingContraint.constant = kiPhoneContraint;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if(IS_IPAD)
    {
        UIInterfaceOrientation toOrientation   = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
        
        if (UIInterfaceOrientationIsLandscape(toOrientation))
        {
            self.containerLeadingConstraint.constant = kiPadLandscapeContraint;
            self.containerTrailingContraint.constant = -kiPadLandscapeContraint;
        }
        else
        {
            self.containerLeadingConstraint.constant = kiPadPortraitContraint;
            self.containerTrailingContraint.constant = -kiPadPortraitContraint;
        }
    }
    else
    {
        self.containerLeadingConstraint.constant = kiPhoneContraint;
        self.containerTrailingContraint.constant = kiPhoneContraint;
    }
    [self.view layoutIfNeeded];
}

@end

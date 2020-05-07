/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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

static CGFloat const kiPadWidthConstraint = 424;

@interface UnderlayViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerWidthConstraint;

@end

@implementation UnderlayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupContainerConstraints];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self setupContainerConstraints];
    
    [self.view layoutIfNeeded];
}

- (void)setupContainerConstraints
{
    self.containerWidthConstraint.constant = IS_IPAD ? kiPadWidthConstraint : CGRectGetWidth([UIScreen mainScreen].bounds);
}

@end

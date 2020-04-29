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
 
#import "ContainerViewController.h"
#import "FullScreenAnimationController.h"

@interface ContainerViewController ()

@property (nonatomic, weak, readwrite) UIView *statusBarBackgroundView;
@property (nonatomic, strong, readwrite) UIViewController *rootViewController;

@end

@implementation ContainerViewController

- (instancetype)initWithController:(UIViewController *)controller
{
    self = [super init];
    if (self)
    {
        self.rootViewController = controller;
    }
    return self;
}

- (void)loadView
{
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    UIView *view = [[UIView alloc] initWithFrame:screenFrame];
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.rootViewController.view.frame = self.view.frame;
    [self addChildViewController:self.rootViewController];
    [self.view addSubview:self.rootViewController.view];
    [self.rootViewController didMoveToParentViewController:self];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

@end

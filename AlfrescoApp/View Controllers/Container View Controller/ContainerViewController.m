//
//  ContainerViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 26/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ContainerViewController.h"

@interface ContainerViewController ()

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
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[view]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(view)];
    [view addConstraints:constraints];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.rootViewController.view.frame = self.view.frame;
    [self addChildViewController:self.rootViewController];
    [self.view addSubview:self.rootViewController.view];
    [self.rootViewController didMoveToParentViewController:self];
}

@end

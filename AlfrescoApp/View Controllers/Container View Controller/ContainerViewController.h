//
//  ContainerViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 26/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@interface ContainerViewController : UIViewController

@property (nonatomic, strong, readonly) UIViewController *rootViewController;

- (instancetype)initWithController:(UIViewController *)controller;

@end

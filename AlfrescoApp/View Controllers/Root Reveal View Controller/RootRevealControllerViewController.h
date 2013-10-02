//
//  RootRevealControllerViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 30/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootRevealControllerViewController : UIViewController

@property (nonatomic, strong, readonly) UIViewController *masterViewController;
@property (nonatomic, strong, readonly) UIViewController *detailViewController;

- (instancetype)initWithMasterViewController:(UIViewController *)masterViewController detailViewController:(UIViewController *)detailViewController;

- (void)expandViewController;
- (void)collapseViewController;

@end

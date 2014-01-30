//
//  DetailSplitViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 01/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailSplitViewController;

@interface DetailSplitViewController : UIViewController

@property (nonatomic, strong, readonly) UIViewController *masterViewController;
@property (nonatomic, strong, readonly) UIViewController *detailViewController;

- (instancetype)initWithMasterViewController:(UIViewController *)masterViewController detailViewController:(UIViewController *)detailViewController;
- (void)expandOrCollapse;
- (void)expandViewController;
- (void)collapseViewController;

@end

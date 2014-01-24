//
//  DetailSplitViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 01/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailSplitViewController;

@protocol DetailSplitViewControllerDelegate <NSObject>

- (void)didPressExpandCollapseButton:(DetailSplitViewController *)detailSplitViewController button:(UIBarButtonItem *)button;

@end

@interface DetailSplitViewController : UIViewController

@property (nonatomic, strong, readonly) UIViewController *masterViewController;
@property (nonatomic, strong, readonly) UIViewController *detailViewController;
@property (nonatomic, weak) id<DetailSplitViewControllerDelegate> delegate;

- (instancetype)initWithMasterViewController:(UIViewController *)masterViewController detailViewController:(UIViewController *)detailViewController;
- (void)expandOrCollapse;
- (void)expandViewController;
- (void)collapseViewController;

@end

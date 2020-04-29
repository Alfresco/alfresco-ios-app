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

#import <Foundation/Foundation.h>

@class RootRevealViewController;

@protocol RootRevealViewControllerDelegate <NSObject>

@optional
- (void)controllerWillExpandToDisplayMasterViewController:(RootRevealViewController *)controller;
- (void)controllerDidExpandToDisplayMasterViewController:(RootRevealViewController *)controller;
- (void)controllerWillCollapseToHideMasterViewController:(RootRevealViewController *)controller;
- (void)controllerDidCollapseToHideMasterViewController:(RootRevealViewController *)controller;

@end

@interface RootRevealViewController : UIViewController

@property (nonatomic, assign, readonly) BOOL hasOverlayController;
@property (nonatomic, assign, readonly) BOOL isExpanded;
@property (nonatomic, strong) UIViewController *masterViewController;
@property (nonatomic, strong) UIViewController *detailViewController;
@property (nonatomic, weak) id<RootRevealViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) UIViewController *overlayedViewController;

- (instancetype)initWithMasterViewController:(UIViewController *)masterViewController detailViewController:(UIViewController *)detailViewController;

- (void)expandViewController;
- (void)collapseViewController;
- (void)addOverlayedViewController:(UIViewController *)overlayViewController;
- (void)removeOverlayedViewControllerWithAnimation:(BOOL)animated;

@end

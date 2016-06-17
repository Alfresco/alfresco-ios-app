/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

#import "BaseFileFolderCollectionViewController.h"
#import "PreferenceManager.h"
#import "ALFSwipeToDeleteGestureRecognizer.h"
#import "UniversalDevice.h"
#import "FailedTransferDetailViewController.h"

static CGFloat const kCellHeight = 64.0f;

@interface BaseFileFolderCollectionViewController () <UISearchControllerDelegate, SwipeToDeleteDelegate, UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *tapToDismissDeleteAction;
@property (nonatomic, strong) ALFSwipeToDeleteGestureRecognizer *swipeToDeleteGestureRecognizer;
@property (nonatomic, strong) NSIndexPath *initialCellForSwipeToDelete;
@property (nonatomic) BOOL shouldShowOrHideDelete;
@property (nonatomic) CGFloat cellActionViewWidth;
@property (nonatomic, strong) AlfrescoNode *retrySyncNode;
@property (nonatomic, strong) UIPopoverController *retrySyncPopover;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, assign) UIBarButtonItem *alertControllerSender;

- (void)deleteNode:(AlfrescoNode *)nodeToDelete completionBlock:(void (^)(BOOL success))completionBlock;
- (void)dismissPopoverOrModalWithAnimation:(BOOL)animated withCompletionBlock:(void (^)(void))completionBlock;
- (void)presentViewInPopoverOrModal:(UIViewController *)controller animated:(BOOL)animated;

@end

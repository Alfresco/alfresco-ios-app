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

#import "BaseFileFolderCollectionViewController.h"
#import "PreferenceManager.h"
#import "LocationManager.h"
#import "ALFSwipeToDeleteGestureRecognizer.h"
#import "UniversalDevice.h"
#import "FailedTransferDetailViewController.h"
#import "UploadFormViewController.h"
#import "DownloadsViewController.h"
#import "TextFileViewController.h"
#import "NavigationViewController.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

static CGFloat const kCellHeight = 84.0f;

@interface BaseFileFolderCollectionViewController () <UISearchControllerDelegate, UIPopoverPresentationControllerDelegate, RepositoryCollectionViewDataSourceDelegate, UIImagePickerControllerDelegate, DownloadsPickerDelegate, UINavigationControllerDelegate, UploadFormViewControllerDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *tapToDismissDeleteAction;
@property (nonatomic, strong) ALFSwipeToDeleteGestureRecognizer *swipeToDeleteGestureRecognizer;
@property (nonatomic, strong) NSIndexPath *initialCellForSwipeToDelete;
@property (nonatomic) BOOL shouldShowOrHideDelete;
@property (nonatomic) CGFloat cellActionViewWidth;
@property (nonatomic, strong) AlfrescoNode *retrySyncNode;
@property (nonatomic, strong) FailedTransferDetailViewController *syncFailedDetailController;
@property (nonatomic, strong) UIViewController *popover;
@property (nonatomic, assign) UIBarButtonItem *alertControllerSender;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic) BOOL hasRequestFinished;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, assign) BOOL capturingMedia;
@property (nonatomic, strong) NSString *requestErrorStringFormat;
@property (nonatomic, strong) NSError *requestError;
@property (nonatomic) BOOL shouldDisplayErrorMessageForRequest;

- (void)deleteNode:(AlfrescoNode *)nodeToDelete completionBlock:(void (^)(BOOL success))completionBlock;
- (void)dismissPopoverOrModalWithAnimation:(BOOL)animated withCompletionBlock:(void (^)(void))completionBlock;
- (void)presentViewInPopoverOrModal:(UIViewController *)controller animated:(BOOL)animated;
- (void)updateUIUsingFolderPermissionsWithAnimation:(BOOL)animated;
- (void)selectIndexPathForAlfrescoNodeInDetailView;
- (void)changeCollectionViewStyle:(CollectionViewStyle)style animated:(BOOL)animated trackAnalytics: (BOOL) trackAnalytics;
- (void)setupActionsAlertController;
- (void)displayActionSheet:(id)sender event:(UIEvent *)event;
- (void)performEditBarButtonItemAction:(UIBarButtonItem *)sender;

@end

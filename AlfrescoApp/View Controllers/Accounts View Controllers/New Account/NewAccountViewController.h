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

#import "ParentListViewController.h"

@class NewAccountViewController;

@protocol NewAccountViewControllerDelegate <NSObject>

@optional
- (void)newAccountViewControllerWillDismiss:(NewAccountViewController *)controller;
- (void)newAccountViewControllerDidDismiss:(NewAccountViewController *)controller;
- (void)newAccountViewController:(NewAccountViewController *)controller willDismissAfterAddingAccount:(UserAccount *)account;
- (void)newAccountViewController:(NewAccountViewController *)controller didDismissAfterAddingAccount:(UserAccount *)account;

@end

@interface NewAccountViewController : ParentListViewController <UITextFieldDelegate>

/**
 This delegate is being made strong to ensure that the callbacks to the delegate are invoked.
 
 If this delegate is not retained, it will be nullified once the modal view is dismissed, therefore the the didDismiss
 callback will not be fired.
 
 By making this a strong reference, the controller is retained as long as this controller is on the heap, and nullified
 once it is deallocated from memory, which then releases the delegate. Therefore this is not leaking any memory.
 */
@property (nonatomic, strong) id<NewAccountViewControllerDelegate> delegate;

- (instancetype)initWithAccount:(UserAccount *)account configuration:(NSDictionary *)configuration;

@end

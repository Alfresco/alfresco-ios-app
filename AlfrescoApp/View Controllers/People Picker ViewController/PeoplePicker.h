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
  
#import "MultiSelectContainerView.h"

@class PeoplePicker;

typedef NS_ENUM(NSInteger, PeoplePickerMode)
{
    PeoplePickerModeMultiSelect,
    PeoplePickerModeSingleSelectAutoConfirm,
    PeoplePickerModeSingleSelectManualConfirm
};

typedef void(^PeoplePickerDismissedCompletionBlock)(PeoplePicker *peoplePicker);

@protocol PeoplePickerDelegate <NSObject>

@optional
- (void)peoplePicker:(PeoplePicker *)peoplePicker didSelectPeople:(NSArray *)selectedPeople;

@end

@interface PeoplePicker : NSObject <MultiSelectActionsDelegate>

@property (nonatomic, assign) PeoplePickerMode mode;
@property (nonatomic, weak) id<PeoplePickerDelegate> delegate;
/// If set to YES it is the caller's responsibility to call "cancel" after picker completion
@property (nonatomic, assign) BOOL shouldSuppressAutoCloseWhenDone;

/*
 * Initiate People Picker giving it reference to nav controller so it can push viewcontrollers e.g people controller
 * @param AlfrescoSession
 * @param NavigationController
 */
- (instancetype)initWithSession:(id<AlfrescoSession>)session navigationController:(UINavigationController *)navigationController;

/*
 * Initiate People Picker giving it reference to nav controller so it can push viewcontrollers e.g people controller
 * @param AlfrescoSession
 * @param NavigationController
 * @param delegate - call back object comforming to PeoplePickerDelegate
 */
- (instancetype)initWithSession:(id<AlfrescoSession>)session navigationController:(UINavigationController *)navigationController delegate:(id<PeoplePickerDelegate>)delegate;

/*
 * Start people picker
 * @param Array of initally-selected AlfrescoPerson objects or nil
 * @param PeoplePickerMode
 * @param modally - whether or not to display the picker modally
 */
- (void)startWithPeople:(NSArray *)people mode:(PeoplePickerMode)mode modally:(BOOL)modally;

/*
 * Cancel people picker
 */
- (void)cancel;
// Cancel picker but invoke completion block when UI has dismissed
- (void)cancelWithCompletionBlock:(PeoplePickerDismissedCompletionBlock)completionBlock;

/*
 * Bellow methods are internal to PeoplePicker controllers (accessed from PeoplePickerViewController)
 */
- (BOOL)isPersonSelected:(AlfrescoPerson *)person;
- (void)deselectPerson:(AlfrescoPerson *)person;
- (void)deselectAllPeople;
- (void)selectPerson:(AlfrescoPerson *)person;
- (void)replaceSelectedPeopleWithPeople:(NSArray *)people;
- (NSArray *)selectedPeople;

- (void)pickingPeopleComplete;

- (void)showMultiSelectToolBar;
- (void)hideMultiSelectToolBar;

@end

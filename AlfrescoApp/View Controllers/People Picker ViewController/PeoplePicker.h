//
//  PeoplePicker.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 05/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MultiSelectActionsToolbar.h"

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
